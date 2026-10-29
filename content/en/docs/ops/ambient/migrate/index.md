---
title: Migrating from Sidecars to Ambient
description: How to migrate existing sidecar topology to Ambient
weight: 1
owner: istio/wg-networking-maintainers
test: no
---

# Migrating from Sidecars to Ambient

This guide lets you quickly migrate from Istio's sidecars to Istio's {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}).
You can install Istio ambient mode on [any supported Kubernetes platform](/docs/setup/platform-setup/), but this guide will assume the use of [kind](https://kind.sigs.k8s.io/) for simplicity.

{{< tip >}}
Note that ambient mode currently requires the use of [istio-cni](/docs/setup/additional-setup/cni) to configure Kubernetes nodes, which must run as a privileged pod. Ambient mode is compatible with every major CNI that previously supported sidecar mode.
{{< /tip >}}

Follow these steps to get started with Istio's ambient mode:

1. [Download and install Istio](#download)
1. [Deploy the sample application](#bookinfo)
1. [Open the application to outside traffic](#ip)
1. [Install Ambient-enabled Istio](#ambient)
1. [Disable sidecar injection](#disable)
1. [Adding your application to ambient](#addtoambient)

## Download and install {#download}
1.  Install [kind](https://kind.sigs.k8s.io/)

1.  Download the [latest version of Istio](https://istio.io/latest/docs/setup/getting-started/#download) (v1.21.0 or later) with Alpha support for ambient mode.

1.  Deploy a new local `kind` cluster:

    {{< text syntax=bash snip_id=none >}}
    $ kind create cluster --config=- <<EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: sidecar-to-ambient
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

    {{< tip >}}
    {{< boilerplate gateway-api-future >}}
    {{< boilerplate gateway-api-choose >}}
    {{< /tip >}}

## Install Istio {#install}

1.  For this installation, we use the `demo`
    [configuration profile](https://istio.io/latest/docs/setup/additional-setup/config-profiles/). It's
    selected to have a good set of defaults for testing, but there are other
    profiles for production or performance testing.

    {{< warning >}}
    If your platform has a vendor-specific configuration profile, e.g., Openshift, use
    it in the following command, instead of the `demo` profile. Refer to your
    [platform instructions](/docs/setup/platform-setup/) for details.
    {{< /warning >}}

    Unlike [Istio Gateways](https://istio.io/latest/docs/concepts/traffic-management/#gateways), creating
    [Kubernetes Gateways](https://gateway-api.sigs.k8s.io/api-types/gateway/) will, by default, also
    [deploy associated gateway proxy services](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
    Therefore, because they won't be used, we disable the deployment of the default Istio gateway services that
    are normally installed as part of the `demo` profile.

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Installation complete
    {{< /text >}}

1.  Add a namespace label to instruct Istio to automatically inject Envoy
    sidecar proxies when you deploy your application later:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## Deploy the sample application {#bookinfo}

1.  Deploy the [`Bookinfo` sample application](https://istio.io/latest/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

1.  The application will start. As each pod becomes ready, the Istio sidecar will be
    deployed along with it.

    {{< text bash >}}
    $ kubectl get pods
    NAME                              READY   STATUS    RESTARTS   AGE
    details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
    productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
    ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
    reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
    reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
    reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
    {{< /text >}}

1.  Verify everything is working correctly up to this point. Run this command to
    see if the app is running inside the cluster and serving HTML pages by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Open the application to outside traffic {#ip}

The Bookinfo application is deployed but not accessible from the outside. To make it accessible,
you need to create an
[Istio Ingress Gateway](/docs/concepts/traffic-management/#gateways), which maps a path to a
route at the edge of your mesh.

1.  Associate this application with the Istio gateway:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

### Determining the ingress IP and ports

1. Set the `INGRESS_HOST` and `INGRESS_PORT` variables for accessing the gateway:

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    $ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    {{< /text >}}

1. Set `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1. Ensure an IP address and port were successfully assigned to the environment variable:

    {{< text bash >}}
    $ echo "$GATEWAY_URL"
    169.48.8.37:80
    {{< /text >}}

### Verify external access {#confirm}

Confirm that the Bookinfo application is accessible from outside the cluster
by viewing the Bookinfo product page using a browser.

1.  Run the following command to retrieve the external address of the Bookinfo application.

    {{< text bash >}}
    $ echo "http://$GATEWAY_URL/productpage"
    {{< /text >}}

1.  Paste the output from the previous command into your web browser and confirm that the Bookinfo product page is displayed.

***

### Install Ambient-enabled Istio {#ambient}

Install Istio with the `ambient` profile on your Kubernetes cluster, using the version of `istioctl` downloaded above:

{{< text bash >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
four components (including ***ztunnel***) have been installed successfully!

{{< text >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

***

6)  Verify the installed components using the following commands:

### Istio APIs

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-cni-node-zq94l                    1/1     Running   0          2m7s
istio-ingressgateway-56b9cb5485-ksnvc   1/1     Running   0          2m7s
istiod-56d848857c-mhr5w                 1/1     Running   0          2m9s
ztunnel-srrnm                           1/1     Running   0          2m5s
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
{{< /text >}}

***

### K8s Gateway API

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-d9rdt      1/1     Running   0          2m15s
istiod-56d848857c-pwsd6   1/1     Running   0          2m23s
ztunnel-wp7hk             1/1     Running   0          2m9s
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
{{< /text >}}

***

### Disable sidecar injection {#disable}

Now that we have enabled Ambient mode, we need to remove the sidecar injection label in the namespace:

{{< text bash >}}
$ kubectl label ns default istio-injection-
namespace/default unlabeled
{{< /text >}}

## Adding your application to the ambient mesh {#addtoambient}

Ambient mesh data plane relies on the ztunnel DaemonSet to redirect traffic. Before we label the namespace to be part of an ambient mesh, check the ztunnel pods to make sure they are on a healthy state:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=ztunnel -o wide
NAME            READY   STATUS    RESTARTS   AGE     IP            NODE                          NOMINATED NODE   READINESS GATES
ztunnel-29m52   1/1     Running   0          2m15s   10.244.0.18   istio-testing-control-plane   <none>           <none>
{{< /text >}}

Now you can enable all pods in a given namespace to be part of an ambient mesh
by simply labeling the namespace:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
{{< /text >}}

Check the ztunnel logs for the proxy has received the network namespace (netns) information about an ambient application pod, and has started proxying for it:

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system | grep -o ".*starting proxy"
... received netns, starting proxy
{{< /text >}}

Restart pods in the target namespace to get rid of the sidecar:

{{< text bash >}}
$ kubectl rollout restart deployment -n default
deployment.apps/bookinfo-gateway-istio restarted
deployment.apps/details-v1 restarted
deployment.apps/productpage-v1 restarted
deployment.apps/ratings-v1 restarted
deployment.apps/reviews-v1 restarted
deployment.apps/reviews-v2 restarted
deployment.apps/reviews-v3 restarted
{{< /text >}}

Check the pods to make sure you have only one container now:

{{< text bash >}}
$ kubectl get pods -n default
NAME                                     READY   STATUS    RESTARTS   AGE
bookinfo-gateway-istio-98bb74cc9-8ksx7   1/1     Running   0          37s
details-v1-7cc67b5dc6-jsjmg              1/1     Running   0          37s
productpage-v1-7bc87fd58d-zdddp          1/1     Running   0          37s
ratings-v1-55cdcc47b4-v7vjf              1/1     Running   0          37s
reviews-v1-5c6b6bbb7d-hgm7s              1/1     Running   0          37s
reviews-v2-fc5bb5b7b-tkrpw               1/1     Running   0          37s
reviews-v3-5f6d9d6bc8-p2bjw              1/1     Running   0          37s
{{< /text >}}

Now, send some test traffic:

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
If you follow the instructions to install [Prometheus](https://istio.io/latest/docs/ops/integrations/prometheus/#installation)
and [Kiali](https://istio.io/latest/docs/ops/integrations/kiali/#installation), you’ll be able to visualize your application
in Kiali’s dashboard.