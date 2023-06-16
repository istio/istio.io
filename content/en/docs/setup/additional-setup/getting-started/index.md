---
title: Getting Started with Istio and Kubernetes Gateway API
description: Try Istio’s features quickly and easily.
weight: 5
aliases:
    - /docs/setup/kubernetes/getting-started/
    - /docs/setup/kubernetes/
    - /docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
The following instructions allow you to get started with Istio using the Gateway API.
If you prefer to use the tried-and-proven Istio APIs for traffic management, you should use
[these instructions](/docs/setup/getting-started/) instead.
{{< /tip >}}

{{< warning >}}
The Kubernetes Gateway API CRDs do not come installed by default on most Kubernetes clusters, so make sure they are
installed before using the Gateway API:

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

{{< /warning >}}

This guide lets you quickly evaluate Istio. If you are already familiar with
Istio or interested in installing other configuration profiles or
advanced [deployment models](/docs/ops/deployment/deployment-models/), refer to our
[which Istio installation method should I use?](/about/faq/#install-method-selection)
FAQ page.

These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}). You can use any supported platform, for
example [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or
others specified by the
[platform-specific setup instructions](/docs/setup/platform-setup/).

Follow these steps to get started with Istio:

1. [Download and install Istio](#download)
1. [Deploy the sample application](#bookinfo)
1. [Open the application to outside traffic](#ip)
1. [View the dashboard](#dashboard)

## Download Istio {#download}

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file for your OS, or download and
    extract the latest release automatically (Linux or macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    The command above downloads the latest release (numerically) of Istio.
    You can pass variables on the command line to download a specific version
    or to override the processor architecture.
    For example, to download Istio {{< istio_full_version >}} for the x86_64 architecture,
    run:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Sample applications in `samples/`
    - The [`istioctl`](/docs/reference/commands/istioctl) client binary in the
      `bin/` directory.

1.  Add the `istioctl` client to your path (Linux or macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Install Istio {#install}

1.  For this installation, we use the `demo`
    [configuration profile](/docs/setup/additional-setup/config-profiles/). It's
    selected to have a good set of defaults for testing, but there are other
    profiles for production or performance testing.

    {{< warning >}}
    If your platform has a vendor-specific configuration profile, e.g., Openshift, use
    it in the following command, instead of the `demo` profile. Refer to your
    [platform instructions](/docs/setup/platform-setup/) for details.
    {{< /warning >}}

    Unlike [Istio Gateways](/docs/concepts/traffic-management/#gateways), creating
    [Kubernetes Gateways](https://gateway-api.sigs.k8s.io/api-types/gateway/) will, by default, also
    [deploy associated gateway proxy services](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
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

1.  Deploy the [`Bookinfo` sample application](/docs/examples/bookinfo/):

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
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    and

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

    {{< tip >}}
    Re-run the previous command and wait until all pods report READY `2/2` and
    STATUS `Running` before you go to the next step. This might take a few minutes
    depending on your platform.
    {{< /tip >}}

1.  Verify everything is working correctly up to this point. Run this command to
    see if the app is running inside the cluster and serving HTML pages by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Open the application to outside traffic {#ip}

The Bookinfo application is deployed but not accessible from the outside. To make it accessible,
you need to create an ingress gateway, which maps a path to a
route at the edge of your mesh.

1.  Create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) for the Bookinfo application:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Because creating a Kubernetes `Gateway` resource will also
    [deploy an associated proxy service](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment),
    run the following command to wait for the gateway to be ready:

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

1.  Ensure that there are no issues with the configuration:

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

### Determining the ingress IP and ports

1. Set the `INGRESS_HOST` and `INGRESS_PORT` variables for accessing the gateway:

    {{< boilerplate external-loadbalancer-support >}}

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
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

## View the dashboard {#dashboard}

Istio integrates with [several](/docs/ops/integrations) different telemetry applications. These can help you gain
an understanding of the structure of your service mesh, display the topology of the mesh, and analyze the health of your mesh.

Use the following instructions to deploy the [Kiali](/docs/ops/integrations/kiali/) dashboard, along with [Prometheus](/docs/ops/integrations/prometheus/), [Grafana](/docs/ops/integrations/grafana), and [Jaeger](/docs/ops/integrations/jaeger/).

1.  Install [Kiali and the other addons]({{< github_tree >}}/samples/addons) and wait for them to be deployed.

    {{< text bash >}}
    $ kubectl apply -f samples/addons
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

    {{< tip >}}
    If there are errors trying to install the addons, try running the command again. There may
    be some timing issues which will be resolved when the command is run again.
    {{< /tip >}}

1.  Access the Kiali dashboard.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  In the left navigation menu, select _Graph_ and in the _Namespace_ drop down, select _default_.

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    The Kiali dashboard shows an overview of your mesh with the relationships
    between the services in the `Bookinfo` sample application. It also provides
    filters to visualize the traffic flow.

    {{< image link="./kiali-example2.png" caption="Kiali Dashboard" >}}

## Next steps

Congratulations on completing the evaluation installation!

These tasks are a great place for beginners to further evaluate Istio's
features using this `demo` installation:

- [Request routing](/docs/tasks/traffic-management/request-routing/)
- [Fault injection](/docs/tasks/traffic-management/fault-injection/)
- [Traffic shifting](/docs/tasks/traffic-management/traffic-shifting/)
- [Querying metrics](/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizing metrics](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Accessing external services](/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizing your mesh](/docs/tasks/observability/kiali/)

Before you customize Istio for production use, see these resources:

- [Deployment models](/docs/ops/deployment/deployment-models/)
- [Deployment best practices](/docs/ops/best-practices/deployment/)
- [Pod requirements](/docs/ops/deployment/requirements/)
- [General installation instructions](/docs/setup/)

## Join the Istio community

We welcome you to ask questions and give us feedback by joining the
[Istio community](/get-involved/).

## Uninstall

To delete the `Bookinfo` sample application and its configuration, see
[`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).

The Istio uninstall deletes the RBAC permissions and all resources hierarchically
under the `istio-system` namespace. It is safe to ignore errors for non-existent
resources because they may have been deleted hierarchically.

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

The `istio-system` namespace is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

The label to instruct Istio to automatically inject Envoy sidecar proxies is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
