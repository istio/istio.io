---
title: Waypoint proxy Layer
description: User guide for L7 Processing.
weight: 2
owner: istio/wg-networking-maintainers
test: n/a
---

<!-- {{<tip>}}
Before you start with this guide, please make sure that you have already read the Ztunnel Networking sub-guide and have a basic understanding of Istio Ambient Mesh. This guide assumes that you have already completed the Installation, set up the ztunnel and enabled mTLS.

If you have not yet done these things, please go back to the Ztunnel Networking sub-guide and follow the instructions before proceeding with this guide.

Once you have completed the Ztunnel Networking sub-guide, you will be ready to start setting up Waypoint proxy layer in Istio Ambient Mesh.

{{</tip>}} -->


## Introduction 

This guide provides instructions on how to set up and use Waypoint proxy layer in Istio Ambient Mesh.

L7 traffic routing is handled via the Waypoint proxy. The waypoint proxy is currently based on Envoy. The waypoint proxy can be deployed to scale dynamically using HPAs.

**Overview of the Layer 7 Waypoint proxy**

TODO

**Benefits of using the Layer 7 Waypoint proxy**

TODO

## Pre-requisites & Supported Topologies

This guide assumes that you have already completed the [Ztunnel Networking sub-guide](../ztunnel/).

Before you begin, make sure that you have the following prerequisites in place:
1. Istio Ambient Mesh installed and configured
2. Ztunnel proxy is installed and running
3. Mutual TLS (mTLS) enabled and configured


<!-- ## Understanding the Waypoint Proxy Default Configuration

The Waypoint proxy get configured based on resources such as Kubernetes Gateway API CRDs and Istio/VirtualService etc.

In the future, there may be some additional limited configurability for Waypoint Proxies. However, for now, the following are all configured with fixed default configurations that are not customizable:

* Networking between pods and Waypoint Proxies
* Networking between Waypoint Proxies
* Networking between Waypoint Proxies and sidecar proxies -->

## Deciding if you need A Waypoint proxy
TODO

## Deciding the scope of your Waypoint proxy
TODO


#### Additional Notes

* The Waypoint Proxy layer can coexist with sidecar proxies in the same cluster. This allows you to use Waypoint proxy for services that require L7 functionality and sidecar proxies for services that do not.
* Waypoint proxy is implemented using Envoy. This means that you can use all of the features of Envoy in your Waypoint Proxies.
* Waypoint proxy is still under development, but it is already a powerful tool for managing L7 traffic in Istio Ambient Mesh.

For the examples in this guide, we used a deployment of Istio Ambient on a `kinD` cluster, although these should apply for any Kubernetes cluster version 1.18.0 or later. Refer to the Getting started guide on how to download the `istioctl` client and how to deploy a `kinD` cluster. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. 

## Functional Overview

A figure showing an architecture summary of Waypoint proxy.

TODO

## Install Waypoint Proxy

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

## Deploying an Application

Lets first deploy a sample application composed of four separate microservices used to demonstrate various L7 feature without making it part of the Istio ambient mesh. We can pick from the apps in the samples folder of the istio repository. Execute the following examples from the top of a local Istio repository or istio folder created by downloading the istioctl client as described in istio guides.

{{< text bash >}}
$ code for bookinfo
{{< /text >}}

## Deploying a Waypoint Proxy

Let's see how you can Deploy a sample application bookinfo to use Waypoint proxy

**How to deploy a Waypoint proxy using istioctl**
TODO

**How to deploy a Waypoint proxy using Helm**
TODO

## Verify Waypoint proxy is deployed

{{< text bash >}}
$ code for verification
{{< /text >}}

This indicates Waypoint proxy is working.  In the next section we look at how to monitor the confuguration and data plane of Waypoint proxy to confirm that traffic is correctly using Waypoint proxy. 

### Verify that Waypoint proxy is routing traffic to the application

## Configuring Waypoint proxy - 

### Overview

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

### Verifying Waypoint proxy Configuration is working

Once the virtual service is deployed, you can verify Waypoint proxy configuration by running the following command:

{{< text bash >}}
$ command
{{< /text >}}

This will output the configuration of Waypoint proxy, including the virtual service that is mapped to it.

### Configuring Virtual Services

You can configure both L4 and L7 virtual services for waypoint proxies. If you want to do a Virtual Service with TCP that is effectively a L4 virtual services. This is used to route traffic to services based on port number. L7 virtual services are used to route traffic to services based on more complex criteria, such as HTTP method and path. In a Virtual service you can have only TCP, or only HTTP or Both.

<< Considered merging L4 (TCP) and L7 (HTTP) virtual service >>

### Example

The following YAML manifest shows an example of an L7 virtual service:

{{< text bash >}}
$ yaml file
{{< /text >}}

This virtual service will route traffic to the `bookinfo-v1` service for requests to the `/productpage` path and traffic to the `bookinfo-v2` service for requests to the `/reviews` path.

### Verifying the Virtual Service

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


## Monitoring Waypoint proxy

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

## L7 Authorization Policy
TODO

## Monitoring and Telemetry with Waypoint Proxy
TODO

## How to use Waypoint proxy for hairpinning
TODO

% ## Co-existence of Ambient/ L7 with Side car proxies
% How to use the Waypoint proxy with sidecar proxies
% TODO

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

## Configuring AB Deployment and Canary Deployment

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


## Troubleshooting
TODO