---
title: Announcing Istio 1.8
linktitle: 1.8
subtitle: Major Update
description: Istio 1.8 release announcement.
publishdate: 2020-11-19
release: 1.8.0
skip_list: true
aliases:
    - /news/announcing-1.8
    - /news/announcing-1.8.0
---

We are pleased to announce the release of Istio 1.8!

{{< relnote >}}

This is our fourth and final release for 2020.  We would like to thank the entire Istio team, and especially the release managers [Greg Hanson](https://github.com/GregHanson) from IBM and [Pengyuan Bian](https://github.com/bianpengyuan) from Google.

We continue to navigate in the direction outlined in our [2020 roadmap post](/blog/2020/tradewinds-2020/), improving usability, security, reliability, with focus on multi-cluster meshes and VM workloads. We've introduced new features where necessary to further those goals, but in general, we've been focusing on bug fixes and polish — a theme we'll be continuing into 2021.

Here are some highlights for this release:

## Installing and Upgrading Istio

To codify all the knowledge on how to deploy and upgrade a mesh into software, we built the `IstioOperator` API and two different methods to install it - [istioctl install](/docs/setup/install/istioctl/) and the [Istio operator](/docs/setup/install/operator/). However, some of our users have a deployment workflow for other software based on Helm, and so in this release we've added support for [installing Istio with Helm 3](/docs/setup/install/helm/). This includes both [in-place upgrades](/docs/setup/install/helm/#in-place-upgrade) and [canary deployment of new control planes](/docs/setup/install/helm/#canary-upgrade), after installing 1.8 or later. Helm 3 support is currently Alpha, so please try it out and give your feedback.

Given the several methods of installation that Istio now supports, we've added a [which Istio installation method should I use?](/about/faq/#install-method-selection) FAQ page to help users understand which method may be best suited to their particular use case.

Vendors can now provide optimized profiles for installing Istio on their platform. [Installing Istio on OpenShift](/docs/setup/platform-setup/openshift/) is easier as a result!

## Multi-cluster

If you're serious about reliability, you run more than one Kubernetes cluster. Setting up a mesh across multiple clusters used to take a lot of manual work, and you had a lot of permutations of choice as to how you wanted to run.

In this release, we've written a [new installation guide](/docs/setup/install/multicluster/) which makes it easy to install a mesh that spans multiple clusters, with options depending on if the clusters are [on the same network](/docs/ops/deployment/deployment-models#network-models), and whether you want [multiple control planes](/docs/ops/deployment/deployment-models#control-plane-models).

## Easier to add VMs to your mesh

After making a number of security improvements to VM mesh endpoints in 1.7, we've focused on usability for 1.8. We simplified the installation process, and you can now use `istioctl` to do it. The new [smart DNS proxying](/blog/2020/dns-proxy/) feature lets you resolve mesh services from your VMs, without having to insecurely point them at your cluster DNS server. It also reduces both cluster DNS traffic, and the number of look-ups needed to resolve a service's IP. [Auto registration](/docs/setup/install/virtual-machine/#install-the-istio-control-plane) allows you to tell the VM agent what kind of workload it has, and automatically have `WorkloadEntry` objects created for it when it joins the mesh.

## Security and secrets

Certificates are now sent from Istiod to gateways, rather than them being read directly from Kubernetes. This reduces the privileges of gateways, which are often publicly exposed, improving our "defense in depth" security posture. Additionally, this opens the door for increased performance and lower memory footprint, and additional extensibility in certificate sources.

Istio ships with an out-of-the box Certificate Authority, but many users want to connect to an existing CA. Currently, you have to implement the [Istio CSR API](https://github.com/istio/api/blob/master/security/v1alpha1/ca.proto) and write third-party integrations yourself. In Istio 1.8, we introduced an approach that leverages the [Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/) and can be integrated with any tools that can use that API. Istiod provides the role of Registration Authority (RA) to authenticate and authorize a workload, then creates, approves, and monitors updates for a CSR resource. A third-party tool (e.g., [cert-manager](https://cert-manager.io/)) can then apply the correct signer to create a signed certificate for with the appropriate backend CA. This feature is currently experimental.

## Ease of use

Every release, our User Experience working group is making Istio easier to use.

When things break, we want to make it as easy as possible to help you fix them. In this release, we've introduced `istioctl bug-report`, which gathers debug information and cluster state, to make it easier for the developers or vendor support teams to understand.

`istioctl analyze` can now show where objects don't validate properly, as well as cluster errors. In the case of an error, it will now return the exact line number of the error.

You can now refer to pods indirectly. No more `istioctl dashboard envoy $(kubectl get pods -l app=productpage -o jsonpath="{.items[0].metadata.name}")` - now it's just `istioctl dashboard envoy deployment/productpage`.

## Deprecations

Istio has been saying a long goodbye to the Mixer component, which is now [removed in 1.8](https://github.com/istio/istio/issues/25333). If you still depend on any Mixer functionality, make sure to check the upgrade notes. [You can still use the Mixer from 1.7](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer) - but you should really get on the [WebAssembly train](/blog/2020/wasm-announce/)!

Over the last two releases, we've [changed how we package integrations addons](/blog/2020/addon-rework/) (such as Prometheus, Zipkin, Jaeger and Kiali). Our bundled versions were not as powerful as those provided by the upstream authors, so we moved to providing upstream manifests instead of including them directly. Support for installing addons with Istioctl was deprecated in 1.7 and is removed in 1.8.

## Join the Istio community

Our [Community Meeting](https://github.com/istio/community#community-meeting) happens on the fourth Thursday of the month, at 10 AM Pacific. Due to US Thanksgiving, we've moved this month's meeting forward one week to the 19th of November. If you can't make it, why not join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/)?

Would you like to get involved? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help make Istio even better.
