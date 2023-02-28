---
title: Getting Started with Ambient Mesh
description: How to deploy and install ambient mesh.
weight: 1
owner: istio/wg-networking-maintainers
test: n/a
---

{{< warning >}}
Ambient is currently in [alpha status](/docs/releases/feature-stages/#feature-phase-definitions).

Please **do not run ambient in production** and be sure to thoroughly review the [feature phase definitions](/docs/releases/feature-stages/#feature-phase-definitions) before use.
In particular, there are already known performance, stability, and security issues in the alpha release.
There are also planned breaking changes, including those that will prevent upgrades.
These are all limitations that will be addressed before graduation to "beta".
{{< /warning >}}

This guide lets you quickly evaluate Istio ambient service mesh. These steps require you to have
a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}). You can use any supported platform, for
example [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or
others specified by the
[platform-specific setup instructions](/docs/setup/platform-setup/).

Follow these steps to get started with ambient:

1. [Download and install](#download)
1. [Deploy the sample application](#bookinfo)
1. [Adding your application to ambient](#addtoambient)
1. [Secure application access](#secure)
1. [Control traffic](#control)
1. [Uninstall](#uninstall)

## Download and install {#download}

1.  Download the [alpha version of Istio](https://github.com/istio/istio/wiki/Dev-Builds) with support for ambient mesh.
    If you don’t have a Kubernetes cluster, you can set up
    locally (e.g. using kind as below) or deploy one in Google or AWS Cloud:

    {{< text bash >}}
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

1.  The `ambient` profile is designed to help you get started with ambient mesh.
    Install Istio with the `ambient` profile on your Kubernetes cluster, using
    the `istioctl` command downloaded above:

    {{< text bash >}}
    $ istioctl install --set profile=ambient
    {{< /text >}}

1.  After running the above command, you’ll get the following output that indicates
    these five components are installed successfully!

    {{< text plain >}}
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ CNI installed
    ✔ Ingress gateways installed
    ✔ Ztunnel installed
    ✔ Installation complete
    {{< /text >}}

## Deploy the sample application {#bookinfo}

You’ll use the sample [bookinfo application](/docs/examples/bookinfo/), which is part of
the Istio distribution that you downloaded above. In ambient mode, you deploy applications to
your Kubernetes cluster exactly the same way you would
without Istio. This means that you can have your applications running in your cluster before
you enable ambient mesh and have them join the mesh without needing to restart or
reconfigure them.

{{< warning >}}
Make sure the default namespace does not include the label `istio-injection=enabled` because when using ambient you do not want Istio to inject sidecars into the application pods.
{{< /warning >}}

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl apply -f samples/sleep/notsleep.yaml
{{< /text >}}

Note: `sleep` and `notsleep` are two simple applications that can serve as curl clients.

Connect `productpage` to the Istio ingress gateway so you can access the bookinfo
app from outside of the cluster:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

Test your bookinfo application, it should work with or without the gateway. Note: you can replace `istio-ingressgateway.istio-system` below with its load balancer IP (or hostname) if it has one:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

## Adding your application to ambient {#addtoambient}

You can enable all pods in a given namespace to be part of the ambient mesh
by simply labeling the namespace:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
{{< /text >}}

Congratulations! You have successfully added all pods in the default namespace
to the ambient mesh. The best part is that there was no need to restart or redeploy anything!

Send some test traffic:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n10
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n10
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n10
{{< /text >}}

You’ll immediately gain mTLS communication and L4 telemetry among the applications in the Ambient mesh.
If you follow the instructions to install [Prometheus](/docs/ops/integrations/prometheus/#installation)
and [Kiali](/docs/ops/integrations/kiali/#installation), you’ll be able to visualize your application
in Kiali’s dashboard:

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali dashboard" >}}

## Secure Application Access {#secure}

After you have added your application to ambient mesh, you can secure application access using L4
authorization policies. This lets you control access to and from a service based on client workload
identities, but not at the L7 level, such as HTTP methods like `GET` and `POST`.

### L4 Authorization Policy

Explicitly allow the `sleep` service account and `istio-ingressgateway` service accounts to call
 the `productpage` service:

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
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
EOF
{{< /text >}}

Confirm the above authorization policy is working:

{{< text bash >}}
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n10
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n10
$ # this should fail with a connection reset error code 56
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n10
{{< /text >}}

### L7 Authorization Policy

Using the Kubernetes Gateway API, you can deploy a waypoint proxy for the `productpage` service that uses the `bookinfo-productpage` service account. Any traffic going to the `productpage` service will be mediated, enforced and observed by the Layer 7 (L7) proxy.
Install Kubernetes Gateway CRDs, which don’t come installed by default on most Kubernetes clusters:

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.6.1" | kubectl apply -f -; }
{{< /text >}}

Deploy a waypoint proxy for the `productpage` service:

{{< text bash >}}
$ istioctl x waypoint apply --service-account bookinfo-productpage
{{< /text >}}

View the `productpage` waypoint proxy status; you should see the details of the gateway
resource with `Ready` status:

{{< text bash >}}
$ kubectl get gtw bookinfo-productpage -o yaml
{{< /text >}}

Verify that the waypoint proxy status is ready:

{{< text plaintext >}}
...
status:
  conditions:
  - lastTransitionTime: "2023-02-24T03:22:43Z"
    message: Deployed waypoint proxy to "default" namespace for "bookinfo-productpage" service account
    observedGeneration: 1
    reason: Ready
    status: "True"
    type: Ready
{{< /text >}}

Update our `AuthorizationPolicy` to explicitly allow the `sleep` service account and `istio-ingressgateway` service accounts to `GET` the `productpage` service, but perform no other operations:

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
     istio.io/gateway-name: bookinfo-productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

Confirm the above authorization policy is working:

{{< text bash >}}
$ # this should fail with an RBAC error because it is not a GET operation
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ -X DELETE
$ # this should fail with an RBAC error because the identity is not allowed
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/  | head -n1
$ # this should continue to work
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

## Control Traffic {#control}

Deploy a `waypoint` proxy for the review service, using the `bookinfo-review` service account, so that any traffic going to the review service will be mediated by the waypoint proxy.

{{< text bash >}}
$ istioctl x waypoint apply --service-account bookinfo-reviews
{{< /text >}}

Apply the reviews virtual service to control 90% traffic to reviews v1 and 10% traffic to reviews v2.

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-reviews.yaml
{{< /text >}}

Confirm that roughly 10% traffic from the 100 requests go to reviews-v2:

{{< text bash >}}
$ kubectl exec -it deploy/sleep -- sh -c 'for i in $(seq 1 100); do curl -s http://istio-ingressgateway.istio-system/productpage | grep reviews-v.-; done'
{{< /text >}}

## Uninstall {#uninstall}

To delete the Bookinfo sample application and its configuration, see [`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).

To remove the `sleep` and `notsleep` applications:

{{< text bash >}}
$ kubectl delete -f samples/sleep/sleep.yaml
$ kubectl delete -f samples/sleep/notsleep.yaml
{{< /text >}}

To remove the `productpage-viewer` authorization policy and uninstall Istio:

{{< text bash >}}
$ kubectl delete authorizationpolicy productpage-viewer
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

The label to instruct Istio to automatically include applications in the `default` namespace to ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}
