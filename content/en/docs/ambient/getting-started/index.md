---
title: Getting Started
description: How to deploy and install Istio in ambient mode.
weight: 1
aliases:
  - /docs/ops/ambient/getting-started
  - /latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
test: yes
---

This guide lets you quickly evaluate Istio's {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}).
You can install Istio ambient mode on [any supported Kubernetes platform](/docs/setup/platform-setup/), but this guide will assume the use of [kind](https://kind.sigs.k8s.io/) for simplicity.

{{< tip >}}
Note that ambient mode currently requires the use of [istio-cni](/docs/setup/additional-setup/cni) to configure Kubernetes nodes, which must run as a privileged pod. Ambient mode is compatible with every major CNI that previously supported sidecar mode.
{{< /tip >}}

Follow these steps to get started with Istio's ambient mode:

1. [Download and install](#download)
1. [Deploy the sample application](#bookinfo)
1. [Adding your application to ambient](#addtoambient)
1. [Secure application access](#secure)
1. [Control traffic](#control)
1. [Uninstall](#uninstall)

## Download and install {#download}

1.  Install [kind](https://kind.sigs.k8s.io/)

1.  Download the [latest version of Istio](/docs/setup/getting-started/#download) (v1.21.0 or later) with Alpha support for ambient mode.

1.  Deploy a new local `kind` cluster:

    {{< text syntax=bash snip_id=none >}}
    $ kind create cluster --config=- <<EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: ambient
    nodes:
    - role: control-plane
    - role: worker
    - role: worker
    EOF
    {{< /text >}}

1.  Install the Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1.  Install Istio with the `ambient` profile on your Kubernetes cluster, using
    the version of `istioctl` downloaded above:

    {{< text bash >}}
    $ istioctl install --set profile=ambient --skip-confirmation
    {{< /text >}}

    After running the above command, you’ll get the following output that indicates
    four components (including {{< gloss "ztunnel" >}}ztunnel{{< /gloss >}}) have been installed successfully!

    {{< text syntax=plain snip_id=none >}}
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ CNI installed
    ✔ Ztunnel installed
    ✔ Installation complete
    {{< /text >}}

1.  Verify the installed components using the following command:

    {{< text bash >}}
    $ kubectl get pods,daemonset -n istio-system
    NAME                                        READY   STATUS    RESTARTS   AGE
    pod/istio-cni-node-btbjf                    1/1     Running   0          2m18s
    pod/istiod-55b74b77bd-xggqf                 1/1     Running   0          2m27s
    pod/ztunnel-5m27h                           1/1     Running   0          2m10s

    NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    daemonset.apps/istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m18s
    daemonset.apps/ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
    {{< /text >}}

## Deploy the sample application {#bookinfo}

You’ll use the sample [bookinfo application](/docs/examples/bookinfo/), which is part of
the Istio distribution that you downloaded above. In ambient mode, you deploy applications to
your Kubernetes cluster exactly the same way you would
without Istio. This means that you can have your applications running in your cluster before
you enable ambient mode, and have them join the mesh without needing to restart or
reconfigure them.

{{< warning >}}
Make sure the default namespace does not include the label `istio-injection=enabled` when using ambient mode, because you do not need Istio to inject sidecars into application pods.
{{< /warning >}}

1. Start the sample services:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl apply -f @samples/sleep/notsleep.yaml@
    {{< /text >}}

    `sleep` and `notsleep` are two simple applications that can serve as curl clients.

1. Deploy an ingress gateway so you can access the bookinfo app from outside the cluster:

    {{< tip >}}
    To get IP address assignment for `Loadbalancer` service types in `kind`, you may need to install a tool like [MetalLB](https://metallb.universe.tf/). Please consult [this guide](https://kind.sigs.k8s.io/docs/user/loadbalancer/) for more information.
    {{</ tip >}}

    Create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway)
    and [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    {{< /text >}}

    Set the environment variables for the Kubernetes Gateway:

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw/bookinfo-gateway
    $ export GATEWAY_HOST=bookinfo-gateway-istio.default
    $ export GATEWAY_SERVICE_ACCOUNT=ns/default/sa/bookinfo-gateway-istio
    {{< /text >}}

1. Test your bookinfo application. It should work with or without the gateway:

    {{< text syntax=bash snip_id=verify_traffic_sleep_to_ingress >}}
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text syntax=bash snip_id=verify_traffic_sleep_to_productpage >}}
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text syntax=bash snip_id=verify_traffic_notsleep_to_productpage >}}
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Adding your application to the ambient mesh {#addtoambient}

1. You can enable all pods in a given namespace to be part of an ambient mesh by simply labeling the namespace:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    namespace/default labeled
    {{< /text >}}

    Congratulations! You have successfully added all pods in the default namespace
    to the mesh. Note that you did not have to restart or redeploy anything!

1. Now, send some test traffic:

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

You’ll immediately gain mTLS communication and L4 telemetry among the applications in the ambient mesh.
If you follow the instructions to install [Prometheus](/docs/ops/integrations/prometheus/#installation)
and [Kiali](/docs/ops/integrations/kiali/#installation), you’ll be able to visualize your application
in Kiali’s dashboard:

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali dashboard" >}}

## Secure application access {#secure}

After you have added your application to an ambient mode mesh, you can secure application access using Layer 4
authorization policies. This feature lets you control access to and from a service based on client workload
identities, but not at the Layer 7 level, such as HTTP methods like `GET` and `POST`.

### Layer 4 authorization policy

1. Explicitly allow the `sleep` and gateway service accounts to call the `productpage` service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      selector:
        matchLabels:
          app: productpage
      action: ALLOW
      rules:
      - from:
        - source:
            principals:
            - cluster.local/ns/default/sa/sleep
            - cluster.local/$GATEWAY_SERVICE_ACCOUNT
    EOF
    {{< /text >}}

1. Confirm the above authorization policy is working:

    {{< text bash >}}
    $ # this should succeed
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # this should succeed
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # this should fail with a connection reset error code 56
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    command terminated with exit code 56
    {{< /text >}}

### Layer 7 authorization policy

1. Using the Kubernetes Gateway API, you can deploy a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} for your namespace:

    {{< text bash >}}
    $ istioctl x waypoint apply --enroll-namespace --wait
    waypoint default/waypoint applied
    namespace default labeled with "istio.io/use-waypoint: waypoint"
    {{< /text >}}

1. View the waypoint proxy status; you should see the details of the gateway resource with `Programmed` status:

    {{< text bash >}}
    $ kubectl get gtw waypoint -o yaml
    ...
    status:
      conditions:
      - lastTransitionTime: "2024-04-18T14:25:56Z"
        message: Resource programmed, assigned to service(s) waypoint.default.svc.cluster.local:15008
        observedGeneration: 1
        reason: Programmed
        status: "True"
        type: Programmed
    {{< /text >}}

1. Update your `AuthorizationPolicy` to explicitly allow the `sleep` service to `GET` the `productpage` service, but perform no other operations:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      targetRefs:
      - kind: Service
        group: ""
        name: productpage
      action: ALLOW
      rules:
      - from:
        - source:
            principals:
            - cluster.local/ns/default/sa/sleep
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Confirm the new waypoint proxy is enforcing the updated authorization policy:

    {{< text bash >}}
    $ # this should fail with an RBAC error because it is not a GET operation
    $ kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage" -X DELETE
    RBAC: access denied
    {{< /text >}}

    {{< text bash >}}
    $ # this should fail with an RBAC error because the identity is not allowed
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/
    RBAC: access denied
    {{< /text >}}

    {{< text bash >}}
    $ # this should continue to work
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Control traffic {#control}

1. You can use the same waypoint to control traffic to `reviews`. Configure traffic routing to send 90% of requests to `reviews` v1 and 10% to `reviews` v2:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
    $ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-90-10.yaml@
    {{< /text >}}

1. Confirm that roughly 10% of the traffic from 100 requests goes to reviews-v2:

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
    {{< /text >}}

## Uninstall {#uninstall}

1. The label to instruct Istio to automatically include applications in the `default` namespace to an ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode-
    $ kubectl label namespace default istio.io/use-waypoint-
    {{< /text >}}

1. To remove waypoint proxies, installed policies, and uninstall Istio:

    {{< text bash >}}
    $ istioctl x waypoint delete --all
    $ istioctl uninstall -y --purge
    $ kubectl delete namespace istio-system
    {{< /text >}}

1. To delete the Bookinfo sample application and its configuration, see [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup).

1. To remove the `sleep` and `notsleep` applications:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete -f @samples/sleep/notsleep.yaml@
    {{< /text >}}

1. If you installed the Gateway API CRDs, remove them:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
