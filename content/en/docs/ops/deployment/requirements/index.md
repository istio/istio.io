---
title: Pods and Services
description: Prepare your Kubernetes pods and services to run in an Istio-enabled
  cluster.
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
---

To be part of a mesh, Kubernetes pods and services must satisfy the following
requirements:

- **Service association**: A pod must belong to at least one Kubernetes
  service even if the pod does NOT expose any port.
  If a pod belongs to multiple [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/),
  the services cannot use the same port number for different protocols, for
  instance HTTP and TCP.

- **Application UIDs**: Ensure your pods do **not** run applications as a user
  with the user ID (UID) value of **1337**.

- **`NET_ADMIN` and `NET_RAW` capabilities**: If your cluster enforces pod security policies,
  they must allow injected pods to add the `NET_ADMIN` and `NET_RAW` capabilities.
  If you use the [Istio CNI Plugin](/docs/setup/additional-setup/cni/),
  this requirement no longer applies. To learn more about the `NET_ADMIN` and `NET_RAW`
  capabilities, see [Required pod capabilities](#required-pod-capabilities), below.

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

- **Named service ports**: Service ports may optionally be named to explicitly specify a protocol.
  See [Protocol Selection](/docs/ops/configuration/traffic-management/protocol-selection/) for
  more details.

## Ports used by Istio

The following ports and protocols are used by Istio.

| Port | Protocol | Used by | Description |
|----|----|----|----|
| 15000 | TCP | Envoy | Envoy admin port (commands/diagnostics) |
| 15001 | TCP | Envoy | Envoy Outbound |
| 15006 | TCP | Envoy | Envoy Inbound |
| 15020 | HTTP | Envoy | Health checks |
| 15090 | HTTP | Envoy | Prometheus telemetry |
| 15010 | GRPC | Istiod | XDS and CA services (plaintext) |
| 15011 | GRPC | Istiod | XDS and CA services (TLS, legacy) |
| 15012 | GRPC | Istiod | XDS and CA services (TLS) |
| 8080 | HTTP | Istiod | Debug interface |
| 443 | HTTPS | Istiod | Webhooks |
| 15014 | HTTP | Citadel, Citadel agent, Galley, Mixer, Istiod, Sidecar Injector | Control plane monitoring |
| 15029 | HTTP | Kiali | Kiali User Interface |
| 15030 | HTTP | Prometheus | Prometheus User Interface |
| 15031 | HTTP | Grafana | Grafana User Interface |
| 15032 | HTTP | Tracing | Tracing User Interface |
| 15443 | TLS | Ingress and Egress Gateways | SNI |
| 9090 | HTTP |  Prometheus | Prometheus |
| 42422 | TCP | Mixer | Telemetry - Prometheus |
| 15004 | HTTP | Mixer, Pilot | Policy/Telemetry - `mTLS` |
| 9091 | HTTP | Mixer | Policy/Telemetry |
| 8060 | HTTP | Citadel | GRPC server |
| 9876 | HTTP | Citadel, Citadel agent |  ControlZ user interface |
| 9901 | GRPC | Galley| Mesh Configuration Protocol |

## Required pod capabilities

If [pod security policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
are [enforced](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies)
in your cluster and unless you use the Istio CNI Plugin, your pods must have the
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

If you see `NET_ADMIN` and `NET_ADMIN` or `*` in the list of capabilities of one of the allowed
policies for your service account, your pods have permission to run the Istio init containers.
Otherwise, you will need to [provide the permission](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies).
