---
title: Kubernetes Gateway API
description: Describes how to configure the Kubernetes Gateway API with Istio.
weight: 50
aliases:
    - /docs/tasks/traffic-management/ingress/service-apis/
    - /latest/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

This task describes how to configure Istio to expose a service outside the service mesh cluster using the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/).
These APIs are an actively developed evolution of the Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) APIs.

## Setup

1. The Gateway APIs do not come installed by default on most Kubernetes clusters. Install the Gateway API CRDs if they are not present:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.5.0" | kubectl apply -f -; }
    {{< /text >}}

1. Install Istio using the `minimal` profile:

    {{< text bash >}}
    $ istioctl install --set profile=minimal -y
    {{< /text >}}

## Differences from Istio APIs

The Gateway APIs share a lot of similarities to the Istio APIs such as Gateway and VirtualService.
The main resource shares the same name, `Gateway`, and the resources serve similar goals.

The new Gateway APIs aim to take the learnings from various Kubernetes ingress implementations, including Istio,
to build a standardized vendor neutral API. These APIs generally serve the same purposes as Istio Gateway and VirtualService,
with a few key differences:

* In Istio APIs, a `Gateway` *configures* an existing gateway Deployment/Service that has [been deployed](/docs/setup/additional-setup/gateway/).
  In the Gateway APIs, the `Gateway` resource both *configures and deploys* a gateway.
  See [Deployment Methods](#deployment-methods) for more information.
* In the Istio `VirtualService`, all protocols are configured within a single resource.
  In the Gateway APIs, each protocol type has its own resource, such as `HTTPRoute` and `TCPRoute`.
* While the Gateway APIs offer a lot of rich routing functionality, it does not yet cover 100% of Istio's feature set.
  Work is ongoing to extend the API to cover these use cases, as well as utilizing the APIs [extensibility](https://gateway-api.sigs.k8s.io/#gateway-api-concepts)
  to better expose Istio functionality.

## Configuring a Gateway

See the [Gateway API](https://gateway-api.sigs.k8s.io/) documentation for information about the APIs.

In this example, we will deploy a simple application and expose it externally using a `Gateway`.

1. First, deploy a test application:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Deploy the Gateway API configuration:

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-ingress
    spec:
      gatewayClassName: istio
      listeners:
      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  Set the Ingress Host

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=ready gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[*].value}')
    {{< /text >}}

1.  Access the _httpbin_ service using _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Note the use of the `-H` flag to set the _Host_ HTTP header to
    "httpbin.example.com". This is needed because the `HTTPRoute` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Cleanup

1. Uninstall Istio and the `helloworld` sample:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    $ kubectl delete ns istio-ingress
    {{< /text >}}

2. Remove the Gateway API CRDs if they are no longer needed:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/service-apis/config/crd?ref=v0.5.0" | kubectl delete -f -
    {{< /text >}}

## Deployment methods

In the example above, you did not need to install an ingress gateway `Deployment` prior to configuring a Gateway.
In the default configuration, a gateway `Deployment` and `Service` is automatically provisioned based on the `Gateway` configuration.
For advanced use cases, manual deployment is still allowed.

### Automated Deployment

By default, each `Gateway` will automatically provision a `Service` and `Deployment` of the same name.
These configurations will be updated automatically if the `Gateway` changes (for example, if a new port is added).

These resources can be customized in a few ways:

* Annotations and labels on the `Gateway` will be copied to the `Service` and `Deployment`.
  This allows configuring things such as [Internal load balancers](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer) that read from these fields.
* Istio offers an additional annotation to configure the generated resources:

    |Annotation|Purpose|
    |----------|-------|
    |`networking.istio.io/service-type`|Controls the `Service.spec.type` field. For example, set to `ClusterIP` to not expose the service externally. The default is `LoadBalancer`.|

* The `Service.spec.loadBalancerIP` field can be explicit set by configuring the `addresses` field:

    {{< text yaml >}}
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: Gateway
    metadata:
      name: gateway
    spec:
      addresses:
      - value: 192.0.2.0
        type: IPAddress
    ...
    {{< /text >}}

Note: only one address may be specified.

* (Advanced) The generated Pod configuration can be configured by [Custom Injection Templates](/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental).

### Manual Deployment

If you do not want to have an automated deployment, a `Deployment` and `Service` can be [configured manually](/docs/setup/additional-setup/gateway/).

When this option is done, you will need to manually link the `Gateway` to the `Service`, as well as keep their port configuration in sync.

To link a `Gateway` to a `Service`, configure the `addresses` field to point to a **single** `Hostname`.

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
...
{{< /text >}}

## Mesh Traffic

The Gateway API can also be used to configure mesh traffic.
This is done by configuring the `parentRef`, to point to the `istio` `Mesh`.
This resource does not actually exist in the cluster and is only used to signal that the Istio mesh should be used.

For example, to redirect calls to `example.com` to an in-cluster `Service` named `example`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:
  - kind: Mesh
    name: istio
  hostnames: ["example.com"]
  rules:
  - backendRefs:
    - name: example
      port: 80
{{< /text >}}
