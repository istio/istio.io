---
title: Announcing Istio 1.3
subtitle: Major Update
description: Istio 1.3 release announcement.
publishdate: 2019-09-12
attribution: The Istio Team
release: 1.3.0
aliases:
    - /about/notes/1.3
    - /blog/2019/announcing-1.3
---

We are pleased to announce the release of Istio 1.3!

{{< relnote >}}

The theme of Istio 1.3 is User Experience:

- Improve the experience of new users adopting Istio
- Improve the experience of users debugging problems
- Support more applications without any additional configuration

Every few releases, the Istio team delivers dramatic improvements to usability, APIs, and the overall system performance. Istio 1.3 is one such release, and the team is very excited to roll out some key updates.

## Intelligent protocol detection (experimental)

To take advantage of Istio's routing features, service ports must use a special port naming format to explicitly declare the protocol. This requirement can cause problems for users that do not name their ports when they add their applications to the mesh. Starting with 1.3, the protocol for outbound traffic is automatically detected as HTTP or TCP when the ports are not named according to Istio's conventions. We will be polishing this feature in the upcoming releases with support for protocol sniffing on inbound traffic as well as identifying protocols other than HTTP.

## Mixer-less telemetry (experimental)

Yes, you read that right! We implemented most of the common security policies, such as RBAC, directly into Envoy. We previously turned off the `istio-policy` service by default and are now on track to migrate most of Mixer's telemetry functionality into Envoy as well. In this release, we have enhanced the Istio proxy to emit HTTP metrics directly to Prometheus, without requiring the `istio-telemetry` service to enrich the information. This enhancement is great if all you care about is telemetry for HTTP services. Follow the [Mixer-less HTTP telemetry instructions](https://github.com/istio/istio/wiki/Mixerless-HTTP-Telemetry) to experiment with this feature. We are polishing this feature in the coming months to add telemetry support for TCP services when you enable Istio mutual TLS.

## Container ports are no longer required

Previous releases required that pods explicitly declare the Kubernetes `containerPort` for each container as a security measure against trampolining traffic. Istio 1.3 has a secure and simpler way of handling all inbound traffic on any port into a {{< gloss >}}workload instance{{< /gloss >}} without requiring the `containerPort` declarations. We have also completely eliminated the infinite loops caused in the IP tables rules when workload instances send traffic to themselves.

## Fully customize generated Envoy configuration

While Istio 1.3 focuses on usability, expert users can use advanced features in Envoy that are not part of the Istio Networking APIs. We enhanced the `EnvoyFilter` API to allow users to fully customize:

- The HTTP/TCP listeners and their filter chains returned by LDS
- The Envoy HTTP route configuration returned by the RDS
- The set of clusters returned by CDS

You get the best of both worlds:

Leverage Istio to integrate with Kubernetes and handle large fleets of Envoys in an efficient manner, while you still can customize the generated Envoy configuration to meet specific requirements within your infrastructure.

## Other enhancements

- `istioctl` gained many debugging features to help you highlight various issues in your mesh installation. Checkout the `istioctl` [reference page](/docs/reference/commands/istioctl/) for the set of all supported features.

- Locality aware load balancing graduated from experimental to default in this release too. Istio now takes advantage of existing locality information to prioritize load balancing pools and favor sending requests to the closest backends.

- Better support for headless services with Istio mutual TLS

- We enhanced control plane monitoring in the following ways:

    - Added new metrics to monitor configuration state
    - Added metrics for sidecar injector
    - Added a new Grafana dashboard for Citadel
    - Improved the Pilot dashboard to expose additional key metrics

- Added the new [Istio Deployment Models concept](/docs/concepts/deployment-models/) to help you decide what deployment model suits your needs.

- Organized the content in of our [Operations Guide](/docs/ops/) and created a [section with all troubleshooting tasks](/docs/ops/troubleshooting) to help you find the information you seek faster.

