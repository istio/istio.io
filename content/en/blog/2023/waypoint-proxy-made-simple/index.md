---
title: "Istio Ambient Waypoint Proxy Made Simple"
description: Introducing the new destination oriented waypoint proxy for simplicity and scalability.
publishdate: 2023-03-31
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [istio,ambient,waypoint]
---

Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a
Layer 7 processing layer. The waypoint proxy is an optional component that is Envoy-based
and handles L7 processing for workloads it manages. Since the [initial ambient launch](/blog/2022/introducing-ambient-mesh/) in 2022,
we have made significant changes to simplify waypoint configuration, debuggability and scalability.

## Architecture of waypoint proxies

Similar to sidecar, the waypoint proxy is also Envoy-based and is dynamically configured by Istio
to serve your applications configuration. What is unique about the waypoint proxy is that it runs either
per-namespace (default) or per-service account. By running outside of the application pod, a waypoint proxy
can install, upgrade, and scale independently from the application, as well as reduce operational costs.

{{< image width="100%"
    link="waypoint-architecture.png"
    caption="Waypoint architecture"
    >}}

Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful `istioctl` command:

{{< text bash >}}
$ istioctl experimental waypoint generate
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: namespace
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Istiod will monitor these resources and deploy and manage the corresponding waypoint deployment for users automatically.

## Shift source proxy configuration to destination proxy

In the existing sidecar architecture, most traffic-shaping (for example [request routing](/docs/tasks/traffic-management/request-routing/) or [traffic shifting](/docs/tasks/traffic-management/traffic-shifting/) or [fault injection](/docs/tasks/traffic-management/fault-injection/)) policies are implemented by the source (client) proxy while most security policies are implemented by the destination (server) proxy. This leads to a number of concerns:

* Scaling - each source sidecar needs to know information about every other destination in the mesh. This is a polynomial scaling problem. Worse, if any destination configuration changes, we need to notify all sidecars at once.
* Debugging - because policy enforcement is split between the client and server sidecars, it can be hard to understand the behavior of the system when troubleshooting.
* Mixed environments - if we have systems where not all clients are part of the mesh, we get inconsistent behavior. For example, a non-mesh client wouldn't respect a canary rollout policy, leading to unexpected traffic distribution.
* Ownership and attribution - ideally a policy written in one namespace should only affect work done by proxies running in the same namespace. However, in this model, it is distributed and enforced by each sidecar. While Istio has designed around this constraint to make this secure, it is still not optimal.

In ambient, all policies are enforced by the destination waypoint. In many ways, the waypoint acts as a gateway into the namespace (default scope) or service account. Istio enforces that all traffic coming into the namespace goes through the waypoint, which then enforces all policies for that namespace. Because of this, each waypoint only needs to know about configuration for its own namespace.

The scalability problem, in particular, is a nuisance for users running in large clusters. If we visualize it, we can see just how big an improvement the new architecture is.

Consider a simple deployment, where we have 2 namespaces, each with 2 (color coded) deployments. The Envoy (XDS) configuration required to program the sidecars is shown as circles:

{{< image width="70%"
    link="sidecar-config.png"
    caption="Every sidecar has configuration about all other sidecars"
    >}}

In the sidecar model, we have 4 workloads, each with 4 sets of configuration. If any of those configurations changed, all of them would need to be updated. In total there are 16 configurations distributed.

In the waypoint architecture, however, the configuration is dramatically simplified:

{{< image width="70%"
    link="waypoint-config.png"
    caption="Each waypoint only has configuration for its own namespace"
    >}}

Here, we see a very different story. We have only 2 waypoint proxies, as each one is able to serve the entire namespace, and each one only needs configuration for its own namespace. In total we have 25% of the amount of configuration sent, even for a simple example.

If we scale each namespace up to 25 deployments with 10 pods each and each waypoint deployment with 2 pods for high availability, the numbers are even more impressive - the waypoint config distribution requires just 0.8% of the configuration distribution of the sidecar, as the table below illustrates!

