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

- **Named service ports**: Service ports must be named. The port name key/value
  pairs must have the following syntax: `name: <protocol>[-<suffix>]`. See
  [Protocol Selection](/docs/ops/configuration/traffic-management/protocol-selection/) for
  more details.

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

- **`NET_ADMIN` and `NET_RAW` capabilities**: If your cluster enforces pod security policies,
  they must allow injected pods to add the `NET_ADMIN` and `NET_RAW` capabilities.
  If you use the [Istio CNI Plugin](/docs/setup/additional-setup/cni/),
  this requirement no longer applies. To learn more about the `NET_ADMIN` and `NET_RAW`
  capabilities, see [Required pod capabilities](#required-pod-capabilities), below.

## Ports used by Istio

The following ports and protocols are used by Istio. Ensure that there are no
TCP headless services using a TCP port used by one of Istio's services.

| Port | Protocol | Used by | Description |
|----|----|----|----|
| 8060 | HTTP | Citadel | GRPC server |
| 8080 | HTTP | Citadel agent | SDS service monitoring |
| 9090 | HTTP |  Prometheus | Prometheus |
| 9091 | HTTP | Mixer | Policy/Telemetry |
| 9876 | HTTP | Citadel, Citadel agent |  ControlZ user interface |
| 9901 | GRPC | Galley| Mesh Configuration Protocol |
| 15000 | TCP | Envoy | Envoy admin port (commands/diagnostics) |
| 15001 | TCP | Envoy | Envoy Outbound |
| 15006 | TCP | Envoy | Envoy Inbound |
| 15004 | HTTP | Mixer, Pilot | Policy/Telemetry - `mTLS` |
| 15010 | HTTP | Pilot | Pilot service - XDS pilot - discovery |
| 15011 | TCP | Pilot | Pilot service - `mTLS` - Proxy - discovery |
| 15014 | HTTP | Citadel, Citadel agent, Galley, Mixer, Pilot, Sidecar Injector | Control plane monitoring |
| 15020 | HTTP | Ingress Gateway | Pilot health checks |
| 15029 | HTTP | Kiali | Kiali User Interface |
| 15030 | HTTP | Prometheus | Prometheus User Interface |
| 15031 | HTTP | Grafana | Grafana User Interface |
| 15032 | HTTP | Tracing | Tracing User Interface |
| 15443 | TLS | Ingress and Egress Gateways | SNI |
| 15090 | HTTP | Mixer | Proxy |
| 42422 | TCP | Mixer | Telemetry - Prometheus |

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
