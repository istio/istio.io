---
title: Announcing Istio 1.2
subtitle: Major Update
description: Istio 1.2 release announcement.
publishdate: 2019-06-18
attribution: The Istio Team
release: 1.2.0
aliases:
    - /about/notes/1.2
    - /blog/2019/announcing-1.2
---

We are pleased to announce the release of Istio 1.2!

{{< relnote >}}

The theme of 1.2 is Predictable Releases - predictable in quality (we want
every release to be a good release) as well as in time (we want to be able
to ship on well known schedules).

As nearly anyone using Istio 1.0 noticed, it took us a long time to get 1.1
out. Far too long. One of the reasons was that we needed to do some work on
our testing and infrastructure -- it was simply far too manual a process to
build, test and release. Because of that, 1.2 focuses on improving the
stability of these new features, and improving general product health.

In order to make release quality and timing predictable, we declared a
"Code Mauve",  meaning that we would spend the next iteration focusing on
project infrastructure. As a result, we’ve been investing a ton of effort
in our build, test and release machinery.

We formed 3 new teams (GitHub Workflow, Source Organization, Testing
Methodology, and Build & Release Automation). Each had a set of issues to
take on and a set of exit criteria. Code Mauve isn’t over yet, in fact we
expect it to go
on for some time.   We’re putting in place the infrastructure to measure the
metrics each team decided on (paraphrasing Peter Drucker: if you can’t
measure it, you can’t manage it).

You might have noticed that the [patch releases](/news/) for 1.1 have
been coming fast and furious.

In order to get features in the hands of our customers and users as soon as
possible, most of the new features from the last three months have been
delivered in 1.1.x releases. With 1.2, those features are now officially
part of the release.

We're seeing early results from the usability group. In the release notes,
you'll find that you can now set log levels for the control plane and the
data plane globally.  You can use [`istioctl`](/docs/reference/commands/istioctl) to validate that your Kubernetes
installation meets Istio's requirements. And the new
`traffic.sidecar.istio.io/includeInboundPorts` annotation to eliminate the
need for service owner to declare `containerPort` in the deployment yaml.

Some of the features have matured as well. The following features have
progressed from Beta status
to Stable:  SNI at ingress, distributed tracing, and service tracing. The
following features have reached beta status: cert management on ingress,
configuration resource validation, and configuration processing with Galley.
We know there are lots of feature requests outstanding, and we have an
exciting roadmap (watch for a forthcoming post from the TOC on that). The
work we have done in this release has taken care of some technical debt which
will help us get those features out reliably in future.

