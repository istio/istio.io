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
[reporting bugs](/help/bugs).

## Make sure authorization is enabled correctly

Authorization functionality is globally controlled by a default cluster level singleton custom resource
`RbacConfig`, Run the following command to check it is created correctly:

{{< text bash >}}
$ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
NAMESPACE   NAME      AGE
default     default   1d
{{< /text >}}

> {{< warning_icon >}}
You should see **at most 1** instance of `RbacConfig` with name **default**, otherwise the authorization
functionality will be disabled and all policies are ignored.

Remove any additional `RbacConfig` instances and make sure the only 1 instance is named **default**.
You could edit the existing one if you want to make any changes.

## Make sure policies are accepted by Pilot

Pilot is responsible for converting and distributing your authorization policies to proxies. Follow
the below steps to make sure this is finished as expected:

1. Turn on debug logging for authorization in Pilot

    First export the Pilot `ControlZ` page with the following command:

    {{< text bash >}}
    $ kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
    Forwarding from 127.0.0.1:9876 -> 9876
    {{< /text >}}

    Then start your browser and open the `ControlZ` page at `http://127.0.0.1:9876/scopez/`. Change the
    `rbac` Output Level to `debug`. After this, use `Ctrl+C` to stop the port-forward command.

1. Check the related authorization debug logging in Pilot

    > Note: You probably need to first delete and then re-apply your authorization policies so that
the debug output is generated for these policies.

    Check Pilot log with the following command:

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
    ... ...
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
    ... ...
    {{< /text >}}

    To make sure Pilot is handling the authorization policies correctly:

    * Carefully check if there are any errors in the log.
    * Check if there is a `built filter config for` message which means a filter config is generated
      for the target service.

    Taking the above output as an example:

    * Pilot generated an empty config for `sleep.foo.svc.cluster.local` as there is no authorization
      policies matched. This also means all requests sent to this service will be denied as Istio
      authorization is deny by default.
    * Pilot generated an config for `productpage.default.svc.cluster.local` that allows anyone to
      access it with GET method.

## Make sure policies are distributed to proxy

The authorization policies are eventually distributed to and enforced in proxies. Run the following
command to get the proxy config dump for the `productpage` service.

> Note: The command used in this section assumes you have deployed [bookinfo application](/docs/examples/bookinfo/).
You should replace `"-l app=productpage"` with your actual pod to get its config dump.

{{< text bash >}}
$ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
...
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
...
{{< /text >}}

The output could be very long but you only need to care about the `envoy.filters.http.rbac` filter.
This is the proxy filter that enforces the authorization policy on each incoming request.

* Check the config dump to see if it includes the `envoy.filters.http.rbac` filter.
* Check the filter config to see if it's updated accordingly after you updated your authorization policy.

Taking the above output as an example, the productpage's proxy enabled the `envoy.filters.http.rbac`
filter with rules that allows anyone to access it via GET method. The `shadow_rules` is not used and
could be ignored safely.

## Make sure policies are enforced correctly

Authorization is enforced on proxies, You can check the runtime log to see what's happening during
the enforcement.

> Note: The command used in this section assumes you have deployed [bookinfo application](/docs/examples/bookinfo/).
You could replace `"-l app=productpage"` with your actual pod name to get its config dump.

1. Turn on the authorization debug logging in proxy with the following command:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/logging?rbac=debug -s
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. Issue a request to `productpage` and check proxy log with the following command:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
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

    Search for `rbac` in the log, the filter will print the data extracted from the request which are
    used in the policy enforcement.

    * The `enforced allowed` or `enforced denied` means the request is allowed or denied by the
      filter, check the data extracted from the request to see if it's expected by your authorization policy.

    * The `uriSanPeerCertificate` field is compared to the `user` field in [Subject](
    /docs/reference/config/authorization/istio.rbac.v1alpha1/#Subject). Note it has a `spiffee://` prefix.

    * The `source.principal` in the filter_metadata is compared to the [source.principal property](
    /docs/reference/config/authorization/constraints-and-properties/#properties). Note it doesn't have
    the `spiffee://` prefix.

    Taking the above output as an example, it means there is a `GET` request at path `/productpage` and
    is allowed by the policy. The "shadow denied" is the result for shadow policies which could be ignored
    safely for now.
