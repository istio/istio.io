---
title: Announcing Istio 1.17
linktitle: 1.17
subtitle: Major Update
description: Istio 1.17 release annoucement.
publishdate: 2023-02-14
release: 1.17.0
aliases:
    - /news/announcing-1.17
    - /news/announcing-1.17.0
---

We are pleased to announce the release of Istio 1.17. This is the first Istio release of 2023. We would like to thank the entire Istio community for helping get the 1.17.0 release published. We would like to thank the Release Managers for this release, `Mariam John` from IBM, `Paul Merrison` from Tetrate and `Kalya Subramanian` from Microsoft. The release managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback, reviews, community testing and for all your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.17.0 is officially supported on Kubernetes versions `1.23` to `1.26`.
{{< /tip >}}

## What's new

Since the 1.16 release we’ve added some important new features and marked some of our existing features as Beta signaling that they’re ready for production use. Here are some highlights:

### Canary upgrade and revision tags were promoted to Beta

Basic support for upgrading the service mesh following a canary pattern using revisions was introduced in the Istio 1.6 release. Using this approach, you can run multiple control planes side-by-side without impacting an existing deployment and slowly migrate workloads from the old control plane to the new. In Istio 1.10, revision tags was introduced as an improvement to canary upgrades to help reduce the number of changes an operator has to make to use revisions, and safely upgrade an Istio control plane. This is a very widely adopted and used feature by our users in production. All integration tests and end-to-end tests covering documentation have been completed for this feature to graduate to Beta.

### Helm installation was promoted to Beta

Helm based installation of Istio, first introduced in Istio 0.4, has graduated to Beta. It is one of the most widely used methods to install Istio in production. All requirements to promote this feature to Beta were completed in this release including updating integration tests to use helm charts for install/upgrade, updating Helm integration tests and documenting advanced Helm chart customization and attributes in `values.yaml`.

### Upgraded support for the Kubernetes Gateway API

Istio's implementation of the [Gateway API](https://gateway-api.sigs.k8s.io/) has been moved to, and is now fully compliant with, the latest version of the API (0.6.1).

### Istio dual stack support

`IPv6` support in dual stack mode was added in Kubernetes in version 1.16 and graduated to stable in the 1.22 release. The basic foundation to enable dual stack support in Istio started in the Istio 1.16 release. In the Istio 1.17 release, the following capabilities were added to enable dual support in Istio:

- Enable users to deploy a service with a single or dual stack IP family on a dual stack cluster. For instance, a user can separately deploy 3 services with IPv4 only, IPv6 only and dual stack IP families on a dual stack Kubernetes cluster, enabling these services to be accessible to each other via sidecar.
- Added extra source address configuration for gateway's listeners to support dual stack mode, so that IPv4 and IPV6 clients outside of the service mesh can access the gateway. This is applicable only for auto deployed gateways via the gateway controller, and the native gateway of Kubernetes should already support dual stack.

This is an experimental feature and is currently under [active development]( https://github.com/istio/istio/issues/40394).

### Added support for filter patching in Istio

Added support for listener filter patching which enables users to perform `ADD`, `REMOVE`, `REPLACE`, `INSERT_FIRST`, `INSERT_BEFORE`, `INSERT_AFTER` operations for `LISTENER_FILTER` in Istio's `EnvoyFilter` resource.

### Added support for using `QuickAssist Technology` (QAT) `PrivateKeyProvider` in Istio

Added support for using `QuickAssist Technology` (QAT) `PrivateKeyProvider` in SDS and added corresponding configuration for selecting QAT private key provider for gateways and sidecars. This builds on the fact that Envoy added [support for QAT]( https://github.com/envoyproxy/envoy/issues/21531) as another private key provider in addition to [CryptoMB]( https://istio.io/latest/blog/2022/cryptomb-privatekeyprovider/). For more information on QAT, you can refer [here]( https://www.intel.com/content/www/us/en/developer/articles/technical/envoy-tls-acceleration-with-quickassist-technology.html).

### Enhancements to the `RequestAuth` API

Added support to copy JWT claims to HTTP request headers in the `RequestAuth` API.

### Enhancements to the `istioctl` command

Added a number of enhancements to the istioctl command including adding:

- `revision` flag to `istioctl admin log`, to switch controls between Istiod’s
- `istioctl proxy-config ecds`, to support retrieving typed extension configuration from Envoy for a specified pod
- `istioctl proxy-config log`, to set proxy log level for all pods in a deployment
- `--revision` flag to `istioctl analyze`, to specify a specific revision

## Join us at Istio Day, 2023

[Istio Day Europe 2023](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/), set for April 18th, is the first Istio conference hosted by CNCF. It will be a Day 0 event co-located with [KubeCon + CloudNativeCon Europe 2023](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe). This is a great opportunity for community members from across the globe to connect with Istio’s ecosystem of developers, partners and vendors. For more information related to the event, visit the [conference website](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/). We hope you can join us at Istio Day Europe.

## Upgrading to 1.17

We would like to hear from you regarding your experience upgrading to Istio 1.17. Please take a few minutes to respond to a [brief survey](https://forms.gle/99uiMML96AmsXY5d6) and let us know how we are doing and what we can do to improve.

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).
Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
