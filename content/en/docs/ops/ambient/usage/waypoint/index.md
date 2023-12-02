---
title: L7 Networking & Services with Waypoint
description: User guide for Istio Ambient L7 networking and services using waypoint proxy.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< warning >}}
Ambient is currently in [alpha status](/docs/releases/feature-stages/#feature-phase-definitions).

Please **do not run ambient in production** and be sure to thoroughly review the [feature phase definitions](/docs/releases/feature-stages/#feature-phase-definitions) before use.
In particular, there are known performance, stability, and security issues in the `alpha` release. There are also functional caveats some of which are listed in the [Caveats section](#caveats) of this guide. There are also planned breaking changes, including some that will prevent upgrades. These are all limitations that will be addressed before graduation to `beta`. The current version of this guide is meant to assist early deployments and testing of the alpha version of `ambient`. The guide will continue to get updated as `ambient` itself evolves from alpha to beta status and beyond. 
{{< /warning >}}

## Introduction

This guide provides instructions on how to set up and use the Waypoint proxy layer in Istio Ambient Mesh.

Istio Ambient Mesh is a new way to deploy and manage microservices. In Ambient Mesh, workloads are no longer required to run sidecar proxies to participate in the service mesh. Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.

Ztunnel proxy is used to handle L3 and L4 networking functions, such as mTLS authentication and L4 authorization. For workloads that require L7 networking features, such as HTTP load balancing and fault injection, a waypoint proxy can be deployed. The waypoint proxy is an optional component that is Envoy-based and is responsible for terminating workload HTTP traffic and parsing workload HTTP headers. They also enforce L7 policies and collect L7 metrics.

{{<tip>}}

<!-- Pre-requisites & Supported Topologies -->

Before you begin, make sure that you have already read the [Ztunnel Networking sub-guide](../ztunnel/). This guide assumes that you have the following prerequisites in place:
1. Istio Ambient Mesh installed and configured
2. Ztunnel proxy is installed and running
3. Mutual TLS (mTLS) enabled and configured

{{</tip>}}

This guide describes the functionality and usage of the waypoint proxy and L7 networking functions using Istio Ambient Mesh. We use a sample user journey to describe these functions hence it would be useful to go through this guide in sequence. However we provide links to the sections below in case the reader would like to jump to the appropriate section.

* [Introduction](#introduction)
* [Deciding if you need A Waypoint Proxy](#deciding-if-you-need-a-waypoint-proxy)
* [Current Challenges](#current-challenges)
<!-- * [Differences between Sidecar Mode and Ambient Mode for Waypoint Proxy](#differences) -->
* [Deciding the scope of your Waypoint Proxy](#Deciding-the-scope-of-your-Waypoint-Proxy)
* [Functional Overview](#functional-overview)
* [Deploying an Application](#deploying-an-application)
* [Configuring Waypoint proxy](#configuring-waypoint-proxy)
* [Monitoring the Waypoint Proxy & L7 Networking](#monitoring-the-waypoint-proxy--l7-networking)
* [L7 Fault Injection](#l7-fault-injection)
* [L7 Observability](#l7-observability)
* [L7 Authorization Policy](#l7-authorization-policy)
* [Co-existence of Ambient/ L7 with Side car proxies](#Co-existence-of-Ambient/-L7-with-Side-car-proxies)
* [Control Traffic towards Waypoint Proxy](##control-traffic-towards-waypoint-proxy)
* [Remove Waypoint proxy layer](#remove-waypoint-proxy-layer)

# Deciding if you need A Waypoint proxy

It's possible that the features offered by the secure overlay doesn’t meet your requirements. For instance, you need a rich Layer 7 authorization policy that sets up access based on a certain method and path. Alternatively you may like to conduct a canary test on the updated version of your service or introduce a new version without affecting current traffic. Or, you would like to receive metrics, HTTP access logs, and distributed tracing for some of your services. In order to accomplish these common cases, we'll go over how you can choose to enforce L7 processing with ambient mesh in this section.

## Benefits of using the waypoint proxy and L7 networking features

In summary, the waypoint proxy approach for the L7 processing layer offers the following three main advantages:

- Security - Rich L7 authorization policy
- Observability - HTTP metrics, access logs, and tracing
- Traffic management - Dark launch, canary test

The waypoint proxy and L7 networking features provide a number of benefits, including:

- Improved performance and scalability: Waypoint proxies are designed to be lightweight and efficient, which can improve the performance and scalability of your microservices architecture.
- Increased flexibility: The waypoint proxy allows you to implement a wide range of L7 networking features, such as HTTP load balancing, fault injection, and observability.
- Simplified operations: By deploying a waypoint proxy, you can simplify the operation of your microservices architecture by reducing the number of components that need to be managed.

## When to use the waypoint proxy and L7 networking features

You should consider using the waypoint proxy and L7 networking features if your microservices architecture requires any of the following:

- L7 load balancing and routing: You need to distribute traffic across multiple instances of a workload based on factors such as request path, header values, or cookies.
Waypoint provides a variety of L7 load balancing and routing algorithms, including round robin, weighted round robin, and least connections. It also supports path-based routing and other advanced routing rules.
- L7 fault injection: You need to simulate faults in your microservices architecture such as delays, errors, and circuit breaks to test its resilience and prepare for real-world failures.
- Rate limiting: You need to protect workloads against denial-of-service attacks and improve performance.
- L7 observability: You need to collect metrics and traces from your microservices architecture to monitor its performance and troubleshoot problems.

### Getting started with the waypoint proxy and L7 networking features

To get started with the waypoint proxy and L7 networking features, you will need to deploy a waypoint proxy for each workload that requires L7 networking. You can do this using the Kubernetes Gateway resource. Once the waypoint proxy is deployed, you can configure L7 policies using the VirtualService, DestinationRule, and ServiceEntry resources.

This guide will provide more detailed instructions on how to deploy and configure the waypoint proxy and L7 networking features.

# Current Challenges: #current-challenges

<<Need to work more>>

Waypoint only supports Ambient workloads. It does not support sidecar proxy workloads. In addition to this general caveats, there are also some specific caveats to be aware of when using Waypoint with certain protocols:

- HTTP: Waypoint does not support all HTTP features, such as HTTP/2 and chunked encoding.
- gRPC: Waypoint does not support all gRPC features, such as HTTP/2 transport and protocol multiplexing.
- WebSocket: Waypoint does not support WebSocket.

Despite these caveats, Waypoint is a powerful tool for enabling L7 networking and services for Istio Ambient workloads. It is a good choice for users who are looking for a way to run microservices-based applications in Ambient mode.

Here is a table summarizing the caveats of Waypoint:

| Caveat | Description |
| ------------- | ------------- |
| Maturity | Waypoint is still under development |
| Features | Waypoint only supports L7 load balancing and routing |
|Integration | Waypoint is not yet fully integrated with the Istio control plane | Support | Waypoint only supports Ambient workloads | HTTP | Waypoint does not support all HTTP features | 
gRPC | Waypoint does not support all gRPC features | Websocket | Waypoint does not support WebSocket |

In addition to these caveats, it is also important to note that Waypoint is a new feature, and it is not yet as mature as Istio's sidecar proxy. As a result, users may experience some performance or stability issues when using Waypoint. However, the Ambient mesh team is actively working to address these issues, and they are committed to making Waypoint a production-ready feature.

Overall, Waypoint is a powerful tool for enabling L7 networking and services for Istio Ambient workloads. However, users should be aware of the caveats and limitations listed above before deploying Waypoint in production.

## Environment used for this guide

For the examples in this guide, we used a deployment of Istio version `1.19.0` on a `kinD` cluster of version `0.20.0` running Kubernetes version `1.27.3`. However these should also work on any Kubernetes cluster at version `1.24.0` or later and Istio version `1.18.0` or later. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. Refer to the [Installation user](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/usage/install/) guide or [Getting started guide](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/getting-started/) on installing Istio in ambient mode on a Kubernetes cluster.

# Deciding the scope of your Waypoint proxy

Waypoint proxies can be deployed at the namespace or service account level. The scope you choose depends on your specific needs and requirements.

## Namespace-level scope

Deploying Waypoint proxies at the namespace level provides a number of benefits, including:
- Simplified policy management: Policies are enforced at the namespace level, so you only need to define them once for all workloads in the namespace.
- Improved performance: Waypoint proxies can cache routing and policy information, which can improve performance for workloads in the namespace.
- Increased security: Waypoint proxies can enforce authorization policies at the namespace level, which can help to protect your workloads from unauthorized access.

However, deploying Waypoint proxies at the namespace level also has some drawbacks, including:
- Limited granularity: You cannot apply different policies to different workloads in the same namespace.
- Increased resource consumption: Each namespace will require its own Waypoint proxy, which can consume more resources.

## Service account-level scope

Deploying Waypoint proxies at the service account level provides a number of benefits, including:
- Increased granularity: You can apply different policies to different workloads based on their service account.
- Reduced resource consumption: You only need to deploy a Waypoint proxy for each service account that has workloads that require L7 routing or policy enforcement.

However, deploying Waypoint proxies at the service account level also has some drawbacks, including:

- Increased complexity: Managing policies at the service account level can be more complex, especially if you have a large number of service accounts.
- Reduced caching: Waypoint proxies cannot cache routing and policy information at the service account level, which can reduce performance.

## How to choose the right scope for your Waypoint proxies

The best scope for your Waypoint proxies will depend on your specific needs and requirements. If you have a simple application with a small number of workloads, then namespace-level scope may be a good choice. However, if you have a more complex application with a large number of workloads or if you need to apply different policies to different workloads, then service account-level scope may be a better choice.

Here are some factors to consider when choosing the scope for your Waypoint proxies:
- The number of workloads in your application
- The complexity of your application
- The need to apply different policies to different workloads
- The performance requirements of your application
- The resource requirements of your application

# Functional Overview

The functional behaviour of the waypoint proxy is dynamically configured by Istio to serve your applications configurations. This section takes a brief look at these functional aspects - detailed description of the internal design of the waypoint proxy is out of scope for this guide. The detailed functional overview from the Secure Overlay Networking was already discussed in the [Ztunnel L4 Networking Guide](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/usage/ztunnel/#functionaloverview) hence this section only focuses on functionalities and features that Waypoint Proxy provides.

<<image>>

What is unique about the waypoint proxy is that it runs either per-namespace (default) or per-service account. By running outside of the application pod, a waypoint proxy can install, upgrade, and scale independently from the application pod, providing a centralized approach to managing L7 traffic and enforcing policies as well as reduce operational costs.

Upon deployment of a gateway resource using the `kubectl apply` command, Istio's control plane, IstioD, assumes the role of the Waypoint controller. Recognizing the gateway resource with the "istio.io/waypoint" gateway class name, istiod automatically deploys the Waypoint proxy based on the specified configuration in the gateway resource.

The waypoint proxy's data plane operates at Layer 7, enabling it to fully parse connections into individual requests and apply policies based on request properties such as headers and credentials. This granular control over L7 traffic extends to a comprehensive suite of capabilities, including:
- HTTP 1.x, 2, or 3
- Request routing
- Advanced load balancing
- Request mirroring
- Fault injection
- Request retries
- gRPC-specific capabilities

Waypoint proxies are deployed either per-namespace or per-service account, providing granular control over L7 traffic management. This deployment model allows for independent scaling of waypoint proxies based on the request load for individual workloads. Unlike the traditional sidecar deployment approach, waypoint proxies can be scaled independently to better fit the incoming traffic for a service and match the actual workload usage, optimizing resource utilization and improving performance. You can think of these waypoint proxies as individual gateways per workload type as shown here - 

<<image>>

The deployment of waypoint proxies can be handled by namespace owners, platform operators, or automated systems. Once a waypoint proxy is deployed, and a corresponding L7 policy is configured for a destination represented by the waypoint proxy, the secure overlay layer ensures that connection is routed to the correct L7 waypoint proxy for processing and policy enforcement as shown here - 

<<image>>

Tenancy for Layer 7 capabilities in the Istio ambient mesh is similar to the sidecar deployment model. L7 capabilities are not shared across multiple identities within a single L7 proxy. Each application has its own dedicated waypoint proxy, ensuring isolation of configuration and extensions (plug-ins, extensions, etc.) specific to individual workloads. This isolation prevents interference between workloads and facilitates independent management of L7 configurations.

Functionally, the Waypoint proxy resembles the sidecar proxy but operates independently of application pods. It has its own CA client and XDS client, enabling secure communication with istioD. To obtain its identity certificate, the Waypoint proxy establishes a secure connection with istioD, requesting certification. Upon validating the presented token, istioD signs the Waypoint proxy's certificate, granting it access to the Istio control plane.

Subsequently, the Waypoint proxy initiates communication with istioD, requesting XDS configuration to govern its operation. This configuration defines the L7 routing rules, policy enforcement mechanisms, and other parameters essential for managing L7 traffic.

In essence, the Waypoint proxy serves as an L7 traffic management hub, decoupled from application pods and centrally managed by istioD. This architecture simplifies L7 configuration and policy enforcement, enabling efficient and scalable L7 services within Istio Ambient deployments as shown in the figure - 

<<image>>

## Destination Only Waypoint

In contrast to traditional sidecar proxies, which reside alongside application pods, Waypoint proxies operate solely on the server-side, acting as reverse proxies for L7 traffic. This approach streamlines L7 traffic management by centralising policy enforcement to the destination workload's namespace or service account.

When a request originates from an application pod, it bypasses the client-side Waypoint proxy and directly reaches the server-side Waypoint proxy associated with the destination workload's namespace or service account. Istio enforces that all traffic coming into the namespace goes through the waypoint, which then enforces all policies for that namespace. Because of this, each waypoint only needs to know about configuration for its own namespace. Thus Waypoint proxy assumes responsibility for enforcing all L7 policies and routing rules applicable to the destination workload.

<<image>>

Destination-only Waypoint simplifies the configuration process by eliminating the need for sidecar proxies and "exportTo" configurations. Waypoint proxies only need to be aware of the endpoints, pods, and workloads within their respective namespaces or service accounts. This streamlined approach reduces the complexity of L7 management and enables a more efficient use of resources.

<<image>>

- **Policy Enforcement**: In traditional Istio deployments, both source-side and destination-side policies were employed, which often led to confusion for users regarding policy enforcement and troubleshooting. Destination-only Waypoint simplifies this process by enforcing all policies exclusively at the destination workload's namespace or service account. This centralized approach eliminates the need to track policies across multiple locations, making it easier to understand, manage, and troubleshoot L7 security configurations.

<<image>>

- **Mixed Environment**: In a mixed environment where clients may reside inside or outside the Istio mesh, destination-only Waypoint ensures consistent policy enforcement regardless of the client's location. Since all policies are applied at the destination workload, users can be confident that security measures are consistently applied to all incoming traffic.

<<image>>

## Handling Destinations without Waypoint Proxies

While destination-only Waypoint offers centralized policy enforcement and simplified configuration, there may be instances where the destination workload doesn't have a waypoint proxy deployed. This could arise when connecting to external services beyond the control of the Istio mesh.

To address this scenario, the Istio community is actively developing mechanisms to route traffic to the egress gateway and enable policy enforcement for destinations without waypoint proxies. This functionality will allow users to configure resilience-enhancing policies, such as timeouts, for external services.

Please stay tuned for future blog posts and documentation updates that will provide detailed information on this evolving feature.

# Deploying an Application

When someone with Istio admin privileges sets up Istio mesh, it becomes available for all users in specific namespaces. The examples below shows how Istio can be used transparently once it's successfully deployed in ambient mode and the namespaces are annotated accordingly.

## Basic application deployment without Ambient

In this guide, we'll work with the sample [bookinfo application](https://istio.io/latest/docs/examples/bookinfo/) that comes with Istio. If you've downloaded Istio, you already have it. In ambient mode, deploying apps to your Kubernetes cluster is just like doing it without Istio. You can have your apps running in the cluster before turning on ambient mesh. They can seamlessly join the mesh without any need for restarting or reconfiguring.

{{< warning >}} 
Make sure the default namespace does not include the label `istio-injection=enabled` because when using ambient you do not want Istio to inject sidecars into the application pods.
 {{</ warning >}}

1. Deploy Sample Services

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl apply -f samples/sleep/notsleep.yaml
{{< /text >}}

2. Deploy an Ingress Gateway and a Virtual Service - 
This allows you to access the bookinfo app from outside the cluster

{{< tip >}}
To get IP address assignment for `Loadbalancer` service types in `kinD`, you may need to install a tool like [MetalLB](https://metallb.universe.tf/). Please consult [this guide](https://kind.sigs.k8s.io/docs/user/loadbalancer/) for more information.
{{< /tip >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Create an Istio [Gateway](/docs/reference/config/networking/gateway/) and
[VirtualService](/docs/reference/config/networking/virtual-service/):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
{{< /text >}}

Set the environment variables for the Istio ingress gateway:

{{< text bash >}}
$ export GATEWAY_HOST=istio-ingressgateway.istio-system
$ export GATEWAY_SERVICE_ACCOUNT=ns/istio-system/sa/istio-ingressgateway-service-account
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway)
and [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute):

{{< text bash >}}
$ sed -e 's/from: Same/from: All/'\
      -e '/^  name: bookinfo-gateway/a\
  namespace: istio-system\
'     -e '/^  - name: bookinfo-gateway/a\
    namespace: istio-system\
' @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@ | kubectl apply -f -
{{< /text >}}

Set the environment variables for the Kubernetes gateway:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw/bookinfo-gateway -n istio-system
$ export GATEWAY_HOST=bookinfo-gateway-istio.istio-system
$ export GATEWAY_SERVICE_ACCOUNT=ns/istio-system/sa/bookinfo-gateway-istio
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}


3. Test your bookinfo application, it should work with or without the gateway:

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

## Enabling Ambient Mesh

<!-- Lets first deploy a sample application composed of four separate microservices used to demonstrate various L7 feature without making it part of the Istio ambient mesh. We can pick from the apps in the samples folder of the istio repository. Execute the following examples from the top of a local Istio repository or istio folder created by downloading the istioctl client as described in istio guides.

{{< text bash >}}
$ code for bookinfo
{{< /text >}}

### Deploying a Waypoint Proxy

Let's see how you can Deploy a sample application bookinfo to use Waypoint proxy

**How to deploy a Waypoint proxy using istioctl**
TODO

**How to deploy a Waypoint proxy using Helm**
TODO

### Verify Waypoint proxy is deployed

{{< text bash >}}
$ code for verification
{{< /text >}}

This indicates Waypoint proxy is working.  In the next section we look at how to monitor the confuguration and data plane of Waypoint proxy to confirm that traffic is correctly using Waypoint proxy. 

### Install Waypoint Proxy

**Install Gateway CRDs**

In L7 networking, a waypoint proxy is a lightweight Envoy proxy that can be configured for your entire namespace or for a service account. It is used to implement L7 functionality in Istio Ambient Mesh.

The reference implementation of a waypoint proxy is managed by the Kubernetes Gateway API `istio-waypoint` GatewayClass.

1. Install Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

    {{< tip >}}
    {{< boilerplate gateway-api-future >}}
    {{< boilerplate gateway-api-choose >}}
    {{< /tip >}}

2. Verify the installed components using the following commands:

    {{< text bash >}}
    $ code
    {{< /text >}}

### Verify that Waypoint proxy is routing traffic to the application

## Configuring Waypoint proxy - 

This section describes how to configure Waypoint proxy for the Bookinfo application. The Bookinfo application is a sample application that requires a virtual service to route traffic to its different services.

The core functionality of the waypoint L7 traffic management is identical to sidecar mode, hence to add more features refer to this link: https://istio.io/latest/docs/reference/config/networking/virtual-service/

FOR EACH SECTION:

### Creating a Virtual Service

To create a virtual service for the Bookinfo application, you can use the following YAML manifest:

{{< text bash >}}
$ yaml file
{{< /text >}}

This virtual service will route all traffic to the `bookinfo-v1` service.

### Deploying the Virtual Service

To deploy the virtual service, you can use the following command:

{{< text bash >}}
$ command
{{< /text >}}

### L7 Load Balancing

<<TODO>>

### Configuring AB Deployment and Canary Deployment

<<TODO>>

To send traffic to an AB deployment for the sidecar model using a waypoint proxy, you can follow these steps:

TODO

Once you have completed these steps, traffic will be routed to the two versions of your application according to the traffic splitting configuration.

Here is a concrete example of how to send traffic to an AB deployment for the sidecar model using a waypoint proxy for the Bookinfo application:

{{< text bash >}}
$ YAML file
{{< /text >}}

Once you have deployed these resources, traffic will be routed to the `bookinfo-v1` and `bookinfo-v2` versions of the Bookinfo application according to the traffic splitting configuration. You can adjust the weight of each route to control how much traffic is routed to each version of the application.

By using waypoint proxies and traffic splitting, you can implement AB deployments for sidecar models in Istio. This allows you to gradually roll out new versions of your application to users and to monitor the performance of the new version before rolling it out to all users.

You can use Istio's AB Deployment and Canary Deployment features to deploy and manage multiple versions of your application at the same time. To do this, you would create a virtual service for each version of your application. Then, you would use Istio's traffic splitting features to route traffic to the different versions of your application.

For more information on AB Deployment and Canary Deployment, please see the Istio documentation.

### Traffic splitting with Canary development
TODO

**Conclusion**

This section has described how to configure Waypoint proxy for the Bookinfo application. For more information on waypoint proxies, please see the Istio documentation.

### Verifying Waypoint proxy Configuration is working

Once the virtual service is deployed, you can verify Waypoint proxy configuration by running the following command:

{{< text bash >}}
$ command
{{< /text >}}

This will output the configuration of Waypoint proxy, including the virtual service that is mapped to it.

### Configuring Virtual Services

You can configure both L4 and L7 virtual services for waypoint proxies. If you want to do a Virtual Service with TCP that is effectively a L4 virtual services. This is used to route traffic to services based on port number. L7 virtual services are used to route traffic to services based on more complex criteria, such as HTTP method and path. In a Virtual service you can have only TCP, or only HTTP or Both.

<<Considered merging L4 (TCP) and L7 (HTTP) virtual service>>

### Example

The following YAML manifest shows an example of an L7 virtual service:

{{< text bash >}}
$ yaml file
{{< /text >}}

This virtual service will route traffic to the `bookinfo-v1` service for requests to the `/productpage` path and traffic to the `bookinfo-v2` service for requests to the `/reviews` path.

### Verifying Virtual Service

Once the virtual service is set up, the HTTP route is mapped to the waypoint configuration. This means that all traffic that matches the virtual service's hosts and HTTP routes will be routed to the waypoint proxy.

In classic mode you can use `istioctl proxy-config cmds` to dump the envoy configuration. While `istioctl proxy-config cmds` will still work in ambient there are some differences because the envoy proxy is no longer configured for every sidecar.

For example, the following command would dump the configuration for the waypoint proxy named `bookinfo-waypoint`:

{{< text bash >}}
$ command
{{< /text >}}

The output of this command would include a list of the virtual services that are mapped to the waypoint proxy. For example:

{{< text bash >}}
$ virtual_services:
  - name: bookinfo
    routes:
    - match:
        uri:
          prefix: /productpage
    - match:
        uri:
          prefix: /reviews
{{< /text >}}

This output shows that the `bookinfo` virtual service is mapped to the `bookinfo-waypoint` waypoint proxy. All traffic that matches the `bookinfo` virtual service's hosts and HTTP routes will be routed to the `bookinfo-waypoint` waypoint proxy.

By understanding how virtual services are mapped to waypoint proxies, you can configure your Istio mesh to route traffic in the way that you need.


## Monitoring the Waypoint Proxy & L7 Networking

This section describes how to monitor Waypoint proxy for the Bookinfo application.

### Viewing Waypoint proxy Status

You can use the following command to view Waypoint proxy status:

{{< text bash >}}
$ command
{{< /text >}}

This will output the status of the waypoint proxy, including its readiness and liveness probes.

### Viewing Waypoint proxy Configuration

You can use the following command to monitor the waypoint proxy configuration:

{{< text bash >}}
$ command
{{< /text >}}

This will output the configuration of Waypoint proxy, including the virtual services that are mapped to it.

### Monitoring the Virtual Service Mapping

You can use the following command to monitor the virtual service mapping to Waypoint proxy:

{{< text bash >}}
$ command
{{< /text >}}

This will output the virtual services that are mapped to Waypoint proxy.

### Checking Waypoint proxy Traffic

You can use the following command to monitor the waypoint proxy traffic:

{{< text bash >}}
$ command
{{< /text >}}

This will output the pods in your cluster. You can then use the `istioctl __` command to get the traffic statistics for each pod.

### Verifying L7 proxy load balancing

### Monitoring the AB Deployment and Canary Deployment

You can use the following command to monitor the AB Deployment and Canary Deployment traffic:

{{< text bash >}}
$ command
{{< /text >}}

This will output the traffic split configuration for the virtual service.

### Conclusion

This section has described how to monitor the Waypoint proxy for the Bookinfo application. For more information on waypoint proxies, please see the Istio documentation.

### Additional Details on Monitoring the Virtual Service Mapping

You can also use the following methods to monitor the virtual service mapping to the waypoint proxy:

* **Use the Istio telemetry dashboards:** The Istio telemetry dashboards provide a graphical view of the traffic flowing through your Istio mesh. You can use these dashboards to monitor the traffic flowing to your waypoint proxies and to identify any problems with the virtual service mapping.
* **Use Prometheus and Grafana:** You can use Prometheus and Grafana to collect and visualize metrics from your Istio mesh. You can use these tools to monitor the metrics associated with the waypoint proxy configuration and the virtual service mapping.

**Monitoring the Waypoint Configuration for How Those Virtual Services Get Mapped to the Waypoint**

You can use the following methods to monitor the waypoint configuration for how virtual services get mapped to the waypoint:

* **Use the Istio telemetry dashboards:** The Istio telemetry dashboards provide a graphical view of the traffic flowing through your Istio mesh. You can use these dashboards to monitor the traffic flowing to your waypoint proxies and to identify any problems with the virtual service mapping.
* **Use the Istio `istioctl` command:** You can use the Istio `istioctl` command to view the waypoint configuration. This configuration includes the virtual services that are mapped to the waypoint.
* **Use Prometheus and Grafana:** You can use Prometheus and Grafana to collect and visualize metrics from your Istio mesh. You can use these tools to monitor the metrics associated with the waypoint proxy configuration and the virtual service mapping.

By monitoring the waypoint proxy and the virtual service mapping, you can ensure that your Istio mesh is operating as expected.


## L7 Fault Injection: #l7faultinjection

## L7 Observability: #l7observability

## L7 Authorization Policy
<<TODO>>

## How to use Waypoint proxy for hairpinning
<<TODO>>

## Co-existence of Ambient/ L7 with Side car proxies

## Control Traffic towards Waypoint Proxy

Deploy a waypoint proxy for the review service, using the `bookinfo-review` service account, so that any traffic going to the review service will be mediated by Waypoint proxy.

{{< text bash >}}
$ istioctl x waypoint apply --service-account bookinfo-reviews
waypoint default/bookinfo-reviews applied
{{< /text >}}

Configure traffic routing to send 90% of requests to `reviews` v1 and 10% to `reviews` v2:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-reviews.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-90-10.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Confirm that roughly 10% of the traffic from 100 requests goes to reviews-v2:

{{< text bash >}}
$ kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://$GATEWAY_HOST/productpage | grep reviews-v.-; done"
{{< /text >}}

## Remove Waypoint proxy layer

To remove the `productpage-viewer` authorization policy, waypoint proxies and uninstall Istio:

{{< text bash >}}
$ kubectl delete authorizationpolicy productpage-viewer
$ istioctl x waypoint delete --service-account bookinfo-reviews
$ istioctl x waypoint delete --service-account bookinfo-productpage
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

The label to instruct Istio to automatically include applications in the `default` namespace to ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

To delete the Bookinfo sample application and its configuration, see [`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).

To remove the `sleep` and `notsleep` applications:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/sleep/notsleep.yaml@
{{< /text >}}

If you installed the Gateway API CRDs for Waypoint proxy, remove them:

{{< text bash >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
{{< /text >}} -->
