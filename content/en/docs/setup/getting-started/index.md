---
title: Getting Started
description: Try Istio’s features quickly and easily.
weight: 5
aliases:
    - /docs/setup/kubernetes/getting-started/
    - /docs/setup/kubernetes/
    - /docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
---

This guide lets you quickly evaluate Istio. If you are already familiar with
Istio or interested in installing other configuration profiles or
advanced [deployment models](/docs/ops/deployment/deployment-models/), see
[Customizable Install with `istioctl`](/docs/setup/install/istioctl/)
instead.

These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
compatible version of Kubernetes. You can use any supported platform, for
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
    To download a specific version, you can add a variable on the command line.
    For example to download Istio 1.4.3, you would run
      `curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.4.3 sh -`
    {{< /tip >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Installation YAML files for Kubernetes in `install/kubernetes`
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

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo
    Detected that your cluster does not support third party JWT authentication. Falling back to less secure first party JWT
    - Applying manifest for component Base...
    ✔ Finished applying manifest for component Base.
    - Applying manifest for component Pilot...
    ✔ Finished applying manifest for component Pilot.
    Waiting for resources to become ready...
    - Applying manifest for component EgressGateways...
    - Applying manifest for component IngressGateways...
    - Applying manifest for component AddonComponents...
    ✔ Finished applying manifest for component EgressGateways.
    ✔ Finished applying manifest for component IngressGateways.
    ✔ Finished applying manifest for component AddonComponents.

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

1.  The application will start. As each pod becomes ready, the Istio sidecar will
    deploy along with it.

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
    NAME                              READY   STATUS            RESTARTS   AGE
    details-v1-78d78fbddf-tj56d       0/2     PodInitializing   0          2m30s
    productpage-v1-85b9bf9cd7-zg7tr   0/2     PodInitializing   0          2m29s
    ratings-v1-6c9dbf6b45-5djtx       0/2     PodInitializing   0          2m29s
    reviews-v1-564b97f875-dzdt5       0/2     PodInitializing   0          2m30s
    reviews-v2-568c7c9d8f-p5wrj       1/2     Running           0          2m29s
    reviews-v3-67b4988599-7nhwz       0/2     PodInitializing   0          2m29s
    {{< /text >}}

    {{< tip >}}
    Re-run the previous command and wait until all pods report READY 2 / 2 and
    STATUS Running before you go to the next step. This might take a few minutes
    depending on your platform.
    {{< /tip >}}

1.  Verify everything is working correctly up to this point. Run this command to
    see if the app is running inside the cluster and serving HTML pages by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
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

1.  Confirm the gateway has been created:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               AGE
    bookinfo-gateway   32s
    {{< /text >}}

### Determining the ingress IP and ports

Follow these instructions to set the `INGRESS_HOST` and `INGRESS_PORT` variables
for accessing the gateway. Use the tabs to choose the instructions for your
chosen platform:

{{< tabset category-name="gateway-ip" >}}

{{< tab name="Minikube" category-value="external-lb" >}}

Set the ingress ports:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

Ensure a port was successfully assigned to each environment variable:

{{< text bash >}}
$ echo $INGRESS_PORT
32194
{{< /text >}}

{{< text bash >}}
$ echo $SECURE_INGRESS_PORT
31632
{{< /text >}}

Set the ingress IP:

{{< text bash >}}
$ export INGRESS_HOST=$(minikube ip)
{{< /text >}}

Ensure an IP address was successfully assigned to the environment variable:

{{< text bash >}}
$ echo $INGRESS_HOST
192.168.4.102
{{< /text >}}

Run this command in a new terminal window to start a Minikube tunnel that
sends traffic to your Istio Ingress Gateway:

{{< text bash >}}
$ minikube tunnel
{{< /text >}}

{{< /tab >}}

{{< tab name="Other platforms" category-value="node-port" >}}

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers:

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

If the `EXTERNAL-IP` value is set, your environment has an external load balancer that you can use for the ingress gateway.
If the `EXTERNAL-IP` value is `<none>` (or perpetually `<pending>`), your environment does not provide an external load balancer for the ingress gateway.
In this case, you can access the gateway using the service's [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport).

Choose the instructions corresponding to your environment:

**Follow these instructions if you have determined that your environment has an external load balancer.**

Set the ingress IP and ports:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
In certain environments, the load balancer may be exposed using a host name, instead of an IP address.
In this case, the ingress gateway's `EXTERNAL-IP` value will not be an IP address,
but rather a host name, and the above command will have failed to set the `INGRESS_HOST` environment variable.
Use the following command to correct the `INGRESS_HOST` value:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

**Follow these instructions if your environment does not have an external load balancer and choose a node port instead.**

Set the ingress ports:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

_GKE:_

{{< text bash >}}
$ export INGRESS_HOST=<workerNodeAddress>
{{< /text >}}

You need to create firewall rules to allow the TCP traffic to the `ingressgateway` service's ports.
Run the following commands to allow the traffic for the HTTP port, the secure port (HTTPS) or both:

{{< text bash >}}
$ gcloud compute firewall-rules create allow-gateway-http --allow tcp:$INGRESS_PORT
$ gcloud compute firewall-rules create allow-gateway-https --allow tcp:$SECURE_INGRESS_PORT
{{< /text >}}

_Docker For Desktop:_

{{< text bash >}}
$ export INGRESS_HOST=127.0.0.1
{{< /text >}}

_Other environments (e.g., IBM Cloud Private, etc.):_

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1.  Set `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1.  Ensure an IP address and port were successfully assigned to the environment variable:

    {{< text bash >}}
    $ echo $GATEWAY_URL
    192.168.99.100:32194
    {{< /text >}}

### Verify external access {#confirm}

Confirm that the Bookinfo application is accessible from outside. Copy the
output of this command and paste into your browser:

{{< text bash >}}
$ echo http://$GATEWAY_URL/productpage
{{< /text >}}

## View the dashboard {#dashboard}

Istio has several optional dashboards installed by the `demo` installation. The
Kiali dashboard helps you understand the structure of your service mesh by
displaying the topology and indicates the health of your mesh.

1.  Access the Kiali dashboard. The default user name is `admin` and default password is `admin`.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  In the left navigation menu, select _Graph_ and in the _Namespace_ drop down, select _default_.

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
- [Rate limiting](/docs/tasks/policy-enforcement/rate-limiting/)
- [Accessing external services](/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizing your mesh](/docs/tasks/observability/kiali/)

Before you customize Istio for production use, see these resources:

- [Deployment models](/docs/ops/deployment/deployment-models/)
- [Deployment best practices](/docs/ops/best-practices/deployment/)
- [Pod requirements](/docs/ops/deployment/requirements/)
- [General installation instructions](/docs/setup/)

## Join the Istio community

We welcome you to ask questions and give us feedback by joining the
[Istio community](/about/community/join/).

## Uninstall

The uninstall deletes the RBAC permissions, the `istio-system` namespace, and
all resources hierarchically under it. It is safe to ignore errors for
non-existent resources because they may have been deleted hierarchically.

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

To delete the `Bookinfo` sample application and its configuration, see
[`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).
