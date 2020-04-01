---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.5.
weight: 20
---

This page describes changes you need to be aware of when upgrading from
Istio 1.4.x to 1.5.x.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.4.

## Control Plane Restructuring

In Istio 1.5, we have moved towards a new deployment model for the control plane, with many components consolidated. The following describes where various functionality has been moved to.

### Istiod

In Istio 1.5, there will be a new deployment, `istiod`. This component is the core of the control plane, and will handle configuration and certificate distribution, sidecar injection, and more.

### Sidecar injection

Previously, sidecar injection was handled by a mutating webhook that was processed by a deployment named `istio-sidecar-injector`. In Istio 1.5, the same mutating webhook remains, but it will now point to the `istiod` deployment. All injection logic remains the same.

### Galley

* Configuration Validation - this functionality remains the same, but is now handled by the `istiod` deployment.
* MCP Server - the MCP server has been disabled by default. For most users, this is an implementation detail. If you depend on this functionality, you will need to run the `istio-galley` deployment.
* Experimental features (such as configuration analysis) - These features will require the `istio-galley` deployment.

### Citadel

Previously, Citadel served two functions: writing certificates to secrets in each namespace, and serving secrets to the `nodeagent` over `gRPC` when SDS is used. In Istio 1.5, secrets are no longer written to each namespace. Instead, they are only served over gRPC. This functionality has been moved to the `istiod` deployment.

### SDS Node Agent

The `nodeagent` deployment has been removed. This functionality now exists in the Envoy sidecar.

### Sidecar

Previously, the sidecar was able to access certificates in two ways: through secrets mounted as files, or over SDS (through the `nodeagent` deployment). In Istio 1.5, this has been simplified. All secrets will be served over a locally run SDS server. For most users, these secrets will be fetched from the `istiod` deployment. For users with a custom CA, file mounted secrets can still be used, however, these will still be served by the local SDS server. This means that certificate rotations will no longer require Envoy to restart.

### CNI

There have been no changes to the deployment of `istio-cni`.

### Pilot

The `istio-pilot` deployment has been removed in favor of the `istiod` deployment, which contains all functionality that Pilot once had. For backwards compatibility, there are still some references to Pilot.

## Mixer deprecation

Mixer, the process behind the `istio-telemetry` and `istio-policy` deployments, has been deprecated with the 1.5 release. `istio-policy` was disabled by default since Istio 1.3 and `istio-telemetry` is disabled by default in Istio 1.5.

Telemetry is collected using an in-proxy extension mechanism (Telemetry V2) that does not require Mixer.

If you depend on specific Mixer features like out of process adapters, you may re-enable Mixer. Mixer will continue receiving bug fixes and security fixes until Istio 1.7.
Many features supported by Mixer have alternatives as specified in the [Mixer Deprecation](https://tinyurl.com/mixer-deprecation) document including the [in-proxy extensions](https://github.com/istio/proxy/tree/master/extensions) based on the WebAssembly sandbox API.

If you rely on a Mixer feature that does not have an equivalent, we encourage you to open issues and discuss in the community.

Please check [Mixer Deprecation](https://tinyurl.com/mixer-deprecation) notice for details.

### Feature gaps between Telemetry V2 and Mixer Telemetry

* Out of mesh telemetry is not supported. Some telemetry is missing if the traffic source or destination is not sidecar injected.
* Egress gateway telemetry is [not supported](https://github.com/istio/istio/issues/19385).
* TCP telemetry is only supported with `mtls`.
* Black Hole telemetry for TCP and HTTP protocols is not supported.
* Histogram buckets are [significantly different](https://github.com/istio/istio/issues/20483) than Mixer Telemetry and cannot be changed.

## Authentication policy

Istio 1.5 introduces [`PeerAuthentication`](/docs/reference/config/security/peer_authentication/) and [`RequestAuthentication`](/docs/reference/config/security/request_authentication/), which are replacing the alpha version of the Authentication API. For more information about how to use the new API, see the [authentication policy](/docs/tasks/security/authentication/authn-policy) tutorial.

* After you upgrade Istio, your alpha authentication policies remain in place and being used. You can gradually replace them with the equivalent `PeerAuthentication` and `RequestAuthentication`. The new policy will take over the old policy in the scope it is defined. We recommend starting with workload-wide (the most specific scope), then namespace-wide, and finally mesh-wide.
* After you replace policies for workload, namespace, and mesh, you can safely remove the alpha authentication policies. To delete the alpha policies, use this command:

{{< text bash >}}
$ kubectl delete policies.authentication.istio.io --all-namespaces --all
$ kubectl delete meshpolicies.authentication.istio.io --all
{{< /text >}}

## Istio workload key and certificate provisioning

* We have stabilized the SDS certificate and key provisioning flow. Now the Istio workloads are using SDS to provision certificates. The secret volume mount approach is deprecated.
* Please note when mutual TLS is enabled, Prometheus deployment needs to be manually modified to monitor the workloads. The details are described in this [issue](https://github.com/istio/istio/issues/21843). This is not required in 1.5.1.

## Automatic mutual TLS

Automatic mutual TLS is now enabled by default. Traffic between sidecars is automatically configured as mutual TLS. You can disable this explicitly if you worry about the encryption overhead by adding the option `-- set values.global.mtls.auto=false` during install. For more details, refer to [automatic mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls).

## Control plane security

As part of the Istiod effort, we have changed how proxies securely communicate with the control plane. In previous versions, proxies would connect to the control plane securely when the setting `values.global.controlPlaneSecurityEnabled=true` was configured, which was the default for Istio 1.4. Each control plane component ran a sidecar with Citadel certificates, and proxies connected to Pilot over port 15011.

In Istio 1.5, this is no longer the recommended or default way to connect the proxies with the control plane; instead, DNS certificates, which can be signed by Kubernetes or Istiod, will be used to connect to Istiod over port 15012.

Note: despite the naming, in Istio 1.5 when `controlPlaneSecurityEnabled` is set to `false`, communication between the control plane will be secure by default.

## Multicluster setup

{{< warning >}}
We recommend that you **do not upgrade** to Istio 1.5.0 if you are using a multicluster setup.

Istio 1.5.0 multicluster setup has several known issues ([27102](https://github.com/istio/istio/issues/21702), [21676](https://github.com/istio/istio/issues/21676)) that make it unusable in both shared control plane and replicated control plane deployments. These issues will be resolved in Istio 1.5.1.
{{< /warning >}}

## Helm upgrade

If you used `helm upgrade` to update your cluster to newer Istio versions, we recommend you to switch to use [`istioctl upgrade`](https://archive.istio.io/v1.5/docs/setup/upgrade/istioctl-upgrade/) or follow the [helm template](/docs/setup/upgrade/cni-helm-upgrade/) steps.

