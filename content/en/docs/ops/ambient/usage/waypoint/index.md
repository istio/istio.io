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

{{<tip>}}

<!-- Pre-requisites & Supported Topologies -->

Before you begin, make sure that you have already read the [Ztunnel Networking sub-guide](../ztunnel/). This guide assumes that you have the following prerequisites in place:
1. Istio Ambient Mesh installed and configured
2. Ztunnel proxy is installed and running
3. Mutual TLS (mTLS) enabled and configured

{{</tip>}}

<!-- to include in future: 
1. The waypoint proxy can be deployed to scale dynamically using HPAs.
2. L7 traffic routing is handled via the Waypoint proxy. The waypoint proxy is currently based on Envoy. The waypoint proxy can be deployed to scale dynamically using HPAs.
 -->

## Introduction

This guide provides instructions on how to set up and use the Waypoint proxy layer in Istio Ambient Mesh.

Istio Ambient Mesh is a new way to deploy and manage microservices. In Ambient Mesh, workloads are no longer required to run sidecar proxies to participate in the service mesh. Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.

Ztunnel proxy is used to handle L3 and L4 networking functions, such as mTLS authentication and L4 authorization. For workloads that require L7 networking features, such as HTTP load balancing and fault injection, a waypoint proxy can be deployed. The waypoint proxy is an optional component that is Envoy-based and is responsible for terminating workload HTTP traffic and parsing workload HTTP headers. They also enforce L7 policies and collect L7 metrics.

This guide describes the functionality and usage of the waypoint proxy and L7 networking functions using Istio Ambient Mesh. We use a sample user journey to describe these functions hence it would be useful to go through this guide in sequence. However we provide links to the sections below in case the reader would like to jump to the appropriate section.

* [Introduction](#introduction)
* [Deciding if you need A Waypoint proxy](#deciding-if-you-need-a-waypoint-proxy)
* [Current Challenges](#current-challenges)
* [Differences between Sidecar Mode and Ambient Mode for Waypoint Proxy](#differences)
* [Deciding the scope of your Waypoint proxy](#differences-between-sidecar-mode-and-ambient-mode-for-waypoint-proxy)
* [Functional Overview](#functional-overview)
* [Deploying an Application](#deploying-an-application)
* [Configuring Waypoint proxy](#configuring-waypoint-proxy)
* [Monitoring the Waypoint Proxy & L7 Networking](#monitoring-the-waypoint-proxy--l7-networking)
* [L7 Fault Injection](#l7-fault-injection)
* [L7 Observability](#l7-observability)
* [L7 Authorization Policy](#l7-authorization-policy)
* [Control Traffic towards Waypoint Proxy](##control-traffic-towards-waypoint-proxy)
* [Remove Waypoint proxy layer](#remove-waypoint-proxy-layer)

## Deciding if you need A Waypoint proxy

<<addition of a paragraph>>

### Benefits of using the waypoint proxy and L7 networking features

The waypoint proxy and L7 networking features provide a number of benefits, including:

1. Improved performance and scalability: Waypoint proxies are designed to be lightweight and efficient, which can improve the performance and scalability of your microservices architecture.
2. Increased flexibility: The waypoint proxy allows you to implement a wide range of L7 networking features, such as HTTP load balancing, fault injection, and observability.
3. Simplified operations: By deploying a waypoint proxy, you can simplify the operation of your microservices architecture by reducing the number of components that need to be managed.

### When to use the waypoint proxy and L7 networking features

You should consider using the waypoint proxy and L7 networking features if your microservices architecture requires any of the following:

1. L7 load balancing and routing: You need to distribute traffic across multiple instances of a workload based on factors such as request path, header values, or cookies.
2. Waypoint provides a variety of L7 load balancing and routing algorithms, including round robin, weighted round robin, and least connections. It also supports path-based routing and other advanced routing rules.
3. L7 fault injection: You need to simulate faults in your microservices architecture such as delays, errors, and circuit breaks to test its resilience and prepare for real-world failures.
4. Rate limiting: You need to protect workloads against denial-of-service attacks and improve performance.
5. L7 observability: You need to collect metrics and traces from your microservices architecture to monitor its performance and troubleshoot problems.

### Getting started with the waypoint proxy and L7 networking features

To get started with the waypoint proxy and L7 networking features, you will need to deploy a waypoint proxy for each workload that requires L7 networking. You can do this using the Kubernetes Gateway resource. Once the waypoint proxy is deployed, you can configure L7 policies using the VirtualService, DestinationRule, and ServiceEntry resources.

This guide will provide more detailed instructions on how to deploy and configure the waypoint proxy and L7 networking features.

## Current Challenges

<<TODO>>

### Environment used for this guide

For the examples in this guide, we used a deployment of Istio version `1.19.0`` on a `kinD` cluster of version `0.20.0 running Kubernetes version `1.27.3`. However these should also work on any Kubernetes cluster at version `1.24.0` or later and Istio version `1.18.0` or later. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. Refer to the installation user guide or Getting started guide information on installing Istio in ambient mode on a Kubernetes cluster.

## Differences between Sidecar Mode and Ambient Mode for Waypoint Proxy

## Deciding the scope of your Waypoint proxy

<!-- The  two-layer  architecture  also  enables  a  more  granular  transition
from no mesh or sidecar to the secure overlay layer (on a pod level,
namespace  level,  or  mesh  level)  to  the  L7  processing  layer  (on  a
service account level or namespace level). -->

<< per workload level or Namespace or service account >>

In ambient, all policies are enforced by the destination waypoint. In many ways, the waypoint acts as a gateway into the namespace (default scope) or service account. Istio enforces that all traffic coming into the namespace goes through the waypoint, which then enforces all policies for that namespace. Because of this, each waypoint only needs to know about configuration for its own namespace


#### Additional Notes

* The Waypoint Proxy layer can coexist with sidecar proxies in the same cluster. This allows you to use Waypoint proxy for services that require L7 functionality and sidecar proxies for services that do not.
* Waypoint proxy is implemented using Envoy. This means that you can use all of the features of Envoy in your Waypoint Proxies.
* Waypoint proxy is still under development, but it is already a powerful tool for managing L7 traffic in Istio Ambient Mesh.

For the examples in this guide, we used a deployment of Istio Ambient on a `kinD` cluster, although these should apply for any Kubernetes cluster version 1.18.0 or later. Refer to the Getting started guide on how to download the `istioctl` client and how to deploy a `kinD` cluster. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. 

## Functional Overview

<<A figure showing an architecture summary of Waypoint proxy.>>

<<TODO>>

## Deploying an Application

Lets first deploy a sample application composed of four separate microservices used to demonstrate various L7 feature without making it part of the Istio ambient mesh. We can pick from the apps in the samples folder of the istio repository. Execute the following examples from the top of a local Istio repository or istio folder created by downloading the istioctl client as described in istio guides.

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
{{< /text >}}