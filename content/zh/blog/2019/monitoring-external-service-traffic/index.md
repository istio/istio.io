---
title: "Monitoring blocked and passthrough external service traffic"
description: "How can you use Istio to monitor blocked and passthrough external traffic."
publishdate: 2019-09-28
attribution: Neeraj Poddar (Aspen Mesh)
keywords: [monitoring,blackhole,passthrough]
target_release: 1.3
---

Understanding, controlling and securing your external service access is one
of the key benefits that you get from a service mesh like Istio. From a security
and operations point of view, it is critical to monitor what external service traffic
is getting blocked as they might surface possible misconfigurations or a
security vulnerability if an application is attempting to communicate with a
service that it should not be allowed to. Similarly, if you currently have a
policy of allowing any external service access, it is beneficial to monitor
the traffic so you can incrementally add explicit Istio configuration to allow
access and better secure your cluster. In either case, having visibility into this
traffic via telemetry is quite helpful as it enables you to create alerts and
dashboards, and better reason about your security posture. This was a highly
requested feature by production users of Istio and we are excited that the
support for this was added in release 1.3.

To implement this, the Istio [default
metrics](/zh/docs/reference/config/policy-and-telemetry/metrics) are augmented with
explicit labels to capture blocked and passthrough external service traffic.
This blog will cover how you can use these augmented metrics to monitor all
external service traffic.

The Istio control plane configures the sidecar proxy with
predefined clusters called BlackHoleCluster and Passthrough which block or
allow all traffic respectively. To understand these clusters, let's start with
what external and internal services mean in the context of Istio service mesh.

## External and internal services

Internal services are defined as services which are part of your platform
and are considered to be in the mesh. For internal services, Istio control
plane provides all the required configuration to the sidecars by default.
For example, in Kubernetes clusters, Istio configures the sidecars for all
Kubernetes services to preserve the default Kubernetes behavior of all
services being able to communicate with other.

External services are services which are not part of your platform i.e. services
which are outside of the mesh. For external services, Istio provides two
options, first to block all external service access (enabled  by setting
`global.outboundTrafficPolicy.mode` to `REGISTRY_ONLY`) and
second to allow all access to external service (enabled  by setting
`global.outboundTrafficPolicy.mode` to `ALLOW_ANY`). The default option for this
setting (as of Istio 1.3) is to allow all external service access. This
option can be configured via [mesh configuration](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode).

This is where the BlackHole and Passthrough clusters are used.

## What are BlackHole and Passthrough clusters?

