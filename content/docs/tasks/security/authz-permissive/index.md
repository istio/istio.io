---
title: Authorization permissive mode
description: Shows how to use Authorization permissive mode.
weight: 10
keywords: [security,access-control,rbac,authorization]
---

The [authorization permissive mode](/docs/concepts/security/#authorization-permissive-mode) allows
you to verify authorization policies before applying them in a production environment.

The authorization permissive mode is an experimental feature in version 1.1. Its interface can change
in future releases. If you do not want to try out the permissive mode feature, you can directly
[enable Istio authorization](/docs/tasks/security/authz-http#enabling-istio-authorization) to skip
enabling the permissive mode.

This task covers two scenarios regarding the use of the permissive mode for authorization:

* For environments where **authorization is disabled**, this task helps you test whether it's safe to
enable the authorization.

* For environments where **authorization is enabled**, this task helps you test whether it's safe to
add a new authorization policy.

## Before you begin

To complete this task, you should first take the following actions:

* Read the [authorization concept](/docs/concepts/security/#authorization).

* Follow the instructions in the [Kubernetes quick start](/docs/setup/kubernetes/quick-start/) to
install Istio **with mutual TLS enabled**.

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Create service accounts for the Bookinfo application. Run the following command to create service
account `bookinfo-productpage` for `productpage` and service account `bookinfo-reviews` for `reviews`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    {{< /text >}}

### Test enabling authorization globally

The following steps show you how to use authorization permissive mode to test whether it's safe to
turn on authorization globally:

1.  To enable the permissive mode in the global authorization configuration, run the following command:

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

1.  Go to the `productpage` at `http://$GATEWAY_URL/productpage` and verify that everything works fine.

1.  Apply the `rbac-permissive-telemetry.yaml` YAML file to enable the metric collection for the permissive mode:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    logentry.config.istio.io/rbacsamplelog created
    stdio.config.istio.io/rbacsamplehandler created
    rule.config.istio.io/rabcsamplestdio created
    {{< /text >}}

1.  Send traffic to the sample application with the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Go to the `productpage` at `http://$GATEWAY_URL/productpage` and verify that everything works fine.

1.  Get the log for telemetry and search for the `permissiveResponseCode` with the following command:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:53:42.059444Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"9.158879ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:53:41.037824Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"1.091670916s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:53:41.019851Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"1.112521495s","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

1.  Verify that the the log shows a `responseCode` of `200` and a `permissiveResponseCode` of `denied`.

1.  Apply the `productpage-policy.yaml` authorization policy in permissive mode with the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

1.  Send traffic to the sample application with the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Get the log for telemetry and search for the `permissiveResponseCode` with the following command:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:55:53.590430Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"4.415633ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:55:53.565914Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"32.97524ms","permissiveResponseCode":"denied","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:55:53.544441Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"57.800056ms","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"productpage-viewer","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

1.  Verify that the the log shows a `responseCode` of `200` and a `permissiveResponseCode` of `allowed`
    for `productpage` service.

1.  Remove the YAML files related to enabling the permissive mode:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Congratulations! You tested an authorization policy with permissive mode and verified it works
    as expected. To enable the authorization policy, follow the steps described in the
    [Enabling Istio authorization task](/docs/tasks/security/authz-http#enabling-istio-authorization).

### Test adding authorization policy

The following steps show how to test a new authorization policy with permissive mode when authorization
has already been enabled.

1.  Allow access to the `producepage` service by following the instructions in
[Enabling authorization for HTTP services step 1](/docs/tasks/security/authz-http#step-1-allowing-access-to-the-productpage-service).

1.  Allow access to the details and reviews service in permissive mode with the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    {{< /text >}}

1.  Verify there are errors `Error fetching product details` and `Error fetching product reviews` on
    the Bookinfo `productpage` by pointing your browser at the `productpage` (`http://$GATEWAY_URL/productpage`),
    These errors are expected because the policy is in `PERMISSIVE` mode.

1.  Apply the `rbac-permissive-telemetry.yaml` YAML file to enable the permissive mode metric collection.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Send traffic to the sample application:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Get the log for telemetry and search for the `permissiveResponseCode` with the following command:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T22:59:42.707093Z","instance":"rbacsamplelog.logentry.istio-system","destination":"details","latency":"423.381µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T22:59:42.763423Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"237.333µs","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {{< /text >}}

1.  Verify that the the log shows a `responseCode` of `403` and a `permissiveResponseCode` of `allowed`
    for ratings and reviews services.

1.  Remove the YAML files related to enabling the permissive mode:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  Congratulations! You tested adding an authorization policy with permissive mode and verified it will
    work as expected. To add the authorization policy, follow the steps described in the
    [Enabling Istio authorization task](/docs/tasks/security/authz-http#enabling-istio-authorization).
