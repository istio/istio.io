---
title: Sidecar or ambient?
description: Learn about Istio's two dataplane modes and which you should use.
weight: 30
keywords: [sidecar, ambient]
owner: istio/wg-docs-maintainers-english
test: n/a
---

An Istio service mesh is logically split into a data plane and a control plane.

The {{< gloss >}}data plane{{< /gloss >}} is the set of proxies that mediate and control all network communication between microservices. They also collect and report telemetry on all mesh traffic.

The {{< gloss >}}control plane{{< /gloss >}} manages and configures the proxies in the data plane.

Istio supports two main {{< gloss "data plane mode">}}data plane modes{{< /gloss >}}:

* **sidecar mode**, which deploys an Envoy proxy along with each pod that you start in your cluster, or running alongside services running on VMs.
* **ambient mode**, which uses a per-node Layer 4 proxy, and optionally a per-namespace Envoy proxy for Layer 7 features.

The two modes can interoperate with one another<sup>[α](#supported-features)</sup>, and you can opt certain namespaces or workloads into each mode.

## Sidecar mode

Istio has been built on the sidecar pattern from its first release in 2017. Sidecar mode is well understood and thoroughly battle-tested, but comes with a resource cost and operational overhead.

* Each application you deploy has an Envoy proxy {{< gloss "injection" >}}injected{{< /gloss >}} as a sidecar
* All proxies can process both Layer 4 and Layer 7

## Ambient mode

Launched in 2002, ambient mode was built to address the shortcomings reported by users of sidecar mode. As of Istio 1.22, it is production-ready for single cluster use cases.

* All traffic is proxied through a Layer 4-only node proxy
* Applications can opt in to routing through an Envoy proxy to get Layer 7 features

## Choosing between sidecar and ambient

Users often deploy a mesh to enable a zero-trust security posture as a first-step and then selectively enable L7 capabilities as needed. Ambient mesh allows those users to bypass the cost of L7 processing entirely when it’s not needed.

<table>
  <thead>
    <tr>
      <td style="border-width: 0px"></td>
      <th><strong>Sidecar</strong></th>
      <th><strong>Ambient</strong></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>Traffic management</th>
      <td>Full Istio feature set</td>
      <td>Full Istio feature set (requires using waypoint)</td>
    </tr>
    <tr>
      <th>Security</th>
      <td>Full Istio feature set</td>
      <td>Full Istio feature set: encryption and L4 authorization in ambient mode. Requires waypoints for L7 authorization.</td>
    </tr>
    <tr>
      <th>Observability</th>
      <td>Full Istio feature set</td>
      <td>Full Istio feature set: L4 telemetry in ambient mode; L7 observability when using waypoint</td>
    </tr>
    <tr>
      <th>Extensibility</th>
      <td>Full Istio feature set</td>
      <td>Full Istio feature set (requires using waypoint) <sup><a href="#supported-features">&alpha;</a></sup></td>
    </tr>
    <tr>
      <th>Adding workloads to the mesh</th>
      <td>Label a namespace and restart all pods to have sidecars added</td>
      <td>Label a namespace - no pod restart required</td>
    </tr>
    <tr>
      <th>Incremental deployment</th>
      <td>Binary: sidecar is injected or it isn't</td>
      <td>Gradual: L4 is always on, L7 can be added by configuration</td>
    </tr>
    <tr>
      <th>Lifecycle management</th>
      <td>Proxies managed by application developer</td>
      <td>Platform administrator</td>
    </tr>
    <tr>
      <th>Utilization of resources</th>
      <td>Wasteful; CPU and memory resources must be provisioned for worst case usage of each individual pod</td>
      <td>Waypoint proxies can be auto-scaled like any other Kubernetes deployment.<br>A workload with many replicas can use one waypoint, vs. each one having its own sidecar.
      </td>
    </tr>
    <tr>
      <th>Average resource cost</th>
      <td>Large</td>
      <td>Small</td>
    </tr>
    <tr>
      <th>Average latency (p90/p99)</th>
      <td>0.63ms-0.88ms</td>
      <td>Ambient: 0.16ms-0.20ms<br />Waypoint: 0.40ms-0.50ms</td>
    </tr>
    <tr>
      <th>L7 processing steps</th>
      <td>2 (source and destination sidecar)</td>
      <td>1 (destination waypoint)</td>
    </tr>
    <tr>
      <th>Configuration at scale</th>
      <td>Requires <a href="/docs/ops/configuration/mesh/configuration-scoping/">configuration of the scope of each sidecar</a> to reduce configuration</td>
      <td>Works without custom configuration</td>
    </tr>
    <tr>
      <th>Supports "server-first" protocols</th>
      <td><a href="/docs/ops/deployment/application-requirements/#server-first-protocols">Requires configuration</a></td>
      <td>Yes</td>
    </tr>
    <tr>
      <th>Support for Kubernetes Jobs</th>
      <td>Complicated by long life of sidecar</td>
      <td>Transparent</td>
    </tr>
    <tr>
      <th>Security model</th>
      <td>Strongest: each workload has its own keys</td>
      <td>Strong: each node agent has only the keys for workloads on that node</td>
    </tr>
    <tr>
      <th>Compromised application pod<br>gives access to mesh keys</th>
      <td>Yes</td>
      <td>No</td>
    </tr>
    <tr>
      <th>Support</th>
      <td>Stable, including multi-cluster</td>
      <td>Beta, single-cluster</td>
    </tr>
    <tr>
      <th>Platforms supported</th>
      <td>Kubernetes (any CNI)<br />Virtual machines</td>
      <td>Kubernetes (any CNI)</td>
    </tr>
  </tbody>
</table>

## Layer 4 vs Layer 7 features

The overhead for processing protocols at Layer 7 is substantially higher than processing network packets at Layer 4. For a given service, if your requirements can be met at L4, service mesh can be delivered at substantially lower cost.

### Security

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Encryption</th>
      <td>All traffic between pods is encrypted using {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}}.</td>
      <td>N/A&mdash;service identity in Istio is based on TLS.</td>
    </tr>
    <tr>
      <th>Service-to-service authentication</th>
      <td>{{< gloss >}}SPIFFE{{< /gloss >}}, via mTLS certificates. Istio issues a short-lived X.509 certificate that encodes the pod's service account identity.</td>
      <td>N/A&mdash;service identity in Istio is based on TLS.</td>
    </tr>
    <tr>
      <th>Service-to-service authorization</th>
      <td>Network-based authorization, plus identity-based policy, e.g.:
        <ul>
          <li>A can accept inbound calls from only "10.2.0.0/16";</li>
          <li>A can call B.</li>
        </ul>
      </td>
      <td>Full policy, e.g.:
        <ul>
          <li>A can GET /foo on B only with valid end-user credentials containing the READ scope.</li>
        </ul>
      </td>
    </tr>
    <tr>
      <th>End-user authentication</th>
      <td>N/A&mdash;we can't apply per-user settings.</td>
      <td>Local authentication of JWTs, support for remote authentication via OAuth and OIDC flows.</td>
    </tr>
    <tr>
      <th>End-user authorization</th>
      <td>N/A&mdash;see above.</td>
      <td>Service-to-service policies can be extended to require <a href="/docs/reference/config/security/conditions/">end-user credentials with specific scopes, issuers, principal, audiences, etc.</a><br />Full user-to-resource access can be implemented using external authorization, allowing per-request policy with decisions from an external service, e.g. OPA.</td>
    </tr>
  </tbody>
