---
title: Application Requirements
description: Requirements of applications deployed in an Istio-enabled cluster.
weight: 40
keywords:
  - kubernetes
  - sidecar
  - sidecar-injection
  - deployment-models
  - pods
  - setup
aliases:
  - /docs/setup/kubernetes/spec-requirements/
  - /docs/setup/kubernetes/prepare/spec-requirements/
  - /docs/setup/kubernetes/prepare/requirements/
  - /docs/setup/kubernetes/additional-setup/requirements/
  - /docs/setup/additional-setup/requirements
  - /docs/ops/setup/required-pod-capabilities
  - /help/ops/setup/required-pod-capabilities
  - /docs/ops/prep/requirements
  - /docs/ops/deployment/requirements
owner: istio/wg-environments-maintainers
test: n/a
---

Istio provides a great deal of functionality to applications with little or no impact on the application code itself.
Many Kubernetes applications can be deployed in an Istio-enabled cluster without any changes at all.
However, there are some implications of Istio's sidecar model that may need special consideration when deploying
an Istio-enabled application.
This document describes these application considerations and specific requirements of Istio enablement.

## Pod requirements

To be part of a mesh, Kubernetes pods must satisfy the following requirements:

- **Application UIDs**: Ensure your pods do **not** run applications as a user
  with the user ID (UID) value of `1337` because `1337` is reserved for the sidecar proxy.

- **`NET_ADMIN` and `NET_RAW` capabilities**: Unless you use the
    [Istio CNI Plugin](/docs/setup/additional-setup/cni/), the `istio-init` container requires
    `NET_ADMIN` and `NET_RAW` capabilities to configure iptables traffic redirection. The
    namespace must use the `baseline` or `privileged`
    [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
    enforcement level. The `restricted` level blocks these capabilities and will prevent the
    `istio-init` container from running.

    To check the current enforcement level on a namespace and set it if needed:

    {{< text bash >}}
    $ kubectl get namespace <your namespace> --show-labels
    $ kubectl label namespace <your namespace> pod-security.kubernetes.io/enforce=baseline
    {{< /text >}}

    If your security policy requires `restricted` enforcement on the namespace, use the
    [Istio CNI Plugin](/docs/setup/additional-setup/cni/) instead, which handles traffic
    redirection without requiring elevated capabilities in the pod.

    {{< tip >}}
    [PodSecurityPolicy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) was
    removed in Kubernetes 1.25 and replaced by Pod Security Admission.
    {{< /tip >}}

- **Pod labels**: We recommend explicitly declaring pods with an application identifier and version by using a pod label.
  These labels add contextual information to the metrics and telemetry that Istio collects.
  Each of these values are read from multiple labels ordered from highest to lowest precedence:

    - Application name: `service.istio.io/canonical-name`, `app.kubernetes.io/name`, or `app`.
    - Application version: `service.istio.io/canonical-revision`, `app.kubernetes.io/version`, or `version`.

- **Named service ports**: Service ports may optionally be named to explicitly specify a protocol.
  See [Protocol Selection](/docs/ops/configuration/traffic-management/protocol-selection/) for
  more details. If a pod belongs to multiple [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/),
  the services cannot use the same port number for different protocols, for
  instance HTTP and TCP.

## Ports used by Istio

The following ports and protocols are used by the Istio sidecar proxy (Envoy).

{{< warning >}}
To avoid port conflicts with sidecars, applications should not use any of the ports used by Envoy.
{{< /warning >}}

| Port | Protocol | Description | Pod-internal only |
|----|----|----|----|
| 15000 | TCP | Envoy admin port (commands/diagnostics) | Yes |
| 15001 | TCP | Envoy outbound | No |
| 15002 | TCP | Listen port for failure detection | Yes |
| 15004 | HTTP | Debug port | Yes |
| 15006 | TCP | Envoy inbound | No |
| 15008 | HTTP2 | {{< gloss >}}HBONE{{</ gloss >}} mTLS tunnel port | No |
| 15020 | HTTP | Merged Prometheus telemetry from Istio agent, Envoy, and application | No |
| 15021 | HTTP | Health checks | No |
| 15053 | DNS  | DNS port, if capture is enabled | Yes |
| 15090 | HTTP | Envoy Prometheus telemetry | No |

The following ports and protocols are used by the Istio control plane (istiod).

| Port | Protocol | Description | Local host only |
|----|----|----|----|
| 443 | HTTPS | Webhooks service port | No |
| 8080 | HTTP | Debug interface (deprecated, container port only) | No |
| 15010 | GRPC | XDS and CA services (Plaintext, only for secure networks) | No |
| 15012 | GRPC | XDS and CA services (TLS and mTLS, recommended for production use) | No |
| 15014 | HTTP | Control plane monitoring | No |
| 15017 | HTTPS | Webhook container port, forwarded from 443 | No |

## Server First Protocols

Some protocols are "Server First" protocols, which means the server will send the first bytes. This may have an impact on
[`PERMISSIVE`](/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode) mTLS and [Automatic protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection).

Both of these features work by inspecting the initial bytes of a connection to determine the protocol, which is incompatible with server first protocols.

In order to support these cases, follow the [Explicit protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) steps to declare the protocol of the application as `TCP`.

The following ports are known to commonly carry server first protocols, and are automatically assumed to be `TCP`:

|Protocol|Port|
|--------|----|
| SMTP   |25  |
| DNS    |53  |
| MySQL  |3306|
| MongoDB|27017|

Because TLS communication is not server first, TLS encrypted server first traffic will work with automatic protocol detection as long as you make sure that all traffic subjected to TLS sniffing is encrypted:

1. Configure `mTLS` mode `STRICT` for the server. This will enforce TLS encryption for all requests.
1. Configure `mTLS` mode `DISABLE` for the server. This will disable the TLS sniffing, allowing server first protocols to be used.
1. Configure all clients to send `TLS` traffic, generally through a [`DestinationRule`](/docs/reference/config/networking/destination-rule/#ClientTLSSettings) or by relying on auto mTLS.
1. Configure your application to send TLS traffic directly.

## Outbound traffic

In order to support Istio's traffic routing capabilities, traffic leaving a pod may be routed differently than
when a sidecar is not deployed.

For HTTP-based traffic, traffic is routed based on the `Host` header. This may lead to unexpected behavior if the destination IP
and `Host` header are not aligned. For example, a request like `curl 1.2.3.4 -H "Host: httpbin.default"` will be routed to the `httpbin` service,
rather than `1.2.3.4`.

For Non HTTP-based traffic (including HTTPS), Istio does not have access to an `Host` header, so routing decisions are based on the Service IP address.

One implication of this is that direct calls to pods (for example, `curl <POD_IP>`), rather than Services, will not be matched. While the traffic may
be [passed through](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services), it will not get the full Istio functionality
including mTLS encryption, traffic routing, and telemetry.

See the [Traffic Routing](/docs/ops/configuration/traffic-management/traffic-routing) page for more information.
