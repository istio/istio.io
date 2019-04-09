---
title: Pods and Services
description:  Prepare your Kubernetes pods and services to run in an Istio-enabled cluster.
weight: 5
aliases:
    - /docs/setup/kubernetes/spec-requirements/
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

## Ports used by Istio

The following ports and protocols are used by Istio. Ensure that there are no TCP headless services using a TCP port used by one of Istio's services.

| Port | Protocol | Used by | Description |
|----|----|----|----|
| 8060 | HTTP | Citadel | GRPC server |
| 9090 | HTTP |  Prometheus | Prometheus |
| 9091 | HTTP | Mixer | Policy/Telemetry |
| 9093 | HTTP | Citadel | |
| 15000 | TCP | Envoy | Envoy admin port (commands/diagnostics) |
| 15001 | TCP | Envoy | Envoy |
| 15004 | HTTP | Mixer, Pilot | Policy/Telemetry - `mTLS` |
| 15010 | HTTP | Pilot | Pilot service - XDS pilot - discovery |
| 15011 | TCP | Pilot | Pilot service - `mTLS` - Proxy - discovery |
| 15014 | HTTP | Citadel, Mixer, Pilot | Control plane monitoring |
| 15030 | TCP | Prometheus | Prometheus |
| 15090 | HTTP | Mixer | Proxy |
| 42422 | TCP | Mixer | Telemetry - Prometheus |
