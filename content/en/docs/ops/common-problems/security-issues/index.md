---
title: Security Problems
description: Techniques to address common Istio authentication, authorization, and general security-related problems.
force_inline_toc: true
weight: 20
keywords: [security,citadel]
aliases:
    - /help/ops/security/repairing-citadel
    - /help/ops/troubleshooting/repairing-citadel
    - /docs/ops/troubleshooting/repairing-citadel
owner: istio/wg-security-maintainers
test: no
---

## End-user authentication fails

With Istio, you can enable authentication for end users through [request authentication policies](/docs/tasks/security/authentication/authn-policy/#end-user-authentication). Follow these steps to troubleshoot the policy specification.

1. If `jwksUri` isn’t set, make sure the JWT issuer is of url format and `url + /.well-known/openid-configuration` can be opened in browser; for example, if the JWT issuer is `https://accounts.google.com`, make sure `https://accounts.google.com/.well-known/openid-configuration` is a valid url and can be opened in a browser.

    {{< text yaml >}}
    apiVersion: "security.istio.io/v1beta1"
    kind: "RequestAuthentication"
    metadata:
      name: "example-3"
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    {{< /text >}}

1. If the JWT token is placed in the Authorization header in http requests, make sure the JWT token is valid (not expired, etc). The fields in a JWT token can be decoded by using online JWT parsing tools, e.g., [jwt.io](https://jwt.io/).

1. Verify the Envoy proxy configuration of the target workload using `istioctl proxy-config` command.

    With the example policy above applied, use the following command to check the `listener` configuration on the inbound port `80`. You should see `envoy.filters.http.jwt_authn` filter with settings matching the issuer and JWKS as specified in the policy.

    {{< text bash >}}
    $ POD=$(kubectl get pod -l app=httpbin -n foo -o jsonpath={.items..metadata.name})
    $ istioctl proxy-config listener ${POD} -n foo --port 80 --type HTTP -o json
    <redacted>
                                {
                                    "name": "envoy.filters.http.jwt_authn",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.config.filter.http.jwt_authn.v2alpha.JwtAuthentication",
                                        "providers": {
                                            "origins-0": {
                                                "issuer": "testing@secure.istio.io",
                                                "localJwks": {
                                                    "inlineString": "*redacted*"
                                                },
                                                "payloadInMetadata": "testing@secure.istio.io"
                                            }
                                        },
                                        "rules": [
                                            {
                                                "match": {
                                                    "prefix": "/"
                                                },
                                                "requires": {
                                                    "requiresAny": {
                                                        "requirements": [
                                                            {
                                                                "providerName": "origins-0"
                                                            },
                                                            {
                                                                "allowMissing": {}
                                                            }
                                                        ]
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                },
    <redacted>
    {{< /text >}}

## Authorization is too restrictive or permissive

### Make sure there are no typos in the policy YAML file

One common mistake is specifying multiple items unintentionally in the YAML. Take the following policy as an example:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: example
  namespace: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths:
        - /foo
  - from:
    - source:
        namespaces:
        - foo
{{< /text >}}

You may expect the policy to allow requests if the path is `/foo` **and** the source namespace is `foo`.
However, the policy actually allows requests if the path is `/foo` **or** the source namespace is `foo`, which is
more permissive.

In the YAML syntax, the `-` in front of the `from:` means it's a new element in the list. This creates 2 rules in the
policy instead of 1. In authorization policy, multiple rules have the semantics of `OR`.

To fix the problem, just remove the extra `-` to make the policy have only 1 rule that allows requests if the
path is `/foo` **and** the source namespace is `foo`, which is more restrictive.

### Make sure you are NOT using HTTP-only fields on TCP ports

The authorization policy will be more restrictive because HTTP-only fields (e.g. `host`, `path`, `headers`, JWT, etc.)
do not exist in the raw TCP connections.

In the case of `ALLOW` policy, these fields are never matched. In the case of `DENY` and `CUSTOM` action, these fields
are considered always matched. The final effect is a more restrictive policy that could cause unexpected denies.

Check the Kubernetes service definition to verify that the port is [named with the correct protocol properly](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).
If you are using HTTP-only fields on the port, make sure the port name has the `http-` prefix.

### Make sure the policy is applied to the correct target

Check the workload selector and namespace to confirm it's applied to the correct targets. You can determine the
authorization policy in effect by running `istioctl x authz check POD-NAME.POD-NAMESPACE`.

### Pay attention to the action specified in the policy

- If not specified, the policy defaults to use action `ALLOW`.

- When a workload has multiple actions (`CUSTOM`, `ALLOW` and `DENY`) applied at the same time, all actions must be
  satisfied to allow a request. In other words, a request is denied if any of the action denies and is allowed only if
  all actions allow.

- The `AUDIT` action does not enforce access control and will not deny the request at any cases.

## Ensure Istiod accepts the policies

Istiod converts and distributes your authorization policies to the proxies. The following steps help
you ensure Istiod is working as expected:

1. Run the following command to open the Istiod `ControlZ` UI Page:

    {{< text bash >}}
    $ istioctl dashboard controlz $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}').istio-system
    {{< /text >}}

1. After your browser opens, click `Logging Scopes` in the left menu.

1. Change the `authorization` Output Level to `debug`.

1. Use `Ctrl+C` in the terminal you started in step 1 to stop the port-forward command.

1. Print the log of Istiod and search for `authorization` with the following command:

    {{< tip >}}
    You probably need to first delete and then re-apply your authorization policies so that
    the debug output is generated for these policies.
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep authorization
    {{< /text >}}

1. Check the output and verify:

    - There are no errors.
    - There is a `building v1beta1 policy` message which indicates the filter was generated
      for the target workload.

1. For example, you might see something similar to the following:

    {{< text plain >}}
    2020-03-05T23:43:21.621339Z   debug   authorization   found authorization allow policies for workload [app=ext-authz-server,pod-template-hash=5fd587cc9d,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=ext-authz-server,service.istio.io/canonical-revision=latest] in foo
    2020-03-05T23:43:21.621348Z   debug   authorization   building filter for HTTP listener protocol
    2020-03-05T23:43:21.621351Z   debug   authorization   building v1beta1 policy
    2020-03-05T23:43:21.621399Z   debug   authorization   constructed internal model: &{Permissions:[{Services:[] Hosts:[] NotHosts:[] Paths:[] NotPaths:[] Methods:[] NotMethods:[] Ports:[] NotPorts:[] Constraints:[] AllowAll:true v1beta1:true}] Principals:[{Users:[] Names:[cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account] NotNames:[] Group: Groups:[] NotGroups:[] Namespaces:[] NotNamespaces:[] IPs:[] NotIPs:[] RequestPrincipals:[] NotRequestPrincipals:[] Properties:[] AllowAll:false v1beta1:true}]}
    2020-03-05T23:43:21.621528Z   info    ads    LDS: PUSH for node:sleep-6bdb595bcb-vmchz.foo listeners:38
    2020-03-05T23:43:21.621997Z   debug   authorization   generated policy ns[foo]-policy[ext-authz-server]-rule[0]: permissions:<and_rules:<rules:<any:true > > > principals:<and_ids:<ids:<or_ids:<ids:<metadata:<filter:"istio_authn" path:<key:"source.principal" > value:<string_match:<exact:"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account" > > > > > > > >
    2020-03-05T23:43:21.622052Z   debug   authorization   added HTTP filter to filter chain 0
    2020-03-05T23:43:21.623532Z   debug   authorization   found authorization allow policies for workload [app=ext-authz-server,pod-template-hash=5fd587cc9d,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=ext-authz-server,service.istio.io/canonical-revision=latest] in foo
    2020-03-05T23:43:21.623543Z   debug   authorization   building filter for TCP listener protocol
    2020-03-05T23:43:21.623546Z   debug   authorization   building v1beta1 policy
    2020-03-05T23:43:21.623572Z   debug   authorization   constructed internal model: &{Permissions:[{Services:[] Hosts:[] NotHosts:[] Paths:[] NotPaths:[] Methods:[] NotMethods:[] Ports:[] NotPorts:[] Constraints:[] AllowAll:true v1beta1:true}] Principals:[{Users:[] Names:[cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account] NotNames:[] Group: Groups:[] NotGroups:[] Namespaces:[] NotNamespaces:[] IPs:[] NotIPs:[] RequestPrincipals:[] NotRequestPrincipals:[] Properties:[] AllowAll:false v1beta1:true}]}
    2020-03-05T23:43:21.623625Z   debug   authorization   generated policy ns[foo]-policy[ext-authz-server]-rule[0]: permissions:<and_rules:<rules:<any:true > > > principals:<and_ids:<ids:<or_ids:<ids:<authenticated:<principal_name:<exact:"spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account" > > > > > > >
    2020-03-05T23:43:21.623645Z   debug   authorization   added TCP filter to filter chain 0
    2020-03-05T23:43:21.623648Z   debug   authorization   added TCP filter to filter chain 1
    {{< /text >}}

    This shows that Istiod generated:

    - An HTTP filter config with policy `ns[foo]-policy[ext-authz-server]-rule[0]` for workload with labels `app=ext-authz-server,...`.

    - A TCP filter config with policy `ns[foo]-policy[ext-authz-server]-rule[0]` for workload with labels `app=ext-authz-server,...`.

## Ensure Istiod distributes policies to proxies correctly

Pilot distributes the authorization policies to proxies. The following steps help you ensure Pilot
is working as expected:

{{< tip >}}
The command used in this section assumes you have deployed [Bookinfo application](/docs/examples/bookinfo/),
otherwise you should replace `"-l app=productpage"` with your actual pod.
{{< /tip >}}

1. Run the following command to get the proxy configuration dump for the `productpage` service:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. Check the log and verify:

    - The log includes an `envoy.filters.http.rbac` filter to enforce the authorization policy
      on each incoming request.
    - Istio updates the filter accordingly after you update your authorization policy.

1. The following output means the proxy of `productpage` has enabled the `envoy.filters.http.rbac` filter
with rules that allows anyone to access it via `GET` method. The `shadow_rules` are not used and you can ignored them safely.

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "config": {
      "rules": {
       "policies": {
        "productpage-viewer": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "header": {
                  "exact_match": "GET",
                  "name": ":method"
                 }
                }
               ]
              }
             }
            ]
           }
          }
         ],
         "principals": [
          {
           "and_ids": {
            "ids": [
             {
              "any": true
             }
            ]
           }
          }
         ]
        }
       }
      },
      "shadow_rules": {
       "policies": {}
      }
     }
    },
    {{< /text >}}