As always, there is a lot happening in the [Community Meeting](https://github.com/istio/community#community-meeting); join us every other Thursday at 11 AM Pacific.

The growth and success of Istio is due to its 400+ contributors from over 300 companies. Join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us make Istio even better.

To join the conversation, go to [discuss.istio.io](https://discuss.istio.io), log in with your GitHub credentials and join us!

## Release notes

### Installation

- **Added** experimental [manifest and profile commands](/docs/setup/install/operator/) to install and manage the Istio control plane for evaluation.

### Traffic management

- **Added** [automatic determination](/docs/ops/traffic-management/protocol-selection/) of HTTP or TCP for outbound traffic when ports are not named according to Istio’s [conventions](/docs/setup/additional-setup/requirements/).
- **Added** a mode to the Gateway API for mutual TLS operation.
- **Fixed** issues present when a service communicates over the network first in permissive mutual TLS mode for protocols like MySQL and MongoDB.
- **Improved** Envoy proxy readiness checks. They now check Envoy's readiness status.
- **Improved** container ports are no longer required in the pod spec. All ports are [captured by default](/faq/traffic-management/#controlling-inbound-ports).
- **Improved** the `EnvoyFilter` API. You can now add or update all configurations.
- **Improved** the Redis load balancer to now default to [`MAGLEV`](https://www.envoyproxy.io/docs/envoy/v1.6.0/intro/arch_overview/load_balancing#maglev) when using the Redis proxy.
- **Improved** load balancing to direct traffic to the [same region and zone](/faq/traffic-management/#controlling-inbound-ports) by default.
- **Improved** Pilot by reducing CPU utilization. The reduction approaches 90% depending on the specific deployment.
- **Improved** the `ServiceEntry` API to allow for the same hostname in different namespaces.
- **Improved** the [Sidecar API](/docs/reference/config/networking/v1alpha3/sidecar/#OutboundTrafficPolicy) to customize the `OutboundTrafficPolicy` policy.

### Security

- **Added** trust domain validation for services using mutual TLS. By default, the server only authenticates the requests from the same trust domain.
- **Added** [labels](/docs/concepts/security/#how-citadel-determines-whether-to-create-service-account-secrets) to control service account secret generation by namespace.
- **Added** SDS support to deliver the private key and certificates to each Istio control plane service.
- **Added** support for [introspection](/docs/ops/troubleshooting/controlz/) to Citadel.
- **Added** metrics to the `/metrics` endpoint of Citadel Agent on port 15014 to monitor the SDS service.
- **Added** diagnostics to the Citadel Agent using the `/debug/sds/workload` and `/debug/sds/gateway` on port 8080.
- **Improved** the ingress gateway to [load the trusted CA certificate from a separate secret](/docs/tasks/traffic-management/ingress/secure-ingress-sds/#configure-a-mutual-tls-ingress-gateway) when using SDS.
- **Improved** SDS security by enforcing the usage of [Kubernetes Trustworthy JWTs](/blog/2019/trustworthy-jwt-sds).
- **Improved** Citadel Agent logs by unifying the logging pattern.
- **Removed** support for Istio SDS when using [Kubernetes versions earlier than 1.13](/blog/2019/trustworthy-jwt-sds).
- **Removed** integration with Vault CA temporarily. SDS requirements caused the temporary removal but we will reintroduce Vault CA integration in a future release.
- **Enabled** the Envoy JWT filter by default to improve security and reliability.

### Telemetry

- **Added** Access Log Service [ALS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/service/accesslog/v2/als.proto#grpc-access-log-service-als) support for Envoy gRPC.
- **Added** a Grafana dashboard for Citadel monitoring.
- **Added** [metrics](/docs/reference/commands/sidecar-injector/#metrics) for monitoring the sidecar injector webhook.
- **Added** control plane metrics to monitor Istio's configuration state.
- **Added** telemetry reporting for traffic destined to the `Passthrough` and `BlackHole` clusters.
- **Added** alpha support for in-proxy generation of service metrics using Prometheus.
- **Added** alpha support for environmental metadata in Envoy node metadata.
- **Added** alpha support for Proxy Metadata Exchange.
- **Added** alpha support for the OpenCensus trace driver.
- **Improved** reporting for external services by removing requirements to add a service entry.
- **Improved** the mesh dashboard to provide monitoring of Istio's configuration state.
- **Improved** the Pilot dashboard to expose additional key metrics to more clearly identify errors.
- **Removed** deprecated `Adapter` and `Template` custom resource definitions (CRDs).
- **Deprecated** the HTTP API spec used to produce API attributes. We will remove support for producing API attributes in Istio 1.4.

### Policy

- **Improved** rate limit enforcement to allow communication when the quota backend is unavailable.

### Configuration management

- **Fixed** Galley to stop too many gRPC pings from closing connections.
- **Improved** Galley to avoid control plane upgrade failures.

### `istioctl`

- **Added** [`istioctl experimental manifest`](/docs/reference/commands/istioctl/#istioctl-experimental-manifest) to manage the new experimental install manifests.
- **Added** [`istioctl experimental profile`](/docs/reference/commands/istioctl/#istioctl-experimental-profile) to manage the new experimental install profiles.
- **Added** [`istioctl experimental metrics`](/docs/reference/commands/istioctl/#istioctl-experimental-metrics)
- **Added** [`istioctl experimental describe pod`](/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod) to describe an Istio pod's configuration.
- **Added** [`istioctl experimental add-to-mesh`](/docs/reference/commands/istioctl/#istioctl-experimental-add-to-mesh) to add Kubernetes services or virtual machines to an existing Istio service mesh.
- **Added** [`istioctl experimental remove-from-mesh`](/docs/reference/commands/istioctl/#istioctl-experimental-remove-from-mesh) to remove Kubernetes services or virtual machines from an existing Istio service mesh.
- **Promoted** the [`istioctl experimental convert-ingress`](/docs/reference/commands/istioctl/#istioctl-convert-ingress) command to `istioctl convert-ingress`.
- **Promoted** the [`istioctl experimental dashboard`](/docs/reference/commands/istioctl/#istioctl-dashboard) command to `istioctl dashboard`.

### Other

- **Added** new images based on [distroless](/docs/ops/security/harden-docker-images/) base images.
- **Improved** the Istio CNI Helm chart to have consistent versions with Istio.
- **Improved** Kubernetes Jobs behavior. Kubernetes Jobs now exit correctly when the job manually calls the `/quitquitquit` endpoint.