As always, there is also a lot happening in the [Community
Meeting](https://github.com/istio/community#community-meeting) (Thursdays at
`11 a.m. Pactific`) and in the [Working
Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md). And
if you haven’t yet joined the conversation at
[discuss.istio.io](https://discuss.istio.io), head over, log in with your
GitHub credentials and join us!

## Release notes

### General

- **Added** `traffic.sidecar.istio.io/includeInboundPorts` annotation to eliminate the need for service owner to declare `containerPort` in the deployment yaml file.  This will become the default in a future release.
- **Added** IPv6 experimental support for Kubernetes clusters.

### Traffic management

- **Improved** [locality based routing](/docs/ops/traffic-management/locality-load-balancing/) in multicluster environments.
- **Improved** outbound traffic policy in [`ALLOW_ANY` mode](/docs/reference/config/installation-options/#global-options). Traffic for unknown HTTP/HTTPS hosts on an existing port will be [forwarded as is](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services). Unknown traffic will be logged in Envoy access logs.
- **Added** support for setting HTTP idle timeouts to upstream services.
- **Improved** Sidecar support for [NONE mode](/docs/reference/config/networking/v1alpha3/sidecar/#CaptureMode) (without iptables) .
- **Added** ability to configure the [DNS refresh rate](/docs/reference/config/installation-options/#global-options) for sidecar Envoys, to reduce the load on the DNS servers.
- **Graduated** [Sidecar API](/docs/reference/config/networking/v1alpha3/sidecar/) from Alpha to Alpha API and Beta runtime.

### Security

- **Improved** extend the default lifetime of self-signed Citadel root certificates to 10 years.
- **Added** Kubernetes health check prober rewrite per deployment via `sidecar.istio.io/rewriteAppHTTPProbers: "true"` in the `PodSpec` [annotation](/docs/ops/app-health-check/#use-annotations-on-pod).
- **Added** support for configuring the secret paths for Istio mutual TLS certificates. Refer [here](https://github.com/istio/istio/issues/11984) for more details.
- **Added** support for [PKCS 8](https://en.wikipedia.org/wiki/PKCS_8) private keys for workloads, enabled by the flag `pkcs8-keys` on Citadel.
- **Improved** JWT public key fetching logic to be more resilient to network failure.
- **Fixed** [SAN](https://tools.ietf.org/html/rfc5280#section-4.2.1.6) field in workload certificates is set as `critical`. This fixes the issue that some custom certificate verifiers cannot verify Istio certificates.
- **Fixed** mutual TLS probe rewrite for HTTPS probes.
- **Graduated** [SNI with multiple certificates support at ingress gateway](/docs/reference/config/networking/v1alpha3/gateway/) from Alpha to Stable.
- **Graduated** [certification management on Ingress Gateway](/docs/tasks/traffic-management/ingress/secure-ingress-sds/) from Alpha to Beta.

### Telemetry

- **Added** Full support for control over Envoy stats generation, based on stats prefixes, suffixes, and regular expressions through the use of annotations.
- **Changed** Prometheus generated traffic is excluded from metrics.
- **Added** support for sending traces to Datadog.
- **Graduated** [distributed tracing](/docs/tasks/observability/distributed-tracing/) from Beta to Stable.

### Policy

- **Fixed** [Mixer based](https://github.com/istio/istio/issues/13868)TCP Policy enforcement.
- **Graduated** [Authorization (RBAC)](/docs/reference/config/authorization/istio.rbac.v1alpha1/) from Alpha to Alpha API and Beta runtime.

### Configuration management

- **Improved** validation of Policy & Telemetry CRDs.
- **Graduated** basic configuration resource validation from Alpha to Beta.

### Installation and upgrade

- **Updated** default proxy memory limit size(`global.proxy.resources.limits.memory`) from `128Mi` to `1024Mi` to ensure proxy has sufficient memory.
- **Added** pod [anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) and [toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) support to all of our control plane components.
- **Added** `sidecarInjectorWebhook.neverInjectSelector` and `sidecarInjectorWebhook.alwaysInjectSelector` to allow users to further refine whether workloads should have sidecar automatically injected or not, based on label selectors.
- **Added** `global.logging.level` and `global.proxy.logLevel` to allow users to easily configure logs for control plane and data plane components globally.
- **Added** support to configure the Datadog location via [`global.tracer.datadog.address`](/docs/reference/config/installation-options/#global-options).
- **Removed** Previously [deprecated]( https://discuss.istio.io/t/deprecation-notice-custom-mixer-adapter-crds/2055) Adapter and Template CRDs are disabled by default. Use  `mixer.templates.useTemplateCRDs=true` and `mixer.adapters.useAdapterCRDs=true` install options to re-enable them.

Refer to the [installation option change page](/docs/reference/config/installation-options-changes/) to view the complete list of changes.

### `istioctl` and `kubectl`

- **Graduated** `istioctl verify-install` out of experimental.
- **Improved** `istioctl verify-install` to validate if a given Kubernetes environment meets Istio's prerequisites.
- **Added** auto-completion support to `istioctl`.
- **Added** `istioctl experimental dashboard` to allow users to easily open the web UI of any Istio addons.
- **Added** `istioctl x` alias to conveniently run `istioctl experimental` command.
- **Improved** `istioctl version` to report both Istio control plane and `istioctl` version info by default.
- **Improved** `istioctl validate` to validate Mixer configuration and supports deep validation with referential integrity.

### Others

- **Added** [Istio CNI support](/docs/setup/additional-setup/cni/) to setup sidecar network redirection and remove the use of `istio-init` containers requiring `NET_ADMIN` capability.
- **Added** a new experimental ['a-la-carte' Istio installer](https://github.com/istio/installer/wiki) to enable users to install and upgrade Istio with desired isolation and security.
- **Added** the [DNS-discovery](https://github.com/istio-ecosystem/dns-discovery) and [iter8](https://github.com/istio-ecosystem/iter8) in [Istio ecosystem](https://github.com/istio-ecosystem).
- **Added** [environment variable and configuration file support](https://docs.google.com/document/d/1M-qqBMNbhbAxl3S_8qQfaeOLAiRqSBpSgfWebFBRuu8/edit) for configuring Galley, in addition to command-line flags.
- **Added** [ControlZ](/docs/ops/troubleshooting/controlz/) support to visualize the state of the MCP Server in Galley.
- **Added** the [`enableServiceDiscovery` command-line flag](/docs/reference/commands/galley/#galley-server) to control the service discovery module in Galley.
- **Added** `InitialWindowSize` and `InitialConnWindowSize` parameters to Galley and Pilot to allow fine-tuning of MCP (gRPC) connection settings.
- **Graduated** configuration processing with Galley from Alpha to Beta.
