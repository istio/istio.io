---
title: Istio 1.1
publishdate: 2019-03-20
icon: notes
---

We're proud to release Istio 1.1! We have spent the last 8 months making some significant improvements to the overall
product, with fixes & features from Google, IBM, VMware, Huawei, RedHat, Cisco, SAP, Salesforce, Pivotal, SUSE, Datadog
and LightStep, to name a few. Special thanks to all of our end-users for providing feedback, feature requests and
testing the release candidates at various scales.

These release notes describe what's different between Istio 1.0.6 and Istio 1.1.

{{< relnote_links >}}

TODO: Need to include anything mentioned as explicit necessary upgrade steps in `/docs/setup/kubernetes/upgrade`
TODO: Need to have an explicit section on everything that's being deprecated.

## Upgrades

- We recommend a manual upgrade of control plane and data plane to 1.1.  Please reference
  [upgrades]((/docs/setup/kubernetes/upgrade/) to upgrade your Istio control and data plane.

## Traffic management

- **New `Sidecar` Resource**. Added support to limit the set of services visible to sidecar proxies in a given namespace using the `Sidecar` resource.
This limit reduces the amount of configuration computed and transmitted to the proxy. On large clusters, we recommend adding
a sidecar resource per namespace.

- **Restrict Visibility of Networking Resources**. Added the new `exportTo` field to all networking resources.
The field currently takes only the following values:

    - `.` Indicates the same namespace as the resource: makes the network resources visible only within their own namespace.

    - `*` Indicates all namespaces and is the default value: makes the network resources visible within all namespaces.

- **Updates to `ServiceEntry` Resources**. Added support to specify the locality of a service
and the associated SAN to use with mutual TLS. Service entries with HTTPS ports no
longer need an additional virtual service to enable SNI-based routing.

- **Locality-Aware Routing**. Added full support for routing to services in the same locality before picking services in other localities.

- **Refined Multicluster Routing**. Simplified the multicluster setup and enabled additional deployment modes. You can now connect multiple
clusters simply using their ingress gateways without needing pod-level VPNs, deploy control planes in each cluster for high-availability cases, and
span a namespace across several clusters
to create global namespaces. Locality-aware routing is enabled by default in the HA control plane solution.

- **Istio Ingress Deprecated**. Removed the previously deprecated Istio ingress. Refer to the
[Securing Kubernetes Ingress with Cert-Manager](/docs/examples/advanced-gateways/ingress-certmgr/) example for more details on how
to use Kubernetes Ingress resources with [gateways](/docs/concepts/traffic-management/#gateways).

- **Behavioral changes**.
    - Outbound traffic policy is set to `ALLOW_ANY` by default. As a result, traffic to unknown ports will be forwarded as-is. Traffic to known ports (e.g., port 80) will be matched with one of the services in the system and forwarded accordingly.
    - Destination rule resolution order has been set. For a given sidecar, when routing to a particular service, destination rules for the target service in the same namespace as the source sidecar will first be considered, followed by destination rules in the target service’s namespace, and finally followed by destination rules in `configRootNamespace` if defined or any other namespace if `configRootNamespace` is not defined.

## Security

- **Readiness and Liveness Probes**. Added support for Kubernetes' HTTP [readiness and liveness probes when mutual TLS is enabled](/help/faq/security/#k8s-health-checks).

- **Cluster RBAC Configuration**.  Replaced the `RbacConfig` resource with the `ClusterRbacConfig` resource to implement the correct cluster scope.
See [Migrating `RbacConfig` to `ClusterRbacConfig`](/docs/setup/kubernetes/upgrade/#migrating-from-rbacconfig-to-clusterrbacconfig).
for migration instructions.

- **Identity Provisioning Through SDS**. Provides stronger security with on-node key generation and dynamic certificate rotation without restarting Envoy.
See [Provisioning Identity through SDS](/docs/tasks/security/auth-sds) for more information.

- **Authorization for TCP Services**. Supports authorization for TCP services in addition to HTTP and gRPC services.
See [Authorization for TCP Services](/docs/tasks/security/authz-tcp) for more information.

- **Authorization for End-User Groups**. Allows authorization based on `groups` claim or any list-typed claims in JWT.
See [Authorization for groups and list claims](/docs/tasks/security/rbac-groups/) for more information.

- **External Certificate Management on Ingress Gateway Controller**. Dynamically loads and rotates external certificates.

- **Vault PKI Integration**. Provides stronger security with Vault-protected signing keys and facilitates integration with existing Vault PKIs.
See [Istio Vault CA Integration](/docs/tasks/security/vault-ca) for more information.

- **Customized (non `cluster.local`) Trust Domains**. Supports organization- or cluster-specific trust domains in the identities.

- TBD: How about adding [11667](https://github.com/istio/istio/issues/11667) as well? As this is also a significant feature for security which can enable end user to set
different CA and Certs for different namespaces.

## Policies and telemetry

- **Policy Checks Off By Default**. Changed policy checks to be turned off by default which improves performance for most customer scenarios.
[Enabling Policy Enforcement](/docs/tasks/policy-enforcement/enabling-policy/) details how to turn on Istio policy checks, if needed.

- **Kiali**. Replaced the [Service Graph addon](https://github.com/istio/istio/issues/9066) with [Kiali](https://www.kiali.io) to provide
a richer visualization experience. See the [Kiali task](/docs/tasks/telemetry/kiali/) for more details.

- **Reduced Overhead**. Added several performance and scale improvements including:

    - Significant reduction in default collection of Envoy-generated statistics.

    - Added load-shedding functionality to Mixer workloads.

    - Improved the protocol between Envoy and Mixer.

- **Control Headers and Routing**. Added the option to create adapters to influence
an incoming request's headers and routing. See [Control Headers and Routing](/docs/tasks/policy-enforcement/control-headers) task
for more information.

- **Out of Process Adapters**. The out-of-process adapter functionality is now ready for production use. As a result, the in-process
adapter model is being deprecated in this release. All new adapter development should use the out-of-process model moving forward.

- **Tracing Improvements**. There have been many improvements in our overall tracing story:

    - Trace ids are now 128 bit wide.

    - Added support for sending trace data to [LightStep](/docs/tasks/telemetry/distributed-tracing/lightstep/)

    - Added the option to disable tracing for Mixer-backed services entirely.

    - Added policy decision-aware tracing.

- **Default TCP Metrics**. Added default metrics for tracking TCP connections.

## Configuration management

- **Galley**. Added [Galley](/docs/concepts/what-is-istio/#galley) as the primary configuration ingestion and distribution mechanism within Istio. It provides
a robust model to validate, transform, and distribute configuration state to Istio components insulating the Istio components
from Kubernetes details. Galley uses the [Mesh Configuration Protocol (MCP)](https://github.com/istio/api/tree/{{< source_branch_name >}}/mcp) to interact with components.

- **Monitoring Port**. Changed Galley's default monitoring port from 9093 to 15014.

## `istioctl` and `kubectl`

- **Validate Command**. Added the [`istioctl validate`](/docs/reference/commands/istioctl/#istioctl-validate)
command for offline validation of Istio Kubernetes resources.

- **Verify-Install Command**. Added the [`istioctl experimental verify-install`](/docs/reference/commands/istioctl/#istioctl-experimental-verify-install) command to verify the status of an
Istio installation given a specified installation YAML file.

- **Deprecated Commands**. Deprecated the `istioctl create`, `istioctl replace`, `istioctl get`, and `istioctl delete` commands. Use the [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl) equivalents instead.
Deprecated the `istioctl gen-deploy` command too. Use a [`helm template`](/docs/setup/kubernetes/install/helm/#option-1-install-with-helm-via-helm-template) instead.
These commands will be removed in the 1.2 release.

- **Short Commands**. Included short commands in `kubectl` for gateways, virtual services, destination rules and service entries.
