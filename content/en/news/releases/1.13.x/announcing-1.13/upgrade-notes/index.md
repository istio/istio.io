---
title: Istio 1.13 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.13.0.
publishdate: 2022-02-11
weight: 20
---

When you upgrade from Istio 1.12.x to Istio 1.13.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.13.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.12.x`.

## Health Probes will no longer re-use connections

Health probes using the istio-agent [health probe rewrite](/docs/ops/configuration/mesh/app-health-check/) will
now no longer re-use connections for the probe. This behavior was changed to match probing behavior of Kubernetes',
and may also improve probe reliability for applications using short idle timeouts.

As a result, your application may see more connections (but the same number of HTTP requests) from probes.
For most applications, this will not be noticeably different.

If you need to revert to the old behavior, the `ENABLE_PROBE_KEEPALIVE_CONNECTION=true` environment variable in the proxy may be set.

## Multicluster Secret Authentication Changes

When kubeconfig files are created to [enable endpoint discovery](/docs/setup/install/multicluster/multi-primary/#enable-endpoint-discovery)
in multicluster installations, the authentication methods allowed in the configuration are now limited to improve the security.

The two authentication methods output but `istioctl create-remote-secret` (`oidc` and `token`), are not impacted.
As a result, only users that are creating custom kubeconfig files will be impacted.

A new environment variable, `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS`, is added to Istiod to enable the methods that were removed.
For example, if `exec` authentication is used, set `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS=exec`.

## Port 22 iptables capture changes

In previous versions, port 22 was excluded from iptables capture. This mitigates risk of getting locked out of a VM
when using Istio on VMs. This configuration was hard coded into the iptables logic, meaning there was no way to
capture traffic on port 22.

The iptables logic now no longer has special logic on port 22. Instead, the `istioctl x workload entry configure`
command will automatically configure `ISTIO_LOCAL_EXCLUDE_PORTS` to include port 22. This means that VM users will
continue to have port 22 excluded, while Kubernetes users will have port 22 included now.

If this behavior is undesirable, the port can be explicitly opted out in Kubernetes with the `traffic.sidecar.istio.io/excludeInboundPorts` annotation.