| Config Distribution         |         Namespace 1              |       Namespace 2                |     Total     |
| --------------------------- | -------------------------------- | -------------------------------- | ------------- |
| Sidecars                    | 25 configurations * 250 sidecars | 25 configurations * 250 sidecars |    12500      |
| Waypoints                   | 25 configurations * 2 waypoints  | 25 configurations * 2 waypoints  |     100       |
| Waypoints / Sidecars        |              0.8%                |               0.8%               |      0.8%     |

While we use namespace scoped waypoint proxies to illustrate the simplification above, the simplification is similar
when you apply it to service account waypoint proxies.

This reduced configuration means lower resource usage (CPU, RAM, and network bandwidth) for both the
control plane and data plane. While users today can see similar improvements with careful usage of
`exportTo` in their Istio networking resources or of the [Sidecar](/docs/reference/config/networking/sidecar/) API,
in ambient mode this is no longer required, making scaling a breeze.

## What if my destination doesn’t have a waypoint proxy?

The design of ambient mode centers around the assumption that most configuration is best implemented by the service producer, rather than the service consumer. However, this isn't always the case - sometimes we need to configure traffic management for destinations we don't control. A common example of this would be connecting to an external service with improved resilience to handle occasional connection issues (e.g., to add a timeout for calls to `example.com`).

This is an area under active development in the community, where we design how traffic can be routed to your egress gateway and how you can configure the egress gateway with your desired policies. Look out for future blog posts in this area!

## A deep-dive of waypoint configuration

