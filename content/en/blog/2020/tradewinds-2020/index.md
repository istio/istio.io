---
title: Istio in 2020 - Following the Trade Winds
subtitle: Istio continues to get faster and easier to use in the 2020 roadmap
description: A vision statement and roadmap for Istio in 2020.
publishdate: 2020-03-03
attribution: Istio Team
keywords: [roadmap,security,performance,operator]
---

Istio solves real problems that people encounter running microservices. Even
[very early pre-release versions](https://kubernetespodcast.com/episode/016-descartes-labs/)
helped users debug the latency in their architecture, increase the reliability
of services, and transparently secure traffic behind the firewall.

Last year, the Istio project experienced major growth. After a 9-month gestation
before the 1.1 release in Q1, we set a goal of having a quarterly release
cadence. We knew it was important to deliver value consistently and predictably.
With three releases landing in the successive quarters as planned, we are proud
to have reached that goal.

During that time, we improved our build and test infrastructure, resulting in
higher quality and easier release cycles. We doubled down on user experience,
adding many commands to make operating and debugging the mesh easier. We also
saw tremendous growth in the number of developers and companies contributing to
the product - culminating in us being
[#4 on GitHub's top ten list of fastest growing projects](https://octoverse.github.com/#fastest-growing-oss-projects-by-contributors)!

We have ambitious goals for Istio in 2020 and there are many major efforts
underway, but at the same time we strongly believe that good infrastructure
should be "boring." Using Istio in production should be a seamless experience;
performance should not be a concern, upgrades should be a non-event and complex
tasks should be automated away. With our investment in a more powerful
extensibility story we think the pace of innovation in the service mesh space
can increase while Istio focuses on being gloriously dull.
More details on our major efforts in 2020 below.

## Sleeker, smoother and faster

Istio provided for extensibility from day one, implemented by a component called
Mixer. Mixer is a platform that allows custom
[adapters](/docs/reference/config/policy-and-telemetry/mixer-overview/#adapters)
to act as an intermediary between the data plane and the backends you use for
policy or telemetry. Mixer necessarily added overhead to requests because it
required extensions to be out-of-process. So, we're moving to a model that
enables extension directly in the proxies instead.

Most of Mixer’s use cases for policy enforcement are already addressed with
Istio's [authentication](/docs/concepts/security/#authentication-policies)
and [authorization](/docs/concepts/security/#authorization) policies, which
allow you to control workload-to-workload and end-user-to-workload authorization
directly in the proxy. Common monitoring use cases have already moved into the
proxy too - we have
[introduced in-proxy support](/docs/reference/config/telemetry/metrics)
for sending telemetry to Prometheus and Stackdriver.

Our benchmarking shows that the new telemetry model reduces our latency
dramatically and gives us industry-leading performance, with 50% reductions in
both latency and CPU consumption.

## A new model for Istio extensibility

The model that replaces Mixer uses extensions in Envoy to provide even more
capability. The Istio community is leading the implementation of a
[WebAssembly](https://webassembly.org/) (Wasm) runtime in Envoy, which lets us
implement extensions that are modular, sandboxed, and developed in one of
[over 20 languages](https://github.com/appcypher/awesome-wasm-langs). Extensions
can be dynamically loaded and reloaded while the proxy continues serving
traffic. Wasm extensions will also be able to extend the platform in ways that
Mixer simply couldn’t.  They can act as custom protocol handlers and transform
payloads as they pass through Envoy —  in short they can do the same things as
modules built into Envoy.

We're working with the Envoy community on ways to discover and distribute these
extensions. We want to make WebAssembly extensions as easy to install and run as
containers. Many of our partners have written Mixer adapters, and together we
are getting them ported to Wasm. We are also developing guides and codelabs on
how to write your own extensions for custom integrations.

By changing the extension model, we were also able to remove dozens of CRDs.
You no longer need a unique CRD for every piece of software you integrate with
Istio.

Installing Istio 1.5 with the 'preview' configuration profile won't install
Mixer. If you upgrade from a previous release, or install the 'default' profile,
we still keep Mixer around, to be safe. When using Prometheus or Stackdriver for
metrics, we recommend you try out the new mode and see how much your performance
improves.

You can keep Mixer installed and enabled if you need it. Eventually Mixer will
become a separately released add-on to Istio that is part of the
[istio-ecosystem](https://github.com/istio-ecosystem/).

## Fewer moving parts

We are also simplifying the deployment of the rest of the control plane. To
that end, we combined several of the control plane components into a single
component: Istiod. This binary includes the features of Pilot, Citadel, Galley,
and the sidecar injector. This approach improves many aspects of installing and
managing Istio -- reducing installation and configuration complexity,
maintenance effort, and issue diagnosis time while increasing responsiveness.
Read more about Istiod in
[this post from Christian Posta](https://blog.christianposta.com/microservices/istio-as-an-example-of-when-not-to-do-microservices/).

We are shipping Istiod as the default for all profiles in 1.5.

To reduce the per-node footprint, we are getting rid of the node-agent, used to
distribute certificates, and moving its functionality to the istio-agent, which
already runs in each Pod. For those of you who like pictures we are moving from
this ...

{{< image width="75%"
    link="./architecture-pre-istiod.svg"
    alt="Istio architecture with Pilot, Mixer, Citadel, Sidecar injector"
    caption="The Istio architecture today"
    >}}

to this...

{{< image width="75%"
    link="./architecture-post-istiod.svg"
    alt="Istio architecture with Istiod"
    caption="The Istio architecture in 2020"
    >}}

In 2020, we will continue to invest in onboarding to achieve our goal of a
"zero config" default that doesn’t require you to change any of your
application's configuration to take advantage of most Istio features.

## Improved lifecycle management

To improve Istio’s life-cycle management, we moved to an
[operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)-based
installation. We introduced the
**[IstioOperator CRD and two installation modes](/docs/setup/install/istioctl/)**:

- Human-triggered: use istioctl to apply the settings to the cluster.
- Machine-triggered: use a controller that is continually watching for changes
in that CRD and affecting those in real time.

In 2020 upgrades will getting easier too.  We will add support for "canarying"
new versions of the Istio control plane, which allows you to run a new version
alongside the existing version and gradually switch your data plane over to use
the new one.

## Secure By Default

Istio already provides the fundamentals for strong service security: reliable
workload identity, robust access policies and comprehensive audit logging. We’re
stabilizing APIs for these features; many Alpha APIs are moving to Beta in 1.5,
and we expect them to all be v1 by the end of 2020. To learn more about the
status of our APIs, see our
[features page](/about/feature-stages/#istio-features).

Network traffic is also becoming more secure by default. After many users
enabled it in preview,
[automated rollout of mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls)
is becoming the recommended practice in Istio 1.5.

In addition we will make Istio require fewer privileges and simplify its
dependencies which in turn make it a more robust system. Historically, you had
to mount certificates into Envoy using Kubernetes Secrets, which were mounted as
files into each proxy.  By leveraging the
[Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret)
we can distribute these certificates securely without concern of them being
intercepted by other workloads on the machine. This mode will become the default
in 1.5.

Getting rid of the node-agent not only simplifies the deployment, but also
removes the requirement for a cluster-wide `PodSecurityPolicy`, further
improving the security posture of your cluster.

## Other features

Here's a snapshot of some more exciting things you can expect from Istio in
2020:

- Integration with more hosted Kubernetes environments - service meshes
powered by Istio are currently available from 15 vendors, including Google, IBM,
Red Hat, VMware, Alibaba and Huawei
- More investment in `istioctl` and its ability to help diagnose problems
- Better integration of VM-based workloads into meshes
- Continued work towards making multi-cluster and multi-network meshes easier to
configure, maintain, and run
- Integration with more service discovery systems, including
Functions-as-a-Service
- Implementation of the new
[Kubernetes service APIs](https://kubernetes-sigs.github.io/service-apis/),
which are currently in development
- An [enhancement repository](https://github.com/istio/enhancements/),
to track feature development
- Making it easier to run Istio without needing Kubernetes!

From the seas to [the skies](https://www.youtube.com/watch?v=YjZ4AZ7hRM0),
we're excited to see where you take Istio next.
