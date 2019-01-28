---
title: Authorization permissive mode
description: Shows how to use Authorization permissive mode.
weight: 10
keywords: [security,access-control,rbac,authorization]
---

The authorization permissive mode is an experimental feature in Istio's 1.1 release. Its interface can change in future releases.
You can skip enabling the permissive mode and directly [enable Istio authorization](/docs/tasks/security/authz-http#enabling-istio-authorization)
if you do not want to try out the permissive mode feature.

This task shows how to use authorization permissive mode in below two scenarios:

* In environment without authorization, test whether it's safe to enable authorization.

* In environment already with authorization enabled, test whether it's safe to add a new authorization policy.

## Before you begin

The activities in this task assume that you:

* Understand [authorization](/docs/concepts/security/#authorization) concepts.

* Have set up Istio on Kubernetes **with authentication enabled** by following the instructions in the
  [quick start](/docs/setup/kubernetes/quick-start/), this tutorial requires mutual TLS to work. Mutual TLS
  authentication should be enabled in the [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

### Testing whether it's safe to turn on authorization globally

This tasks show how to use authorization permissive mode to test whether it's safe to
turn on authorization globally.

Before you start, please make sure that you have finished [preparation task](#before-you-begin).

1.  Set the global authorization configuration to permissive mode.

    Run the following command:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
      enforcement_mode: PERMISSIVE
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`), you should
    see everything works fine, same as in [preparation task](#before-you-begin).

1.  Apply YAML file for the permissive mode metric collection.

    Run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    logentry.config.istio.io/rbacsamplelog created
    stdio.config.istio.io/rbacsamplehandler created
    rule.config.istio.io/rabcsamplestdio created
    {{< /text >}}

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`), you should
    see everything works fine.

1.  Verify the logs stream has been created and check `permissiveResponseCode`.

    In a Kubernetes environment, search through the `istio-telemetry`
    pods' logs as follows:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:53:42.059444Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"9.158879ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:53:41.037824Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"1.091670916s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:53:41.019851Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"1.112521495s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

    In the above telemetry logs,  the `responseCode` is 200 which is what user see now.
    The `permissiveResponseCode` is `denied` which is what user will see after switching
    global authorization configuration from `PERMISSIVE` mode to `ENFORCED` mode, which
    indicates the global authorization configuration will work as expected after rolling
    to production.

1.  Before rolling out a new authorization policy in production, apply it in permissive mode.
    `Note`, when global authorization configuration is in permissive mode, all policies will be in
    permissive mode by default.

    Run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

1.  Send traffic to the sample application again.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`), you should
    see everything works fine.

1.  Verify the logs and check `permissiveResponseCode` again.

    In a Kubernetes environment, search through the `istio-telemetry`
    pods's logs as follows:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:55:53.590430Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"4.415633ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:55:53.565914Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"32.97524ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:55:53.544441Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"57.800056ms","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"productpage-viewer","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

    In telemetry logs above,  the `responseCode` is 200 which is what user see now.
    The `permissiveResponseCode` is `allowed` for productpage service, 403 for ratings
    and reviews services, which are what user will see after switching
    policy mode from `PERMISSIVE` mode to `ENFORCED` mode; the result aligns with
    [Emabling authorization for HTTP services step 1](/docs/tasks/security/authz-http#step-1-allowing-access-to-the-productpage-service).

1.  Remove permissive mode related yaml files:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Now we have verified authorization will work as expected when turning it on,
    it's safe following the [Enabling Istio authorization](/docs/tasks/security/authz-http#enabling-istio-authorization) to turn on authorization.

### Testing new authorization policy works as expected before rolling to production

This tasks shows how to use authorization permissive mode to test a new authorization policy works
as expected in environment with authorization already enabled.

Before you start, please make sure that you have finished [Enabling authorization for HTTP services step 1](/docs/tasks/security/authz-http#step-1-allowing-access-to-the-productpage-service).

1.  Before applying a new policy, test it by setting its mode to permissive:

    Run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    {{< /text >}}

    The policy is the same as defined in [allowing access to the details and
    reviews services](/docs/tasks/security/authz-http#step-2-allowing-access-to-the-details-and-reviews-services), except `PERMISSIVE` mode is set in ServiceRoleBinding.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-details-reviews
      namespace: default
    spec:
      subjects:
      - user: "cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
      mode: PERMISSIVE
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`), you should still
    see there are errors `Error fetching product details` and `Error fetching
    product reviews` on the page. These errors are expected because the policy is
    in `PERMISSIVE` mode.

1.  Apply YAML file for the permissive mode metric collection.

    Run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Verify the logs and check `permissiveResponseCode` again.

    In a Kubernetes environment, search through the `istio-telemetry`
    pods' logs as follows:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T22:59:42.707093Z","instance":"rbacsamplelog.logentry.istio-system","destination":"details","latency":"423.381µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T22:59:42.763423Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"237.333µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {{< /text >}}

    In telemetry logs above, the `responseCode` is 403 for ratings
    and reviews services, which is what users see now.
    The `permissiveResponseCode` is `allowed` for ratings and reviews services,
    which is what users will see after switching policy mode from `PERMISSIVE` mode
    to `ENFORCED` mode; it indicates the new authorization policy will work as expected
    after rolling to production.

1.  Remove permissive mode related yaml files:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Now we have verified the new policy will work as expected, it's safe
    following [Enabling authorization for HTTP services step 2](/docs/tasks/security/authz-http#step-2-allowing-access-to-the-details-and-reviews-services) to apply the policy.
