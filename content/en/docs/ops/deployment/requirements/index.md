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

- **Service association**: A pod must belong to at least one Kubernetes
  service even if the pod does NOT expose any port.
  If a pod belongs to multiple [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/),
  the services cannot use the same port number for different protocols, for
  instance HTTP and TCP.

- **Application UIDs**: Ensure your pods do **not** run applications as a user
  with the user ID (UID) value of `1337` because `1337` is reserved for the sidecar proxy.

- **`NET_ADMIN` and `NET_RAW` capabilities**: If [pod security policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
    are [enforced](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies)
    in your cluster and unless you use the [Istio CNI Plugin](/docs/setup/additional-setup/cni/), your pods must have the
    `NET_ADMIN` and `NET_RAW` capabilities allowed. The initialization containers of the Envoy
    proxies require these capabilities.

    To check if the `NET_ADMIN` and `NET_RAW` capabilities are allowed for your pods, you need to check if their
    [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
    can use a pod security policy that allows the `NET_ADMIN` and `NET_RAW` capabilities.
    If you haven't specified a service account in your pods' deployment, the pods run using
    the `default` service account in their deployment's namespace.

    To list the capabilities for a service account, replace `<your namespace>` and `<your service account>`
    with your values in the following command:

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    For example, to check for the `default` service account in the `default` namespace, run the following command:

    {{< text bash >}}
    $ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    If you see `NET_ADMIN` and `NET_RAW` or `*` in the list of capabilities of one of the allowed
    policies for your service account, your pods have permission to run the Istio init containers.
    Otherwise, you will need to [provide the permission](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies).

- **Pods with app and version labels**: We recommend adding an explicit
  `app` label and `version` label to the specification of the pods deployed using
  a Kubernetes `Deployment`. The `app` and `version` labels add contextual information
  to the metrics and telemetry that Istio collects.

    - The `app` label: Each deployment should have a distinct
      `app` label with a meaningful value. The `app` label is used to add
      contextual information in distributed tracing.

    - The `version` label: This label indicates the version of the application
      corresponding to the particular deployment.

- **Named service ports**: Service ports may optionally be named to explicitly specify a protocol.
  See [Protocol Selection](/docs/ops/configuration/traffic-management/protocol-selection/) for
  more details.

## Ports used by Istio

The following ports and protocols are used by the Istio sidecar proxy (Envoy).

{{< warning >}}
To avoid port conflicts with sidecars, applications should not use any of the ports used by Envoy.
{{< /warning >}}

| Port | Protocol | Description | Pod-internal only |
|----|----|----|----|
| 15000 | TCP | Envoy admin port (commands/diagnostics) | Yes |
| 15001 | TCP | Envoy outbound | No |
| 15004 | HTTP | Debug port | Yes |
| 15006 | TCP | Envoy inbound | No |
| 15008 | H2 | HBONE mTLS tunnel port | No |
| 15009 | H2C | HBONE port for secure networks | No |
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

For HTTP based traffic, traffic is routed based on the `Host` header. This may lead to unexpected behavior if the destination IP
and `Host` header are not aligned. For example, a request like `curl 1.2.3.4 -H "Host: httpbin.default"` will be routed to the `httpbin` service,
rather than `1.2.3.4`.

For Non-HTTP based traffic (including HTTPS), Istio does not have access to an `Host` header, so routing decisions are based on the Service IP address.

One implication of this is that direct calls to pods (for example, `curl <POD_IP>`), rather than Services, will not be matched. While the traffic may
be [passed through](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services), it will not get the full Istio functionality
including mTLS encryption, traffic routing, and telemetry.
