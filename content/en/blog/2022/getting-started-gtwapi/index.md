---
title: Getting started with the Kubernetes Gateway API
description: Using the Gateway API to configure ingress traffic for your Kubernetes cluster.
publishdate: 2022-12-14
attribution: Frank Budinsky (IBM)
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

Whether you're running your Kubernetes application services using Istio, or any service mesh for that matter,
or simply using ordinary services in a Kubernetes cluster, you need to provide access to your application services
for clients outside of the cluster. If you're using plain Kubernetes clusters, you're probably using
Kubernetes [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resources
to configure the incoming traffic. If you're using Istio, you are more likely
to be using Istio's recommended configuration resources,
[Gateway](/docs/reference/config/networking/gateway/) and [VirtualService](/docs/reference/config/networking/virtual-service/),
to do the job.

The Kubernetes Ingress resource has for some time been known to have significant shortcomings, especially
when using it to configure ingress traffic for large applications and when working with protocols other
than HTTP. One problem is that it configures both
the client-side L4-L6 properties (e.g., ports, TLS, etc.) and service-side L7 routing in a single resource,
configurations that for large applications should be managed by different teams and in different namespaces.
Also, by trying to draw a common denominator across
different HTTP proxies, Ingress is only able to support the most basic HTTP routing and ends up pushing
every other feature of modern proxies into non-portable annotations.

To overcome Ingress' shortcomings, Istio introduced its own configuration API for ingress traffic management.
With Istio's API, the client-side representation is defined using an Istio Gateway resource, with L7 traffic
moved to a VirtualService, not coincidentally the same configuration resource used for routing traffic between
services inside the mesh. Although the Istio API provides a good solution for ingress traffic management
for large-scale applications, it is unfortunately an Istio-only API. If you are using a different service
mesh implementation, or no service mesh at all, you're out of luck.

## Enter Gateway API

There's a lot of excitement surrounding a new Kubernetes traffic management API,
dubbed [Gateway API](https://gateway-api.sigs.k8s.io/), which has recently been
[promoted to Beta](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/).
Gateway API provides a set of Kubernetes configuration resources for ingress traffic control
that, like Istio's API, overcomes the shortcoming of Ingress, but unlike Istio's, is a standard Kubernetes
API with broad industry agreement. There are [several implementations](https://gateway-api.sigs.k8s.io/implementations/)
of the API in the works, including a Beta implementation
in Istio, so now may be a good time to start thinking about how you can start moving your ingress
traffic configuration from Kubernetes Ingress or Istio Gateway/VirtualService to the new Gateway API.

Whether or not you use, or plan to use, Istio to manage your service mesh, the Istio implementation of the
Gateway API can easily be used to get started with your cluster ingress control.
Even though it's still a Beta feature in Istio, mostly driven by the fact that the Gateway API is itself
still a Beta level API, Istio's implementation is quite robust because under the covers it uses Istio's
same tried-and-proven internal resources to implement the configuration.

## Gateway API quick-start

To get started using the Gateway API, you need to first download the CRDs, which don't come installed by default
on most Kubernetes clusters, at least not yet:

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

Once the CRDs are installed, you can use them to create Gateway API resources to configure ingress traffic,
but in order for the resources to work, the cluster needs to have a gateway controller running.
You can enable Istio's gateway controller implementation by simply installing Istio with the minimal profile:

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ ./bin/istioctl install --set profile=minimal -y
{{< /text >}}

Your cluster will now have a fully-functional implementation of the Gateway API,
via Istio's gateway controller named `istio.io/gateway-controller`,
ready to use.

### Deploy a Kubernetes target service

To try out the Gateway API, we'll use the Istio [helloworld sample]({{< github_tree >}}/samples/helloworld)
as an ingress target, but only running as a simple Kubernetes service
without sidecar injection enabled. Because we're only going to use the Gateway API to control ingress traffic
into the "Kubernetes cluster", it makes no difference if the target service is running inside or
outside of a mesh.

We'll use the following command to deploy the helloworld service:

{{< text bash >}}
$ kubectl create ns sample
$ kubectl apply -f @samples/helloworld/helloworld.yaml@ -n sample
{{< /text >}}

The helloworld service includes two backing deployments, corresponding to different versions (`v1` and `v2`).
We can confirm they are both running using the following command:

{{< text bash >}}
$ kubectl get pod -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-s7zfc   1/1     Running   0          10s
helloworld-v2-54df5f84b-9hxgww   1/1     Running   0          10s
{{< /text >}}

### Configure the helloworld ingress traffic

With the helloworld service up and running, we can now use the Gateway API to configure ingress traffic for it.

The ingress entry point is defined using a
[Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.Gateway) resource:

{{< text bash >}}
$ kubectl create namespace sample-ingress
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: sample-gateway
  namespace: sample-ingress
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "*.sample.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

The controller that will implement a Gateway is selected by referencing a
[GatewayClass](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.GatewayClass).
There must be at least one GatewayClass defined in the cluster to have functional Gateways.
In our case, we're selecting Istio's gateway controller, `istio.io/gateway-controller`, by referencing its
associated GatewayClass (named `istio`) with the `gatewayClassName: istio` setting in the Gateway.

Notice that unlike Ingress, a Kubernetes Gateway doesn't include any references to the target service,
helloworld. With the Gateway API, routes to services are defined in separate configuration resources
that get attached to the Gateway to direct subsets of traffic to specific services,
like helloworld in our example. This separation allows us to define the Gateway and routes in
different namespaces, presumably managed by different teams. Here, while acting in the role of cluster
operator, we're applying the Gateway in the `sample-ingress` namespace. We'll add the route,
below, in the `sample` namespace, next to the helloworld service itself, on behalf of the application developer.

Because the Gateway resource is owned by a cluster operator, it can very well be used to provide ingress
for more than one team's services, in our case more than just the helloworld service.
To emphasize this point, we've set hostname to `*.sample.com` in the Gateway,
allowing routes for multiple subdomains to be attached.

After applying the Gateway resource, we need to wait for it to be ready before retrieving its external address:

{{< text bash >}}
$ kubectl wait -n sample-ingress --for=condition=programmed gateway sample-gateway
$ export INGRESS_HOST=$(kubectl get -n sample-ingress gateway sample-gateway -o jsonpath='{.status.addresses[0].value}')
{{< /text >}}

Next, we attach an [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.HTTPRoute)
to the `sample-gateway` (i.e., using the `parentRefs` field) to expose and route traffic to the helloworld service:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

Here we've exposed the `/hello` path of the helloworld service to clients outside of the cluster,
specifically via host `helloworld.sample.com`.
You can confirm the helloworld sample is accessible using curl:

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
{{< /text >}}

Since no version routing has been configured in the route rule, you should see an equal split of traffic,
about half handled by `helloworld-v1` and the other half handled by `helloworld-v2`.

### Configure weight-based version routing

Among other "traffic shaping" features, you can use Gateway API to send all of the traffic to one of the versions
or split the traffic based on request percentages. For example, you can use the following rule to distribute the
helloworld traffic 90% to `v1`, 10% to `v2`:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld-v1
      port: 5000
      weight: 90
    - name: helloworld-v2
      port: 5000
      weight: 10
EOF
{{< /text >}}

Gateway API relies on version-specific backend service definitions for the route targets,
`helloworld-v1` and `helloworld-v2` in this example.
The helloworld sample already includes service definitions for the helloworld versions `v1` and `v2`,
we just need to run the following command to define them:

{{< text bash >}}
$ kubectl apply -n sample -f @samples/helloworld/gateway-api/helloworld-versions.yaml@
{{< /text >}}

Now, we can run the previous curl commands again:

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
{{< /text >}}

This time we see that about 9 out of 10 requests are now handled by `helloworld-v1` and only about 1 in 10 are handled by `helloworld-v2`.

## Gateway API for internal mesh traffic

You may have noticed that we've been talking about the Gateway API only as an ingress configuration API,
often referred to as north-south traffic management, and not an API for service-to-service (aka, east-west)
traffic management within a cluster.

If you are using a service mesh, it would be highly desirable to use the same API
resources to configure both ingress traffic routing and internal traffic, similar to the way Istio uses
VirtualService to configure route rules for both. Fortunately, the Kubernetes Gateway API is working to
add this support.
Although not as mature as the Gateway API for ingress traffic, an effort
known as the [Gateway API for Mesh Management and Administration (GAMMA)](https://gateway-api.sigs.k8s.io/contributing/gamma/)
initiative is underway to make this a reality and Istio intends to make Gateway API the default API for all
of its traffic management [in the future](/blog/2022/gateway-api-beta/).

The first significant [Gateway Enhancement Proposal (GEP)](https://gateway-api.sigs.k8s.io/geps/gep-1426/)
has recently been accepted and is, in-fact, already available to use in Istio.
To try it out, you'll need to use the
[experimental version](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
of the Gateway API CRDs, instead of the standard Beta version we installed above, but otherwise, you're ready to go.
Check out the Istio [request routing task](/docs/tasks/traffic-management/request-routing/)
to get started.

## Summary

In this article, we've seen how a light-weight minimal install of Istio can be used to provide a Beta-quality implementation
of the new Kubernetes Gateway API for cluster ingress traffic control. For Istio users, the Istio implementation also lets
you start trying out the experimental Gateway API support for east-west traffic management within the mesh.

Much of Istio's documentation, including all of the [ingress tasks](/docs/tasks/traffic-management/ingress/)
and several mesh-internal traffic management tasks, already includes parallel instructions for
configuring traffic using either the Gateway API or the Istio configuration API.
Check out the [Gateway API task](/docs/tasks/traffic-management/ingress/gateway-api/) for more information about the
Gateway API implementation in Istio.
