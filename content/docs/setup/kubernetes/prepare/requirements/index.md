---
title: Pods and Services
description:  Prepare your Kubernetes pods and services to run in an Istio-enabled cluster.
weight: 5
keywords: [kubernetes,sidecar,sidecar-injection]
---

To be a part of an Istio service mesh, pods and services in a Kubernetes
cluster must satisfy the following requirements:

- **Named service ports**: Service ports must be named. The port name key/value
  pairs must have the following syntax: `name: <protocol>[-<suffix>]`. To take
  advantage of Istio's routing features, replace `<protocol>` with one of the
  following values:

    - `grpc`
    - `http`
    - `http2`
    - `https`
    - `mongo`
    - `redis`
    - `tcp`
    - `tls`
    - `udp`

  For example, `name: http2-foo` or  `name: http` are valid port names, but
  `name: http2foo` is not. If the port name does not begin with a recognized
  prefix or if the port is unnamed, traffic on the port is treated as
  plain TCP traffic unless the port [explicitly](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)
  uses `Protocol: UDP` to signify a UDP port.

- **Pod ports**: Pods must include an explicit list of the ports each
  container listens on. Use a `containerPort` configuration in the container
  specification for each port. Any unlisted ports bypass the Istio proxy.

- **Service association**: A pod must belong to at least one Kubernetes
  service even if the pod does NOT expose any port.
  If a pod belongs to multiple [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/),
  the services cannot use the same port number for different protocols, for
  instance HTTP and TCP.

- **Deployments with app and version labels**: We recommend adding an explicit
  `app` label and `version` label to deployments. Add the labels  to the
  deployment specification of pods deployed using the Kubernetes `Deployment`.
  The `app` and `version` labels add contextual information to the metrics and
  telemetry Istio collects.

    - The `app` label: Each deployment specification should have a distinct
      `app` label with a meaningful value. The `app` label is used to add
      contextual information in distributed tracing.

    - The `version` label: This label indicates the version of the application
      corresponding to the particular deployment.

- **Application UIDs**: Ensure your pods do **not** run applications as a user
  with the user ID (UID) value of **1337**.

- **`NET_ADMIN` capability**: If your cluster enforces pod security policies,
  pods must allow the `NET_ADMIN` capability. If you use the [Istio CNI Plugin](/docs/setup/kubernetes/additional-setup/cni/),
  this requirement no longer applies. To learn more about the `NET_ADMIN`
  capability, visit [Required Pod Capabilities](/help/ops/setup/required-pod-capabilities/).

* _**Service Ports and Protocols**_: Ensure that your service's ports and protocols are available and don't conflict with the [Istio used ports and protocols](#istio-used-ports) for the Istio components be used.

## Istio Used Ports

The following ports and protocols are used by Istio.

If Istio is using HTTP on a port, a service may also use HTTP, but not TCP on that port. This is because HTTP routing is dependent on a number of factors such as Hostname, headers or path which removes the conflict.

If Istio is using TCP, another service may not use HTTP on that port. The service may potentially use TCP on that port, marked with a `?` in the table, by using SNI headers or IP address blocks. For example, see [Consuming External TCP Services](/blog/2018/egress-tcp/).

| Port | Protocol | Service can use HTTP? | Service can use TCP? | Used by | Description |
|----|----|----|----|----|----|
| 53 | TCP | No | `?` | Core DNS  | DNS - TCP/UDP Protocols |
| 80 | HTTP | Yes | No |  Egress gateway, Ingress Gateway, Tracing (Jaeger) |
| 443 | TCP | No | `?` |  Egress gateway, Galley (validation), Ingress Gateway, Sidecar Injector |
| 3000 | HTTP | Yes | No |  Grafana  |  Grafana |
| 8053 | TCP | No | `?` |  Core DNS  |  DNS plugin |
| 8060 | HTTP | Yes | No |  Citadel  |  The port number for Citadel GRPC server |
| 8080 | HTTP | Yes | No |  Pilot  |  Pilot service - Discovery - legacy |
| 8088 | HTTP | Yes | No |  Service Graph  |  Service Graph |
| 9090 | HTTP | Yes | No |  Prometheus  |  Prometheus |
| 9091 | HTTP | Yes | No |  Mixer |  Policy/Telemetry |
| 9093 | HTTP | Yes | No |  Citadel  | |
| 9153 | TCP | No | `?` |  Core DNS  |  DNS |
| 9411 | HTTP | Yes | No |  Tracing, Zipkin | |
| 9901 | HTTP | Yes | No |  Galley | |
| 14267 | TCP | No | `?` |  Tracing  |  Tracing - Jaeger |
| 14268 | TCP | No | `?` |  Tracing  |  Tracing - Jaeger |
| 15000 | TCP | No | `?` |  Envoy  |  Envoy admin port (commands/diagnostics) |
| 15001 | TCP | No | `?` |  Envoy  |  Envoy |
| 15004 | HTTP | Yes | `?` |  Mixer, Pilot |  Policy/Telemetry - `mTLS` |
| 15010 | HTTP | Yes | No |  Pilot  |  Pilot service - XDS pilot - discovery |
| 15011 | TCP | No | `?` |  Pilot  |  Pilot service - `mTLS` - Proxy - discovery |
| 15014 | HTTP | Yes | No |  Citadel, Galley, Mixer, Pilot  |  Control plane monitoring |
| 15029 | TCP | No | `?` |  Ingress gateway , Kiali |  Kiali |
| 15030 | TCP | No | `?` |  Ingress gateway, Prometheus |  Prometheus |
| 15031 | TCP | No | `?` |  Grafana, Ingress Gateway  |  Grafana |
| 15032 | TCP | No | `?` |  Ingress gateway, Tracing  |  Tracing |
| 15090 | HTTP | Yes | No |  Egress gateway, Ingress Gateway, Mixer  |  Proxy |
| 15443 | TCP | No | `?` |  Egress gateway, Ingress Gateway  |  This is the port where SNI routing happens |
| 16686 | TCP | No | ? |  Tracing  |  Tracing - Jaeger |
| 20001 | HTTP | Yes | No |  Kiali | |
| 42422 | TCP | No | ? |  Mixer  |  Telemetry - Prometheus |
