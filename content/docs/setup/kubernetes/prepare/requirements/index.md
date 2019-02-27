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

* _**Check required ports**_: The following table lists the default ports used by Istio components. Make sure the ports are available before installing Istio components.

    | Component | Port | NodePort | Description |
    |----|----|----|----|
    | Citadel | 8060 |   | The port number for Citadel GRPC server |
    | | | | |
    | Core DNS | 53 |   | DNS - TCP/UDP Protocols |
    | Core DNS | 8053 |   | DNS plugin |
    | Core DNS | 9153 |   | DNS |
    | | | | |
    | Egress gateway | 80 |   |   |
    | Egress gateway | 443 |   |   |
    | Egress gateway | 15090 |   | Proxy |
    | Egress gateway | 15443 |   | This is the port where SNI routing happens |
    | | | | |
    | Galley | 443 |   | Validation port |
    | Galley | 9091 |   | Mesh control Plane - Running mixer |
    | Galley | 9094 |   | Port to use for exposing profiling (no longer used?) |
    | Galley | 15014 |   | Monitoring |
    | | | | |
    | Grafana | 3000 |   | Grafana |
    | Grafana | 15031 |   | Grafana |
    | | | | |
    | Envoy | 15000 |   | Envoy admin port (commands/diagnostics) |
    | | | | |
    | Ingress gateway | 80 | 31380 |   |
    | Ingress gateway | 443 | 31390 |   |
    | Ingress gateway | 15029 |   | Kiali |
    | Ingress gateway | 15030 |   | Prometheus |
    | Ingress gateway | 15031 |   | Grafana |
    | Ingress gateway | 15032 |   | Tracing |
    | Ingress gateway | 15090 |   | Proxy |
    | Ingress gateway | 15443 |   | This is the port where SNI routing happens |
    | Ingress gateway | 31400 | 31400 | Sample port|
    | | | | |
    | Mixer | 9091 |   | Policy/Telemetry |
    | Mixer | 15004 |   | Policy/Telemetry - `mTLS`|
    | Mixer | 15014 |   | Policy/Telemetry monitoring port |
    | Mixer | 15090 |   | Proxy |
    | Mixer | 42422 |   | Telemetry - Prometheus |
    | | | | |
    | Pilot | 8080 |   | Pilot service - Discovery - legacy |
    | Pilot | 15003 |   | Pilot service - Proxy - http - Discovery - old |
    | Pilot | 15004 |   | Pilot service - Mixer |
    | Pilot | 15005 |   | Pilot service - Proxy - https - Discovery |
    | Pilot | 15007 |   | Pilot service - Proxy - http - Discovery |
    | Pilot | 15010 |   | Pilot service - XDS pilot - discovery |
    | Pilot | 15011 |   | Pilot service - `mTLS` - Proxy - discovery |
    | Pilot | 15012 |   | Pilot service - `mTLS` - Proxy - Discovery service grpc address, with https discovery (still used?) |
    | Pilot | 15014 |   | Pilot service - Monitoring |
    | | | | |
    | Prometheus | 9090 |   | Prometheus |
    | | | | |
    | Service Graph | 8088 |   | Service Graph |
    | | | | |
    | Sidecar injector | 443 |   | Sidecar injector |
    | | | | |
    | Tracing | 80 |   | Tracing - Jaeger |
    | Tracing | 9411 |   | Tracing - Other |
    | Tracing | 15032 |   | Tracing - Jaeger |
    | Tracing | 16686 |   | Tracing - Jaeger |
    | | | | |
    | Zipkin | 9411 |   | Zipkin collector |