</table>

### Observability

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Logging</th>
      <td>Basic network information: network 5-tuple, bytes sent/received, etc. <a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">See Envoy docs</a>.</td>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">Full request metadata logging</a>, in addition to basic network information.</td>
    </tr>
    <tr>
      <th>Tracing</th>
      <td>Not today; possible eventually with HBONE.</td>
      <td>Envoy participates in distributed tracing. <a href="/docs/tasks/observability/distributed-tracing/overview/">See Istio overview on tracing</a>.</td>
    </tr>
    <tr>
      <th>Metrics</th>
      <td>TCP only (bytes sent/received, number of packets, etc.).</td>
      <td>L7 RED metrics: rate of requests, rate of errors, request duration (latency).</td>
    </tr>
  </tbody>
</table>

### Traffic management

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Load balancing</th>
      <td>Connection level only. <a href="/docs/tasks/traffic-management/tcp-traffic-shifting/">See TCP traffic shifting task</a>.</td>
      <td>Per request, enabling e.g. canary deployments, gRPC traffic, etc. <a href="/docs/tasks/traffic-management/traffic-shifting/">See HTTP traffic shifting task</a>.</td>
    </tr>
    <tr>
      <th>Circuit breaking</th>
      <td><a href="/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-TCPSettings">TCP only</a>.</td>
      <td><a href="/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings">HTTP settings</a> in addition to TCP.</td>
    </tr>
    <tr>
      <th>Outlier detection</th>
      <td>On connection establishment/failure.</td>
      <td>On request success/failure.</td>
    </tr>
    <tr>
      <th>Rate limiting</th>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rate_limit_filter#config-network-filters-rate-limit">Rate limit on L4 connection data only, on connection establishment</a>, with global and local rate limiting options.</td>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter#config-http-filters-rate-limit">Rate limit on L7 request metadata</a>, per request.</td>
    </tr>
    <tr>
      <th>Timeouts</th>
      <td>Connection establishment only (connection keep-alive is configured via circuit breaking settings).</td>
      <td>Per request.</td>
    </tr>
    <tr>
      <th>Retries</th>
      <td>Retry connection establishment</td>
      <td>Retry per request failure.</td>
    </tr>
    <tr>
      <th>Fault injection</th>
      <td>N/A&mdash;fault injection cannot be configured on TCP connections.</td>
      <td>Full application and connection-level faults (<a href="/docs/tasks/traffic-management/fault-injection/">timeouts, delays, specific response codes</a>).</td>
    </tr>
    <tr>
      <th>Traffic mirroring</th>
      <td>N/A&mdash;HTTP only</td>
      <td><a href="/docs/tasks/traffic-management/mirroring/">Percentage-based mirroring of requests to multiple backends</a>.</td>
    </tr>
  </tbody>
</table>

## Supported features

As of Istio 1.22, the following ambient mode features are implemented but are currently in Alpha status:

* Interoperability with sidecars
* Istio’s classic APIs (VirtualService and DestinationRule)
* Multi-cluster installations
* DNS proxying
* IPv6/Dual stack
* SOCKS5 support (for outbound)

The following features are not yet implemented:

* Controlled egress traffic
* Multi-network support
* VM support
