---
title: Announcing Istio 1.29.0
linktitle: 1.29.0
subtitle: Major Release
description: Istio 1.29 Release Announcement.
publishdate: 2026-02-12
release: 1.29.0
aliases:
    - /news/announcing-1.29
    - /news/announcing-1.29.0
---

We are pleased to announce the release of Istio 1.29. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.29.0 release published!
We would like to thank the Release Managers for this release, **Francisco Herrera** from Red Hat, and **Petr McAllister** from Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.29.0 is officially supported on Kubernetes versions 1.31 to 1.35.
{{< /tip >}}

## Security Update

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx) (CVSS score 8.6, High): A discrepancy between how Go and C/C++ comments were parsed allowed for code smuggling into the resulting cgo binary. 
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm) (CVSS score 4.8, Moderate): A flaw in crypto/tls session resumption allows resumed handshakes to succeed when they should fail if ClientCAs or RootCAs are mutated between the initial and resumed handshake. This can occur when using `Config.Clone` with mutations or `Config.GetConfigForClient`. As a result, clients may resume sessions with unintended servers, and servers may resume sessions with unintended clients.

## What's new?

### Ambient Mesh Production-Ready Enhancements

Istio 1.29 significantly strengthens ambient mesh capabilities with two major operational improvements enabled by default. DNS capture is now enabled by default for ambient workloads, improving security and performance while enabling advanced features like better service discovery and traffic management. This enhancement ensures that DNS traffic from ambient workloads is properly proxied through the mesh infrastructure.

Additionally, iptables reconciliation is now enabled by default, providing automatic network rule updates when the `istio-cni` DaemonSet is upgraded. This eliminates the manual intervention previously required to ensure existing ambient pods receive updated networking configuration, making ambient mesh operations more seamless and reliable for production environments.

### Enhanced Security Posture

This release introduces comprehensive security enhancements across multiple components. Certificate Revocation List (CRL) support is now available in ztunnel, allowing validation and rejection of revoked certificates when using plugged in certificate authorities. This strengthens the security posture of service mesh deployments using external CAs.

Debug endpoint authorization is enabled by default, providing namespace based access controls for debug endpoints on port 15014. Non system namespaces are now restricted to specific endpoints (`config_dump`, `ndsz`, `edsz`) and same namespace proxies only, improving security without impacting normal operations.

Optional NetworkPolicy deployment is now available for istiod, istio-cni, and ztunnel components, enabling users to deploy default NetworkPolicies with `global.networkPolicy.enabled=true` for enhanced network security.

### TLS Traffic Management for Wildcard Hosts

Istio 1.29 introduces alpha support for wildcard hosts in ServiceEntries with `DYNAMIC_DNS` resolution specifically for TLS traffic. This significant enhancement enables routing based on SNI (Server Name Indication) from TLS handshakes without terminating the TLS connection to inspect Host headers.

While this feature has important security implications due to potential SNI spoofing, it provides powerful capabilities for managing external TLS services when used with trusted clients. The feature requires explicit enablement via the `ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS` feature flag and represents an important step forward in external service mesh integration.

### Performance and Observability Improvements

HTTP compression for Envoy metrics is now enabled by default, providing automatic compression (`brotli`, `gzip`, and `zstd`) for the Prometheus stats endpoint based on client `Accept-Header` values. This reduces network overhead for metrics collection while maintaining compatibility with existing monitoring infrastructure.

Baggage based telemetry support has been added in alpha for ambient mesh, particularly benefiting multinetwork deployments. When enabled via the `AMBIENT_ENABLE_BAGGAGE` pilot environment variable, this feature ensures proper source and destination attribution for crossnetwork traffic metrics, improving observability in complex network topologies.

### Simplified Operations and Resource Management

Istio 1.29 introduces pilot resource filtering capabilities through the `PILOT_IGNORE_RESOURCES` environment variable, enabling administrators to deploy Istio as a Gateway API only controller or with specific resource subsets. This is particularly valuable for GAMMA (Gateway API for Mesh Management and Administration) deployments.

Memory management has been improved with `istiod` now automatically setting `GOMEMLIMIT` to 90% of memory limits (via the `automemlimit` library), reducing the risk of OOM kills while maintaining optimal performance. Circuit breaker metrics tracking is now disabled by default, improving proxy memory usage while maintaining the option to enable legacy behavior when needed.

### Plus Much More

- **Enhanced istioctl capabilities**: New `--wait` flag for `istioctl waypoint status`, support for `--all-namespaces` flag, and improved proxy admin port specification
- **Installation improvements**: Configurable terminationGracePeriodSeconds for istio-cni pods, safeguards for gateway deployment controller, and support for custom envoy file flush intervals
- **Traffic management enhancements**: Support for `LEAST_REQUEST` load balancing and circuit breaking in gRPC proxyless clients, improved ambient multicluster ingress routing
- **Telemetry advances**: Source and destination workload identification in waypoint proxy traces, timeout and headers support for Zipkin tracing provider

Read about these and more in the full [release notes](change-notes/).

## Upgrading to 1.29

We would like to hear from you regarding your experience upgrading to Istio 1.29. You can provide feedback in the `#release-1.29` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