* **BlackHoleCluster** - The BlackHoleCluster is a virtual cluster created
  in the Envoy configuration when `global.outboundTrafficPolicy.mode` is set to
  `REGISTRY_ONLY`. In this mode, all traffic to external service is blocked unless
  [service entries](/zh/docs/reference/config/networking/service-entry)
  are explicitly added for each service. To implement this, the default virtual
  outbound listener at `0.0.0.0:15001` which uses
  [original destination](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#original-destination)
  is setup as a TCP Proxy with the BlackHoleCluster as the static cluster.
  The configuration for the BlackHoleCluster looks like this:

  {{< text json >}}
    {
      "name": "BlackHoleCluster",
      "type": "STATIC",
      "connectTimeout": "10s"
    }
  {{< /text >}}

  As you can see, this cluster is static with no endpoints so all the traffic
  will be dropped. Additionally, Istio creates unique listeners for every
  port/protocol combination of platform services which gets hit instead of the
  virtual listener if the request is made to an external service on the same port.
  In that case, the route configuration of every virtual route in Envoy is augmented to
  add the BlackHoleCluster like this:

  {{< text json >}}
    {
      "name": "block_all",
      "domains": [
        "*"
      ],
      "routes": [
        {
          "match": {
            "prefix": "/"
          },
          "directResponse": {
            "status": 502
          }
        }
      ]
    }
  {{< /text >}}

  The route is setup as [direct response](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto#envoy-api-msg-route-directresponseaction)
  with `502` response code which means if no other routes match the Envoy proxy
  will directly return a `502` HTTP status code.

* **PassthroughCluster** - The PassthroughCluster is a virtual cluster created
  in the Envoy configuration when `global.outboundTrafficPolicy.mode` is set to
  `ALLOW_ANY`. In this mode, all traffic to any external service external is allowed.
  To implement this, the default virtual outbound listener at `0.0.0.0:15001`
  which uses `SO_ORIGINAL_DST`, is setup as a TCP Proxy with the PassthroughCluster
  as the static cluster.
  The configuration for the PassthroughCluster looks like this:

  {{< text json >}}
    {
      "name": "PassthroughCluster",
      "type": "ORIGINAL_DST",
      "connectTimeout": "10s",
      "lbPolicy": "ORIGINAL_DST_LB",
      "circuitBreakers": {
        "thresholds": [
          {
            "maxConnections": 102400,
            "maxRetries": 1024
          }
        ]
      }
    }
  {{< /text >}}

  This cluster uses the [original destination load balancing](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#original-destination)
  policy which configures Envoy to send the traffic to the
  original destination i.e. passthrough.

  Similar to the BlackHoleCluster, for every port/protocol based listener the
  virtual route configuration is augmented to add the PassthroughCluster as the
  default route:

  {{< text json >}}
    {
      "name": "allow_any",
      "domains": [
        "*"
      ],
      "routes": [
        {
          "match": {
            "prefix": "/"
          },
          "route": {
            "cluster": "PassthroughCluster"
          }
        }
      ]
    }
  {{< /text >}}

Prior to Istio 1.3, there were no metrics reported or if metrics were reported
there were no explicit labels set when traffic hit these clusters, resulting in
lack of visibility in traffic flowing through the mesh.

The next section covers how to take advantage of this enhancement as the metrics
and labels emitted are conditional on whether the virtual outbound or explicit port/protocol
listener is being hit.

## Using the augmented metrics

To capture all external service traffic in either of the cases (BlackHole or
Passthrough), you will need to monitor `istio_requests_total` and
`istio_tcp_connections_closed_total` metrics. Depending upon the Envoy listener
type i.e. TCP proxy or HTTP proxy that gets invoked, one of these metrics
will be incremented.

Additionally, in case of a TCP proxy listener in order to see the IP address of
the external service that is blocked or allowed via BlackHole or Passthrough
cluster, you will need to add the `destination_ip` label to the
`istio_tcp_connections_closed_total` metric. In this scenario, the host name of
the external service is not captured. This label is not added by default and can
be easily added by augmenting the Istio configuration for attribute generation
and Prometheus handler. You should be careful about cardinality explosion in
time series if you have many services with non-stable IP addresses.

### PassthroughCluster metrics

This section explains the metrics and the labels emitted based on the listener
type invoked in Envoy.

* HTTP proxy listener: This happens when the port of the external service is
  same as one of the service ports defined in the cluster. In this scenario,
  when the PassthroughCluster is hit, `istio_requests_total` will get increased
  like this:

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_requests_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_principal": "unknown",
        "destination_service": "httpbin.org",
        "destination_service_name": "PassthroughCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "permissive_response_code": "none",
        "permissive_response_policyid": "none",
        "reporter": "source",
        "request_protocol": "http",
        "response_code": "200",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567033080.282,
        "1"
      ]
    }
  {{< /text >}}

  Note that the `destination_service_name` label is set to PassthroughCluster to
  indicate that this cluster was hit and the `destination_service` is set to the
  host of the external service.

* TCP proxy virtual listener - If the external service port doesn't map to any
  HTTP based service ports within the cluster, this listener is invoked and
  `istio_tcp_connections_closed_total` is the metric that will be increased:

  {{< text json >}}
    {
      "status": "success",
      "data": {
        "resultType": "vector",
        "result": [
          {
            "metric": {
              "__name__": "istio_tcp_connections_closed_total",
              "connection_security_policy": "unknown",
              "destination_app": "unknown",
              "destination_ip": "52.22.188.80",
              "destination_principal": "unknown",
              "destination_service": "unknown",
              "destination_service_name": "PassthroughCluster",
              "destination_service_namespace": "unknown",
              "destination_version": "unknown",
              "destination_workload": "unknown",
              "destination_workload_namespace": "unknown",
              "instance": "100.96.2.183:42422",
              "job": "istio-mesh",
              "reporter": "source",
              "response_flags": "-",
              "source_app": "sleep",
              "source_principal": "unknown",
              "source_version": "unknown",
              "source_workload": "sleep",
              "source_workload_namespace": "default"
            },
            "value": [
              1567033761.879,
              "1"
            ]
          }
        ]
      }
    }
  {{< /text >}}

  In this case, `destination_service_name` is set to PassthroughCluster and
  the `destination_ip` is set to the IP address of the external service.
  The `destination_ip` label can be used to do a reverse DNS lookup and
  get the host name of the external service. As this cluster is passthrough,
  other TCP related metrics like `istio_tcp_connections_opened_total`,
  `istio_tcp_received_bytes_total` and `istio_tcp_sent_bytes_total` are also
  updated.

### BlackHoleCluster metrics

Similar to the PassthroughCluster, this section explains the metrics and the
labels emitted based on the listener type invoked in Envoy.

* HTTP proxy listener: This happens when the port of the external service is same
  as one of the service ports defined in the cluster.
  In this scenario, when the BlackHoleCluster is hit,
  `istio_requests_total` will get increased like this:

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_requests_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_principal": "unknown",
        "destination_service": "httpbin.org",
        "destination_service_name": "BlackHoleCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "permissive_response_code": "none",
        "permissive_response_policyid": "none",
        "reporter": "source",
        "request_protocol": "http",
        "response_code": "502",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567034251.717,
        "1"
      ]
    }
  {{< /text >}}

  Note the `destination_service_name` label is set to BlackHoleCluster and the
  `destination_service` to the host name of the external service. The response
  code should always be `502` in this case.

* TCP proxy virtual listener - If the external service port doesn't map to any
  HTTP based service ports within the cluster, this listener is invoked and
  `istio_tcp_connections_closed_total` is the metric that will be increased:

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_tcp_connections_closed_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_ip": "52.22.188.80",
        "destination_principal": "unknown",
        "destination_service": "unknown",
        "destination_service_name": "BlackHoleCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "reporter": "source",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567034481.03,
        "1"
      ]
    }
  {{< /text >}}

  Note the `destination_ip` label represents the IP address of the external
  service and the `destination_service_name` is set to BlackHoleCluster
  to indicate that this traffic was blocked by the mesh. Is is interesting to
  note that for the BlackHole cluster case, other TCP related metrics like
  `istio_tcp_connections_opened_total` are not increased as there's no
  connection that is ever established.

Monitoring these metrics can help operators easily understand all the external
services consumed by the applications in their cluster.
