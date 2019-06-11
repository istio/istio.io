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

* Follow the instructions in the [Kubernetes quick start](/docs/setup/kubernetes/install/kubernetes/) to
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
    instance.config.istio.io/rbacsamplelog created
    handler.config.istio.io/rbacsamplehandler created
    rule.config.istio.io/rabcsamplestdio created
    {{< /text >}}

1.  Send traffic to the sample application with the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Go to the `productpage` at `http://$GATEWAY_URL/productpage` and verify that everything works fine.

1.  Get the log for telemetry and search for the `permissiveResponseCode` with the following command:

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"accesslog.instance.istio-system\"
    {"level":"info","time":"2019-06-07T17:50:50.111933Z","instance":"accesslog.instance.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"productpage","destinationIp":"10.44.3.13","destinationName":"productpage-v1-6f7f6fd5bf-hfnw2","destinationNamespace":"default","destinationOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/productpage-v1","destinationPrincipal":"cluster.local/ns/default/sa/bookinfo-productpage","destinationServiceHost":"productpage.default.svc.cluster.local","destinationWorkload":"productpage-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"35.239.224.75","latency":"32.395873ms","method":"GET","permissiveResponseCode":"denied","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":1300,"referer":"","reporter":"destination","requestId":"56eaa9a6-d0af-93f7-a162-817b23fe3f58","requestSize":0,"requestedServerName":"outbound_.9080_._.productpage.default.svc.cluster.local","responseCode":200,"responseFlags":"-","responseSize":4183,"responseTimestamp":"2019-06-07T17:50:50.144023Z","sentBytes":4328,"sourceApp":"istio-ingressgateway","sourceIp":"10.44.3.5","sourceName":"istio-ingressgateway-766f5fd7c9-775qh","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway","sourcePrincipal":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account","sourceWorkload":"istio-ingressgateway","url":"/productpage","userAgent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36","xForwardedFor":"10.44.3.1"}
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
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"accesslog.instance.istio-system\"
    {"level":"info","time":"2019-06-07T18:11:49.208958Z","instance":"accesslog.instance.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"productpage","destinationIp":"10.44.3.13","destinationName":"productpage-v1-6f7f6fd5bf-hfnw2","destinationNamespace":"default","destinationOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/productpage-v1","destinationPrincipal":"cluster.local/ns/default/sa/bookinfo-productpage","destinationServiceHost":"productpage.default.svc.cluster.local","destinationWorkload":"productpage-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"35.239.224.75","latency":"67.406515ms","method":"GET","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"productpage-viewer","protocol":"http","receivedBytes":1300,"referer":"","reporter":"destination","requestId":"ee84d9d9-a0e0-9fef-a82e-417e367cdfeb","requestSize":0,"requestedServerName":"outbound_.9080_._.productpage.default.svc.cluster.local","responseCode":200,"responseFlags":"-","responseSize":5179,"responseTimestamp":"2019-06-07T18:11:49.275747Z","sentBytes":5324,"sourceApp":"istio-ingressgateway","sourceIp":"10.44.3.5","sourceName":"istio-ingressgateway-766f5fd7c9-775qh","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway","sourcePrincipal":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account","sourceWorkload":"istio-ingressgateway","url":"/productpage","userAgent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36","xForwardedFor":"10.44.3.1"}
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
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"accesslog.instance.istio-system\"
    {"level":"info","time":"2019-06-07T18:51:46.860970Z","instance":"accesslog.instance.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"reviews","destinationIp":"10.44.3.11","destinationName":"reviews-v1-7dccc4d655-q9zc8","destinationNamespace":"default","destinationOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/reviews-v1","destinationPrincipal":"cluster.local/ns/default/sa/default","destinationServiceHost":"reviews.default.svc.cluster.local","destinationWorkload":"reviews-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"reviews:9080","latency":"416.29µs","method":"GET","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","protocol":"http","receivedBytes":0,"referer":"","reporter":"destination","requestId":"11ff06c7-ce8d-970d-b1dc-32abf12dea21","requestSize":0,"requestedServerName":"outbound_.9080_._.reviews.default.svc.cluster.local","responseCode":403,"responseFlags":"-","responseSize":19,"responseTimestamp":"2019-06-07T18:51:46.861152Z","sentBytes":117,"sourceApp":"productpage","sourceIp":"10.44.3.13","sourceName":"productpage-v1-6f7f6fd5bf-hfnw2","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/productpage-v1","sourcePrincipal":"cluster.local/ns/default/sa/bookinfo-productpage","sourceWorkload":"productpage-v1","url":"/reviews/0","userAgent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36","xForwardedFor":"10.44.3.13"}
    {"level":"info","time":"2019-06-07T18:51:47.814739Z","instance":"accesslog.instance.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"reviews","destinationIp":"10.44.1.6","destinationName":"reviews-v2-6754c89b76-ptd6h","destinationNamespace":"default","destinationOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/reviews-v2","destinationPrincipal":"cluster.local/ns/default/sa/bookinfo-reviews","destinationServiceHost":"reviews.default.svc.cluster.local","destinationWorkload":"reviews-v2","grpcMessage":"","grpcStatus":"","httpAuthority":"reviews:9080","latency":"320.379µs","method":"GET","permissiveResponseCode":"allowed","permissiveResponsePolicyID":"details-reviews-viewer","protocol":"http","receivedBytes":0,"referer":"","reporter":"destination","requestId":"c15f0bca-33ae-9cf1-8aaa-fdcea1c528fc","requestSize":0,"requestedServerName":"outbound_.9080_._.reviews.default.svc.cluster.local","responseCode":403,"responseFlags":"-","responseSize":19,"responseTimestamp":"2019-06-07T18:51:47.814765Z","sentBytes":117,"sourceApp":"productpage","sourceIp":"10.44.3.13","sourceName":"productpage-v1-6f7f6fd5bf-hfnw2","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/productpage-v1","sourcePrincipal":"cluster.local/ns/default/sa/bookinfo-productpage","sourceWorkload":"productpage-v1","url":"/reviews/0","userAgent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36","xForwardedFor":"10.44.3.13"}
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
