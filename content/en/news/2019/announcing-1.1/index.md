---
title: Announcing Istio 1.1
subtitle: Major Update
description: Istio 1.1 release announcement.
publishdate: 2019-03-19
attribution: The Istio Team
release: 1.1.0
aliases:
    - /about/notes/1.1
    - /blog/2019/announcing-1.1
    - /news/announcing-1.1
---

We are pleased to announce the release of Istio 1.1!

{{< relnote >}}

Since we released 1.0 back in July, we’ve done a lot of work to help people get
into production. Not surprisingly, we had to do some [patch releases](/news)
(6 so far!), but we’ve also been hard at work adding new features to the
product.

The theme for 1.1 is Enterprise Ready. We’ve been very pleased to see more and
more companies using Istio in production, but as some larger companies tried to
adopt Istio they hit some limits.

One of our prime areas of focus has been [performance and scalability](/docs/concepts/performance-and-scalability/).
As people moved into production with larger clusters running more services at
higher volume, they hit some scaling and performance issues. The
[sidecars](/docs/concepts/traffic-management/#sidecars) took too many resources
and added too much latency. The control plane (especially
[Pilot](/docs/concepts/traffic-management/#pilot)) was overly
resource hungry.

We’ve done a lot of work to make both the data plane and the control plane more
efficient. You can find the details of our 1.1 performance testing and the
results in our updated [performance ans scalability concept](/docs/concepts/performance-and-scalability/).

We’ve done work around namespace isolation as well. This lets you use
Kubernetes namespaces to enforce boundaries of control, and ensures that your
teams cannot interfere with each other.

We have also improved the [multicluster capabilities and usability](/docs/concepts/deployment-models/).
We listened to the community and improved defaults for traffic control and
policy. We introduced a new component called
[Galley](/docs/concepts/what-is-istio/#galley). Galley validates that sweet,
sweet YAML, reducing the chance of configuration errors. Galley will also be
instrumental in [multicluster setups](/docs/setup/install/multicluster/),
gathering service discovery information from each Kubernetes cluster. We are
also supporting additional multicluster topologies including different
[control plane models](/docs/concepts/deployment-models/#control-plane-models)
topologies without requiring a flat network.

There is lots more -- see the [release notes](/news/2019/announcing-1.1/) for complete
details.

There is more going on in the project as well. We know that Istio has a lot of
moving parts and can be a lot to take on. To help address that, we recently
formed a [Usability Working Group](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)
(feel free to join). There is also a lot happening in the [Community
Meeting](https://github.com/istio/community#community-meeting) (Thursdays at
`11 a.m.`) and in the [Working
Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md). And
if you haven’t yet joined the conversation at
[discuss.istio.io](https://discuss.istio.io), head over, log in with your
GitHub credentials and join us!

We are grateful to everyone who has worked hard on Istio over the last few
months -- patching 1.0, adding features to 1.1, and, lately, doing tons of
testing on 1.1. Thanks especially to those companies and users who worked with
us installing and upgrading to the early builds and helping us catch problems
before the release.

So: now’s the time! Grab 1.1, check out [the updated documentation](/docs/),
[install it](/docs/setup/) and...happy meshing!

## Release notes

### Incompatible changes from 1.0

In addition to the new features and improvements listed below, Istio 1.1 has introduced
a number of significant changes from 1.0 that can alter the behavior of applications.
A concise list of these changes can be found in the [upgrade notice](/docs/setup/upgrade/notice).

### Upgrades

We recommend a manual upgrade of the control plane and data plane to 1.1. See
the [upgrades documents](/docs/setup/upgrade/) for more information.

{{< warning >}}
Be sure to check out the [upgrade notice](/docs/setup/upgrade/notice) for a
concise list of things you should know before upgrading your deployment to Istio 1.1.
{{< /warning >}}

### Installation

- **CRD Install Separated from Istio Install**.  Placed Istio’s Custom Resource
  Definitions (CRDs) into the `istio-init` Helm chart. Placing the CRDs in
  their own Helm chart preserves the data continuity of the custom resource
  content during the upgrade process and further enables Istio to evolve beyond
  a Helm-based installation.

- **Installation Configuration Profiles**. Added several installation
  configuration profiles to simplify the installation process using well-known
  and well-tested patterns. Learn more about the better user experience
  afforded by the [installation profile feature](/docs/setup/additional-setup/config-profiles/).

- **Improved Multicluster Integration**. Consolidated the 1.0 `istio-remote`
  chart previously used for
  [multicluster VPN](/docs/setup/install/multicluster/shared-vpn/) and
  [multicluster split horizon](/docs/setup/install/multicluster/shared-gateways/) remote cluster installation
  into the Istio Helm chart simplifying the operational experience.

### Traffic management

- **New `Sidecar` Resource**. The new [sidecar](/docs/concepts/traffic-management/#sidecars) resource
  enables more fine-grained control over the behavior of the sidecar proxies attached to workloads within a namespace.
  In particular it adds support to limit the set of services a sidecar will send traffic to.
  This reduces the amount of configuration computed and transmitted to
  the proxy, improving startup time, resource consumption and control-plane scalability.
  For large deployments, we recommend adding a sidecar resource per namespace. Controls are also
  provided for ports, protocols and traffic capture for advanced use-cases.

- **Restrict Visibility of Services**. Added the new `exportTo` feature which allows
  service owners to control which namespaces can reference their services. This feature is
  added to `ServiceEntry`, `VirtualService` and is also supported on a Kubernetes Service via the
  `networking.istio.io/exportTo` annotation.

- **Namespace Scoping**. When referring to a `VirtualService` in a Gateway we use DNS based name matching
  in our configuration model. This can be ambiguous when more than one namespace defines a virtual service
  for the same host name. To resolve ambiguity it is now possible to explicitly scope these references
  by namespace using a syntax of the form **`[{namespace-name}]/{hostname-match}`** in the `hosts` field.
  The equivalent capability is also available in `Sidecar` for egress.

- **Updates to `ServiceEntry` Resources**. Added support to specify the
  locality of a service and the associated SAN to use with mutual TLS. Service
  entries with HTTPS ports no longer need an additional virtual service to
  enable SNI-based routing.

- **Locality-Aware Routing**. Added full support for routing to services in the
  same locality before picking services in other localities.
  See [Locality Load Balancer Settings](/docs/reference/config/istio.mesh.v1alpha1/#LocalityLoadBalancerSetting)

- **Refined Multicluster Routing**. Simplified the multicluster setup and
  enabled additional deployment modes. You can now connect multiple clusters
  simply using their ingress gateways without needing pod-level VPNs, deploy
  control planes in each cluster for high-availability cases, and span a
  namespace across several clusters to create global namespaces. Locality-aware
  routing is enabled by default in the high-availability control plane
  solution.

- **Istio Ingress Deprecated**. Removed the previously deprecated Istio
  ingress. Refer to the [Securing Kubernetes Ingress with Cert-Manager](/docs/tasks/traffic-management/ingress/ingress-certmgr/)
  example for more details on how to use Kubernetes Ingress resources with
  [gateways](/docs/concepts/traffic-management/#gateways).

- **Performance and Scalability Improvements**. Tuned the performance and
  scalability of Istio and Envoy. Read more about [Performance and Scalability](/docs/concepts/performance-and-scalability/)
  enhancements.

- **Access Logging Off by Default**. Disabled the access logs for all Envoy
  sidecars by default to improve performance.

### Security

- **Readiness and Liveness Probes**. Added support for Kubernetes' HTTP
  [readiness and liveness probes](/faq/security/#k8s-health-checks) when
  mutual TLS is enabled.

- **Cluster RBAC Configuration**. Replaced the `RbacConfig` resource with the
  `ClusterRbacConfig` resource to implement the correct cluster scope. See
  [Migrating `RbacConfig` to `ClusterRbacConfig`](https://archive.istio.io/v1.1/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig).
  for migration instructions.

- **Identity Provisioning Through SDS**. Added SDS support to provide stronger
  security with on-node key generation and dynamic certificate rotation without
  restarting Envoy. See [Provisioning Identity through SDS](/docs/tasks/security/auth-sds)
  for more information.

- **Authorization for TCP Services**. Added support of authorization for TCP
  services in addition to HTTP and gRPC services. See [Authorization for TCP Services](/docs/tasks/security/authz-tcp)
  for more information.

- **Authorization for End-User Groups**. Added authorization based on `groups`
  claim or any list-typed claims in JWT. See [Authorization for groups and list claims](/docs/tasks/security/rbac-groups/)
  for more information.

- **External Certificate Management on Ingress Gateway Controller**.
  Added a controller to dynamically load and rotate external certificates.

- **Custom PKI Integration**. Added Vault PKI integration with support for
  Vault-protected signing keys and ability to integrate with existing Vault PKIs.

- **Customized (non `cluster.local`) Trust Domains**. Added support for
  organization- or cluster-specific trust domains in the identities.

### Policies and telemetry

- **Policy Checks Off By Default**. Changed policy checks to be turned off by
  default to improve performance for most customer scenarios. [Enabling Policy Enforcement](/docs/tasks/policy-enforcement/enabling-policy/)
  details how to turn on Istio policy checks, if needed.

- **Kiali**. Replaced the [Service Graph addon](https://github.com/istio/istio/issues/9066)
  with [Kiali](https://www.kiali.io) to provide a richer visualization
  experience. See the [Kiali task](/docs/tasks/telemetry/kiali/) for more
  details.

- **Reduced Overhead**. Added several performance and scale improvements
  including:

    - Significant reduction in default collection of Envoy-generated
      statistics.

    - Added load-shedding functionality to Mixer workloads.

    - Improved the protocol between Envoy and Mixer.

- **Control Headers and Routing**. Added the option to create adapters to
  influence the headers and routing of an incoming request. See the [Control Headers and Routing](/docs/tasks/policy-enforcement/control-headers)
  task for more information.

- **Out of Process Adapters**. Added the out-of-process adapter functionality
  for production use. As a result, we deprecated the in-process adapter model
  in this release. All new adapter development should use the out-of-process
  model moving forward.

- **Tracing Improvements**. Performed many improvements in our overall tracing
  story:

    - Trace ids are now 128 bit wide.

    - Added support for sending trace data to [LightStep](/docs/tasks/telemetry/distributed-tracing/lightstep/)

    - Added the option to disable tracing for Mixer-backed services entirely.

    - Added policy decision-aware tracing.

- **Default TCP Metrics**. Added default metrics for tracking TCP connections.

- **Reduced Load Balancer Requirements for Addons**. Stopped exposing addons
  via separate load balancers. Instead, addons are exposed via the Istio
  gateway. To expose addons externally using either HTTP or HTTPS protocols,
  please use the [Addon Gateway documentation](/docs/tasks/telemetry/gateways/).

- **Secure Addon Credentials**. Changed storage of the addon credentials.
  Grafana, Kiali, and Jaeger passwords and username are now stored in
  [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
  for improved security and compliance.

- **More Flexibility with `statsd` Collector**. Removed the built-in `statsd`
  collector. Istio now supports bring your own `statsd` for
  improved flexibility with existing Kubernetes deployments.

### Configuration management

- **Galley**. Added [Galley](/docs/concepts/what-is-istio/#galley) as the
  primary configuration ingestion and distribution mechanism within Istio. It
  provides a robust model to validate, transform, and distribute configuration
  states to Istio components insulating the Istio components from Kubernetes
  details. Galley uses the [Mesh Configuration Protocol (MCP)](https://github.com/istio/api/tree/{{< source_branch_name >}}/mcp)
  to interact with components.

- **Monitoring Port**. Changed Galley's default monitoring port from 9093 to
  15014.

### `istioctl` and `kubectl`

- **Validate Command**. Added the [`istioctl validate`](/docs/reference/commands/istioctl/#istioctl-validate)
  command for offline validation of Istio Kubernetes resources.

- **Verify-Install Command**. Added the [`istioctl verify-install`](/docs/reference/commands/istioctl/#istioctl-verify-install)
  command to verify the status of an Istio installation given a specified
  installation YAML file.

- **Deprecated Commands**. Deprecated the `istioctl create`, `istioctl
  replace`, `istioctl get`, and `istioctl delete` commands. Use the
  [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl)
  equivalents instead. Deprecated the `istioctl gen-deploy` command too. Use a
  [`helm template`](/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template)
  instead. Release 1.2 will remove these commands.

- **Short Commands**. Included short commands in `kubectl` for gateways,
  virtual services, destination rules and service entries.