Assuming you have followed the [ambient get started guide](/docs/ops/ambient/getting-started/) up to and including the [control traffic section](/docs/ops/ambient/getting-started/#control), you have deployed a waypoint proxy for the bookinfo-reviews service account to direct 90% traffic to reviews v1 and 10% traffic to reviews v2.

Use `istioctl` to retrieve the listeners for the `reviews` waypoint proxy:

{{< text bash >}}
$ istioctl proxy-config listener deploy/bookinfo-reviews-istio-waypoint --waypoint
LISTENER              CHAIN                                                 MATCH                                         DESTINATION
envoy://connect_originate                                                       ALL                                           Cluster: connect_originate
envoy://main_internal inbound-vip|9080||reviews.default.svc.cluster.local-http  ip=10.96.104.108 -> port=9080                 Inline Route: /*
envoy://main_internal direct-tcp                                            ip=10.244.2.14 -> ANY                         Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.1.6 -> ANY                          Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.2.11 -> ANY                         Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='h2c'   Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='http/1.1'  Cluster: encap
envoy://connect_terminate default                                               ALL                                           Inline Route:
{{< /text >}}

For requests arriving on port `15008`, which by default is Istio’s inbound {{< gloss >}}HBONE{{< /gloss >}} port, the waypoint proxy terminates the HBONE connection and forwards the request to the `main_internal` listener to enforce any workload policies such as AuthorizationPolicy. If you are not familiar with [internal listeners](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/internal_listener), they are Envoy listeners that accepts user space connections without using the system network API. The `--waypoint` flag added to the `istioctl proxy-config` command, above, instructs it to show the details of the `main_internal` listener, its filter chains, chain matches, and destinations.

Note `10.96.104.108` is the reviews' service VIP and `10.244.x.x` are the reviews' v1/v2/v3 pod IPs, which you can view for your cluster using the `kubectl get svc,pod -o wide` command. For plain text or HBONE terminated inbound traffic, it will be matched on the service VIP and port 9080 for reviews or by pod IP address and application protocol (either `ANY`, `h2c`, or `http/1.1`).

Checking out the clusters for the `reviews` waypoint proxy, you get the `main_internal` cluster along with a few inbound clusters. Other than the clusters for infrastructure, the only Envoy clusters created are for services and pods running in the same service account. No clusters are created for services or pods running elsewhere.

{{< text bash >}}
$ istioctl proxy-config clusters deploy/bookinfo-reviews-istio-waypoint
SERVICE FQDN                         PORT SUBSET  DIRECTION   TYPE         DESTINATION RULE
agent                                -    -       -           STATIC
connect_originate                    -    -       -           ORIGINAL_DST
encap                                -    -       -           STATIC
kubernetes.default.svc.cluster.local 443  tcp     inbound-vip EDS
main_internal                        -    -       -           STATIC
prometheus_stats                     -    -       -           STATIC
reviews.default.svc.cluster.local    9080 http    inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v1 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v2 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v3 inbound-vip EDS
sds-grpc                             -    -       -           STATIC
xds-grpc                             -    -       -           STATIC
zipkin                               -    -       -           STRICT_DNS
{{< /text >}}

Note that there are no `outbound` clusters in the list, which you can confirm using `istioctl proxy-config cluster deploy/bookinfo-reviews-istio-waypoint --direction outbound`! What's nice is that you didn’t need to configure `exportTo` on any other bookinfo services (for example, the `productpage` or `ratings` services). In other words, the `reviews` waypoint is not made aware of any unnecessary clusters, without any extra manual configuration from you.

Display the list of routes for the `reviews` waypoint proxy:

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint
NAME                                                    DOMAINS MATCH              VIRTUAL SERVICE
encap                                                   *       /*
inbound-vip|9080|http|reviews.default.svc.cluster.local *       /*                 reviews.default
default
{{< /text >}}

Recall that you didn’t configure any Sidecar resources or `exportTo` configuration on your Istio networking resources. You did, however, deploy the `bookinfo-productpage` route to configure an ingress gateway to route to `productpage` but the `reviews` waypoint has not been made aware of any such irrelevant routes.

Displaying the detailed information for the `inbound-vip|9080|http|reviews.default.svc.cluster.local` route, you’ll see the weight-based routing configuration directing 90% of the traffic to `reviews` v1 and 10% of the traffic to `reviews` v2, along with some of Istio’s default retry and timeout configurations. This confirms the traffic and resiliency policies are shifted from the source to destination oriented waypoint as discussed earlier.

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint --name "inbound-vip|9080|http|reviews.default.svc.cluster.local" -o yaml
- name: inbound-vip|9080|http|reviews.default.svc.cluster.local
 validateClusters: false
 virtualHosts:
 - domains:
   - '*'
   name: inbound|http|9080
   routes:
   - decorator:
       operation: reviews:9080/*
     match:
       prefix: /
     metadata:
       filterMetadata:
         istio:
           config: /apis/networking.istio.io/v1alpha3/namespaces/default/virtual-service/reviews
     route:
       maxGrpcTimeout: 0s
       retryPolicy:
         hostSelectionRetryMaxAttempts: "5"
         numRetries: 2
         retriableStatusCodes:
         - 503
         retryHostPredicate:
         - name: envoy.retry_host_predicates.previous_hosts
           typedConfig:
             '@type': type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate
         retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
       timeout: 0s
       weightedClusters:
         clusters:
         - name: inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
           weight: 90
         - name: inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
           weight: 10
{{< /text >}}

Check out the endpoints for `reviews` waypoint proxy:

{{< text bash >}}
$ istioctl proxy-config endpoints deploy/bookinfo-reviews-istio-waypoint
ENDPOINT                                            STATUS  OUTLIER CHECK CLUSTER
127.0.0.1:15000                                     HEALTHY OK            prometheus_stats
127.0.0.1:15020                                     HEALTHY OK            agent
envoy://connect_originate/                          HEALTHY OK            encap
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http/v3|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://main_internal/                              HEALTHY OK            main_internal
unix://./etc/istio/proxy/XDS                        HEALTHY OK            xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket HEALTHY OK            sds-grpc
{{< /text >}}

Note that you don’t get any endpoints related to any services other than reviews, even though you have a few other services in the `default` and `istio-system` namespace.

## Wrapping up

We are very excited about the waypoint simplification focusing on destination oriented waypoint proxies. This is another significant step towards simplifying Istio’s usability, scalability and debuggability which are top priorities on Istio’s roadmap. Follow our [getting started guide](/docs/ops/ambient/getting-started/) to try the ambient alpha build today and experience the simplified waypoint proxy!
