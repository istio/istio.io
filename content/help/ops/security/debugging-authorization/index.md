---
title: Debugging Authorization
description: Demonstrates how to debug authorization.
weight: 5
keywords: [debug,security,authorization,RBAC]
---

This page demonstrates how to debug Istio authorization. If you still cannot find solutions after following
this page, feel free to send an email to `istio-security@googlegroups.com` for help.

> {{< idea_icon >}}
It would be very helpful to also include a cluster state archive in your email by following instructions in
[reporting bugs](/about/bugs).

## Ensure Authorization is Enabled Correctly

The `ClusterRbacConfig` default cluster level singleton custom resource controls the authorization functionality globally.

1. Run the following command to list existing `ClusterRbacConfig`:

    {{< text bash >}}
    $ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
    {{< /text >}}

1. Verify there is only **one** instance of `ClusterRbacConfig` with name `default`. Otherwise, Istio disables the
authorization functionality and ignores all policies.

    {{< text plain >}}
    NAMESPACE   NAME      AGE
    default     default   1d
    {{< /text >}}

1. If there is more than one `ClusterRbacConfig` instance, remove any additional `ClusterRbacConfig` instances and
ensure **only one** instance is named `default`.

## Ensure Pilot Accepts the Policies

Pilot converts and distributes your authorization policies to the proxies. The following steps help
you ensure Pilot is working as expected:

1. Run the following command to export the Pilot `ControlZ`:

    {{< text bash >}}
    $ kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
    {{< /text >}}

1. Verify you see the following output:

    {{< text plain >}}
    Forwarding from 127.0.0.1:9876 -> 9876
    {{< /text >}}

1. Start your browser and open the `ControlZ` page at `http://127.0.0.1:9876/scopez/`.

1. Change the `rbac` Output Level to `debug`.

1. Use `Ctrl+C` in the terminal you started in step 1 to stop the port-forward command.

1. Print the log of Pilot and search for `rbac` with the following command:

    > Note: You probably need to first delete and then re-apply your authorization policies so that
the debug output is generated for these policies.

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
    {{< /text >}}

1. Check the output and verify:

    * There are no errors.
    * There is a `"built filter config for ..."` message which means the filter is generated
      for the target service.

1. For example, you might see something similar to the following:

    {{< text plain >}}
    2018-07-26T22:25:41.009838Z debug rbac building filter config for {sleep.foo.svc.cluster.local map[app:sleep pod-template-hash:3326367878] map[destination.name:sleep destination.namespace:foo destination.user:default]}
    2018-07-26T22:25:41.009915Z info  rbac no service role in namespace foo
    2018-07-26T22:25:41.009957Z info  rbac no service role binding in namespace foo
    2018-07-26T22:25:41.010000Z debug rbac generated filter config: { }
    2018-07-26T22:25:41.010114Z info  rbac built filter config for sleep.foo.svc.cluster.local
    2018-07-26T22:25:41.182400Z debug rbac building filter config for {productpage.default.svc.cluster.local map[pod-template-hash:2600844901 version:v1 app:productpage] map[destination.name:productpage destination.namespace:default destination.user:bookinfo-productpage]}
    2018-07-26T22:25:41.183131Z debug rbac checking role app2-grpc-viewer
    2018-07-26T22:25:41.183214Z debug rbac role skipped for no AccessRule matched
    2018-07-26T22:25:41.183255Z debug rbac checking role productpage-viewer
    2018-07-26T22:25:41.183281Z debug rbac matched AccessRule[0]
    2018-07-26T22:25:41.183390Z debug rbac generated filter config: {policies:<key:"productpage-viewer" value:<permissions:<and_rules:<rules:<or_rules:<rules:<header:<name:":method" exact_match:"GET" > > > > > > principals:<and_ids:<ids:<any:true > > > > >  }
    2018-07-26T22:25:41.184407Z info  rbac built filter config for productpage.default.svc.cluster.local
    {{< /text >}}

    It means Pilot generated:

    * An empty config for `sleep.foo.svc.cluster.local` as there is no authorization policies matched
      and Istio denies all requests sent to this service by default.

    * An config for `productpage.default.svc.cluster.local` and Istio will allow anyone to access it
      with GET method.

## Ensure Pilot Distributes Policies to Proxies Correctly

Pilot distributes the authorization policies to proxies. The following steps help you ensure Pilot
is working as expected:

> Note: The command used in this section assumes you have deployed [Bookinfo application](/docs/examples/bookinfo/),
otherwise you should replace `"-l app=productpage"` with your actual pod.

1. Run the following command to get the proxy configuration dump for the `productpage` service:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
    {{< /text >}}

1. Check the log and verify:

    * The log includes an `envoy.filters.http.rbac` filter to enforce the authorization policy
      on each incoming request.
    * Istio updates the filter accordingly after you update your authorization policy.

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

## Ensure Proxies Enforce Policies Correctly

Proxies eventually enforce the authorization policies. The following steps help you ensure the proxy
is working as expected:

> Note: The command used in this section assumes you have deployed [Bookinfo application](/docs/examples/bookinfo/).
otherwise you should replace `"-l app=productpage"` with your actual pod.

1. Turn on the authorization debug logging in proxy with the following command:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -X POST localhost:15000/logging?rbac=debug -s
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

    * The output log shows either `enforced allowed` or `enforced denied` depending on whether the request
      was allowed or denied respectively.

    * Your authorization policy expects the data extracted from the request.

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