## Ensure proxies enforce policies correctly

Proxies eventually enforce the authorization policies. The following steps help you ensure the proxy
is working as expected:

{{< tip >}}
The command used in this section assumes you have deployed [Bookinfo application](/docs/examples/bookinfo/).
otherwise you should replace `"-l app=productpage"` with your actual pod.
{{< /tip >}}

1. Turn on the authorization debug logging in proxy with the following command:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request POST 'logging?rbac=debug'
    {{< /text >}}

1. Verify you see the following output:

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. Visit the `productpage` in your browser to generate some logs.

1. Print the proxy logs with the following command:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. Check the output and verify:

    - The output log shows either `enforced allowed` or `enforced denied` depending on whether the request
      was allowed or denied respectively.

    - Your authorization policy expects the data extracted from the request.

1. The following output means there is a `GET` request at path `/productpage` and the policy allows the request.
The `shadow denied` has no effect and you can ignore it safely.

    {{< text plain >}}
    ...
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:79] checking request: remoteAddress: 10.60.0.139:51158, localAddress: 10.60.0.93:9080, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account, subjectPeerCertificate: O=, headers: ':authority', '35.238.0.62'
    ':path', '/productpage'
    ':method', 'GET'
    'upgrade-insecure-requests', '1'
    'user-agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36'
    'dnt', '1'
    'accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    'accept-encoding', 'gzip, deflate'
    'accept-language', 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7'
    'x-forwarded-for', '10.60.0.1'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e23ea62d-b25d-91be-857c-80a058d746d4'
    'x-b3-traceid', '5983108bf6d05603'
    'x-b3-spanid', '5983108bf6d05603'
    'x-b3-sampled', '1'
    'x-istio-attributes', 'CikKGGRlc3RpbmF0aW9uLnNlcnZpY2UubmFtZRINEgtwcm9kdWN0cGFnZQoqCh1kZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWVzcGFjZRIJEgdkZWZhdWx0Ck8KCnNvdXJjZS51aWQSQRI/a3ViZXJuZXRlczovL2lzdGlvLWluZ3Jlc3NnYXRld2F5LTc2NjY0Y2NmY2Ytd3hjcjQuaXN0aW8tc3lzdGVtCj4KE2Rlc3RpbmF0aW9uLnNlcnZpY2USJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApDChhkZXN0aW5hdGlvbi5zZXJ2aWNlLmhvc3QSJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApBChdkZXN0aW5hdGlvbi5zZXJ2aWNlLnVpZBImEiRpc3RpbzovL2RlZmF1bHQvc2VydmljZXMvcHJvZHVjdHBhZ2U='
    'content-length', '0'
    'x-envoy-internal', 'true'
    'sec-istio-authn-payload', 'CkVjbHVzdGVyLmxvY2FsL25zL2lzdGlvLXN5c3RlbS9zYS9pc3Rpby1pbmdyZXNzZ2F0ZXdheS1zZXJ2aWNlLWFjY291bnQSRWNsdXN0ZXIubG9jYWwvbnMvaXN0aW8tc3lzdGVtL3NhL2lzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudA=='
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
      }
    }

    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:88] shadow denied
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:98] enforced allowed
    ...
    {{< /text >}}

