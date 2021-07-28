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
test: n/a
---

## End-user authentication fails

With Istio, you can enable authentication for end users through [request authentication policies](/docs/tasks/security/authentication/authn-policy/#end-user-authentication). Follow these steps to troubleshoot the policy specification.

1. If `jwksUri` isn’t set, make sure the JWT issuer is of url format and `url + /.well-known/openid-configuration` can be opened in browser; for example, if the JWT issuer is `https://accounts.google.com`, make sure `https://accounts.google.com/.well-known/openid-configuration` is a valid url and can be opened in a browser.

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: RequestAuthentication
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

Read [authorization implicit enablement](/docs/concepts/security/#implicit-enablement) for more details of the evaluation order.

## Ensure Istiod accepts the policies

Istiod converts and distributes your authorization policies to the proxies. The following steps help
you ensure Istiod is working as expected:

1. Run the following command to enable the debug logging in istiod:

    {{< text bash >}}
    $ istioctl admin log --level authorization:debug
    {{< /text >}}

1. Get the Istiod log with the following command:

    {{< tip >}}
    You probably need to first delete and then re-apply your authorization policies so that
    the debug output is generated for these policies.
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system
    {{< /text >}}

1. Check the output and verify there are no errors. For example, you might see something similar to the following:

    {{< text plain >}}
    2021-04-23T20:53:29.507314Z info ads Push debounce stable[31] 1: 100.981865ms since last change, 100.981653ms since last push, full=true
    2021-04-23T20:53:29.507641Z info ads XDS: Pushing:2021-04-23T20:53:29Z/23 Services:15 ConnectedEndpoints:2  Version:2021-04-23T20:53:29Z/23
    2021-04-23T20:53:29.507911Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508077Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508128Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
    2021-04-23T20:53:29.508158Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509097Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509167Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509501Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509652Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on TCP filter chain successfully
        * built 1 TCP filters for DENY action
        * added 1 TCP filters to filter chain 2
        * added 1 TCP filters to filter chain 3
        * added 1 TCP filters to filter chain 4
    2021-04-23T20:53:29.510903Z info ads LDS: PUSH for node:sleep-557747455f-6dxbl.foo resources:18 size:85.0kB
    2021-04-23T20:53:29.511487Z info ads LDS: PUSH for node:httpbin-74fb669cc6-lpscm.foo resources:18 size:86.4kB
    {{< /text >}}

    This shows that Istiod generated:

    - An HTTP filter config with policy `ns[foo]-policy[deny-path-headers]-rule[0]` for workload `httpbin-74fb669cc6-lpscm.foo`.

    - A TCP filter config with policy `ns[foo]-policy[deny-path-headers]-rule[0]` for workload `httpbin-74fb669cc6-lpscm.foo`.

## Ensure Istiod distributes policies to proxies correctly

Istiod distributes the authorization policies to proxies. The following steps help you ensure istiod is working as expected:

{{< tip >}}
The command below assumes you have deployed `httpbin`, you should replace `"-l app=httpbin"` with your actual pod if
you are not using `httpbin`.
{{< /tip >}}

1. Run the following command to get the proxy configuration dump for the `httpbin` workload:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. Check the log and verify:

    - The log includes an `envoy.filters.http.rbac` filter to enforce the authorization policy on each incoming request.
    - Istio updates the filter accordingly after you update your authorization policy.

1. The following output means the proxy of `httpbin` has enabled the `envoy.filters.http.rbac` filter with rules that rejects
   anyone to access path `/headers`.

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "typed_config": {
      "@type": "type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC",
      "rules": {
       "action": "DENY",
       "policies": {
        "ns[foo]-policy[deny-path-headers]-rule[0]": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "url_path": {
                  "path": {
                   "exact": "/headers"
                  }
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
      "shadow_rules_stat_prefix": "istio_dry_run_allow_"
     }
    },
    {{< /text >}}

## Ensure proxies enforce policies correctly

Proxies eventually enforce the authorization policies. The following steps help you ensure the proxy is working as expected:

{{< tip >}}
The command below assumes you have deployed `httpbin`, you should replace `"-l app=httpbin"` with your actual pod if you
are not using `httpbin`.
{{< /tip >}}

1. Turn on the authorization debug logging in proxy with the following command:

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin --level "rbac:debug"
    {{< /text >}}

1. Verify you see the following output:

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. Send some requests to the `httpbin` workload to generate some logs.

1. Print the proxy logs with the following command:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. Check the output and verify:

    - The output log shows either `enforced allowed` or `enforced denied` depending on whether the request
      was allowed or denied respectively.

    - Your authorization policy expects the data extracted from the request.

1. The following is an example output for a request at path `/httpbin`:

    {{< text plain >}}
    ...
    2021-04-23T20:43:18.552857Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:46180, directRemoteIP: 10.44.3.13:46180, remoteIP: 10.44.3.13:46180,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/sleep, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', '672c9166-738c-4865-b541-128259cc65e5'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '8a124905edf4291a21df326729b264e9'
    'x-b3-spanid', '21df326729b264e9'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/sleep'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
      }
    }

    2021-04-23T20:43:18.552910Z debug envoy rbac enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    ...
    {{< /text >}}

    The log `enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` means the request is rejected by
    the policy `ns[foo]-policy[deny-path-headers]-rule[0]`.

1. The following is an example output for authorization policy in the [dry-run mode](/docs/tasks/security/authorization/authz-dry-run):

    {{< text plain >}}
    ...
    2021-04-23T20:59:11.838468Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:49826, directRemoteIP: 10.44.3.13:49826, remoteIP: 10.44.3.13:49826,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/sleep, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e7b2fdb0-d2ea-4782-987c-7845939e6313'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '696607fc4382b50017c1f7017054c751'
    'x-b3-spanid', '17c1f7017054c751'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/sleep'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
      }
    }

    2021-04-23T20:59:11.838529Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    2021-04-23T20:59:11.838538Z debug envoy rbac no engine, allowed by default
    ...
    {{< /text >}}

    The log `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` means the request would be rejected
    by the **dry-run** policy `ns[foo]-policy[deny-path-headers]-rule[0]`.

    The log `no engine, allowed by default` means the request is actually allowed because the dry-run policy is the
    only policy on the workload.

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

If you suspect the client side sidecar may send mutual TLS or plaintext traffic incorrectly, check the
[Grafana Workload dashboard](/docs/ops/integrations/grafana/). The outbound requests are annotated whether mTLS
 is used or not. After checking this if you believe the client sidecars are misbehaved, report an issue on GitHub.
