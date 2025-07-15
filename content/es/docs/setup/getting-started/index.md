---
title: Getting Started
description: Try Istio’s features quickly and easily.
weight: 5
aliases:
    - /docs/setup/additional-setup/getting-started/
    - /latest/docs/setup/additional-setup/getting-started/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Want to explore Istio's {{< gloss "ambient" >}}ambient mode{{< /gloss >}}? Visit the [Getting Started with Ambient Mode](/es/docs/ambient/getting-started) guide!
{{< /tip >}}

This guide lets you quickly evaluate Istio. If you are already familiar with
Istio or interested in installing other configuration profiles or
advanced [deployment models](/es/docs/ops/deployment/deployment-models/), refer to our
[which Istio installation method should I use?](/es/about/faq/#install-method-selection)
FAQ page.

You will need a Kubernetes cluster to proceed. If you don't have a cluster, you can use [kind](/es/docs/setup/platform-setup/kind) or any other [supported Kubernetes platform](/es/docs/setup/platform-setup).

Follow these steps to get started with Istio:

1. [Download and install Istio](#download)
1. [Install the Kubernetes Gateway API CRDs](#gateway-api)
1. [Deploy the sample application](#bookinfo)
1. [Open the application to outside traffic](#ip)
1. [View the dashboard](#dashboard)

## Download Istio {#download}

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file for your OS, or [download and
    extract the latest release automatically](/es/docs/setup/additional-setup/download-istio-release)
    (Linux or macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Sample applications in `samples/`
    - The [`istioctl`](/es/docs/reference/commands/istioctl) client binary in the
      `bin/` directory.

1.  Add the `istioctl` client to your path (Linux or macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Install Istio {#install}

For this guide, we use the `demo`
[configuration profile](/es/docs/setup/additional-setup/config-profiles/). It is
selected to have a good set of defaults for testing, but there are other
profiles for production, performance testing or [OpenShift](/es/docs/setup/platform-setup/openshift/).

Unlike [Istio Gateways](/es/docs/concepts/traffic-management/#gateways), creating
[Kubernetes Gateways](https://gateway-api.sigs.k8s.io/api-types/gateway/) will, by default, also
[deploy gateway proxy servers](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
Because they won't be used, we disable the deployment of the default Istio gateway services that
are normally installed as part of the `demo` profile.

1. Install Istio using the `demo` profile, without any gateways:

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Installation complete
    Made this installation the default for injection and validation.
    {{< /text >}}

1.  Add a namespace label to instruct Istio to automatically inject Envoy
    sidecar proxies when you deploy your application later:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## Install the Kubernetes Gateway API CRDs {#gateway-api}

The Kubernetes Gateway API CRDs do not come installed by default on most Kubernetes clusters, so make sure they are
installed before using the Gateway API.

1. Install the Gateway API CRDs, if they are not already present:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

## Deploy the sample application {#bookinfo}

You have configured Istio to inject sidecar containers into any application you deploy in your `default` namespace.

1.  Deploy the [`Bookinfo` sample application](/es/docs/examples/bookinfo/):

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

    The application will start. As each pod becomes ready, the Istio sidecar will be
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

    Note that the pods show `READY 2/2`, confirming they have their application container and the Istio sidecar container.

1.  Validate that the app is running inside the cluster by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Open the application to outside traffic {#ip}

The Bookinfo application is deployed, but not accessible from the outside. To make it accessible,
you need to create an ingress gateway, which maps a path to a
route at the edge of your mesh.

1.  Create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) for the Bookinfo application:

    {{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    By default, Istio creates a `LoadBalancer` service for a gateway. As we will access this gateway by a tunnel, we don't need a load balancer. If you want to learn about how load balancers are configured for external IP addresses, read the [ingress gateways](/es/docs/tasks/traffic-management/ingress/ingress-control/) documentation.

1. Change the service type to `ClusterIP` by annotating the gateway:

    {{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
    $ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
    {{< /text >}}

1. To check the status of the gateway, run:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
    bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
    {{< /text >}}

## Access the application

You will connect to the Bookinfo `productpage` service through the gateway you just provisioned. To access the gateway, you need to use the `kubectl port-forward` command:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Open your browser and navigate to `http://localhost:8080/productpage` to view the Bookinfo application.

{{< image width="80%" link="./bookinfo-browser.png" caption="Bookinfo Application" >}}

If you refresh the page, you should see the book reviews and ratings changing as the requests are distributed across the different versions of the `reviews` service.

## View the dashboard {#dashboard}

Istio integrates with [several different telemetry applications](/es/docs/ops/integrations). These can help you gain
an understanding of the structure of your service mesh, display the topology of the mesh, and analyze the health of your mesh.

Use the following instructions to deploy the [Kiali](/es/docs/ops/integrations/kiali/) dashboard, along with [Prometheus](/es/docs/ops/integrations/prometheus/), [Grafana](/es/docs/ops/integrations/grafana), and [Jaeger](/es/docs/ops/integrations/jaeger/).

1.  Install [Kiali and the other addons]({{< github_tree >}}/samples/addons) and wait for them to be deployed.

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

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

- [Request routing](/es/docs/tasks/traffic-management/request-routing/)
- [Fault injection](/es/docs/tasks/traffic-management/fault-injection/)
- [Traffic shifting](/es/docs/tasks/traffic-management/traffic-shifting/)
- [Querying metrics](/es/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizing metrics](/es/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Accessing external services](/es/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizing your mesh](/es/docs/tasks/observability/kiali/)

Before you customize Istio for production use, see these resources:

- [Deployment models](/es/docs/ops/deployment/deployment-models/)
- [Deployment best practices](/es/docs/ops/best-practices/deployment/)
- [Pod requirements](/es/docs/ops/deployment/application-requirements/)
- [General installation instructions](/es/docs/setup/)

## Join the Istio community

We welcome you to ask questions and give us feedback by joining the
[Istio community](/get-involved/).

## Uninstall

To delete the `Bookinfo` sample application and its configuration, see
[`Bookinfo` cleanup](/es/docs/examples/bookinfo/#cleanup).

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

If you installed the Kubernetes Gateway API CRDs and would now like to remove them, run one of the following commands:

- If you ran any tasks that required the **experimental version** of the CRDs:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}

- Otherwise:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