## Keys and certificates errors

If you suspect that some of the keys and/or certificates used by Istio aren't correct, you can inspect the contents from any pod:

{{< text bash >}}
$ istioctl proxy-config secret sleep-8f795f47d-4s4t7
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           138092480869518152837211547060273851586     2020-11-11T16:39:48Z     2020-11-10T16:39:48Z
ROOTCA            CA             ACTIVE     true           288553090258624301170355571152070165215     2030-11-08T16:34:52Z     2020-11-10T16:34:52Z
{{< /text >}}

By passing the `-o json` flag, you can pass the full certificate content to `openssl` to analyze its contents:

{{< text bash >}}
$ istioctl proxy-config secret sleep-8f795f47d-4s4t7 -o json | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            99:59:6b:a2:5a:f4:20:f4:03:d7:f0:bc:59:f5:d8:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jun  4 20:38:20 2018 GMT
            Not After : Sep  2 20:38:20 2018 GMT
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
...
{{< /text >}}

Make sure the displayed certificate contains valid information. In particular, the `Subject Alternative Name` field should be `URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`.

## Mutual TLS errors

If you suspect problems with mutual TLS, first ensure that [Citadel is healthy](#repairing-citadel), and
second ensure that [keys and certificates are being delivered](#keys-and-certificates-errors) to sidecars properly.

If everything appears to be working so far, the next step is to verify that the right [authentication policy](/docs/tasks/security/authentication/authn-policy/)
is applied and the right destination rules are in place.
