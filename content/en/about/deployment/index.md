---
title: Deployment
description: Deployment.
subtitle: Read about good practices that lead to a quick and effective implementation for day 1, day 2, and day 1,000.
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /deployment.html
doc_type: about
---

{{< centered_block >}}

You have decided you want to use Istio. Welcome to the world of service mesh. Congratulations, you're in great company!

If you haven't already, you might like to try Istio out in a test environment, and run through our [Getting Started guide](/docs/setup/getting-started/). This will give you an idea for the **traffic management**, **security** and **observability** features.

## Do it yourself, or bring a guide?

Istio is open-source software which you can download and install yourself. Getting a mesh installed on a Kubernetes cluster is as simple as running one command:

{{< text bash >}}
$ istioctl install
{{< /text >}}

As new versions are released, you can test them and gradually roll them out across your clusters.

Many managed Kubernetes service providers have an option to automatically install and manage Istio for you. Check out our [distributors page](/about/ecosystem/) to see if your vendor supports Istio.

Istio is also the engine powering many commercial service management products, with teams of experts ready to help you get on board.

There is a growing community of cloud native consultants who are able to help you on your Istio journey. If you're going to work with a member of the Istio ecosystem, we recommend you loop them in early. Many of our partners and distributors have been working with the project for a very long time, and will be invaluable in guiding you on your journey.

## What should you enable first?

There are many great reasons for adopting Istio: from adding security to your microservices to improving the reliability of your applications. Whatever your goals, the most successful Istio implementations start by identifying one use case and solving for that. Once you've configured the mesh to solve a problem, you can easily enable other features, increasing the usefulness of your deployment.

## How do I map the mesh to my architecture?

Gradually onboard your services into the mesh by adding one namespace at a time. By default, services from multiple namespaces can communicate with each other, but you can easily increase isolation by selectively choosing which services to expose to other namespaces. Using namespaces also improves performance as configuration is scoped down.

Istio is flexible to match the configuration of your Kubernetes cluster and network architecture. You may wish to run individual meshes and control planes on individual clusters, or you may have one.

As long as pods can reach each other on the network, Istio will work; and you can even configure Istio Gateways to act as bastion hosts between networks.

Learn about the [full range of deployment models](/docs/ops/deployment/deployment-models/) in our documentation.

Now is also a great time to think about which integrations you want to use: we recommend [setting up Prometheus](/docs/ops/integrations/prometheus/#Configuration) for service monitoring, with a [hierarchical federation to an external server](/docs/ops/best-practices/observability/). If your company's observability stack is run by a different team, now is the time to get them on board.

## Adding services to the mesh on Day 1

Your mesh is now configured and ready to accept services. To do that, you simply label your namespaces in Kubernetes, and when those services are redeployed, they will now include the Envoy proxy configured to talk to the Istio control plane.

### Configuring services

Many services will work out of the box, but by adding a little information to your Kubernetes manifests, you can make Istio much smarter. For example, setting labels for `app` and `version` will help with querying metrics later.

For common ports and protocols, Istio will detect the traffic type. If it can't detect, it will fall back to treating the traffic as TCP, but you can easily [annotate the service](/docs/ops/configuration/traffic-management/protocol-selection/) with the traffic type.

Learn more about [enabling applications for use with Istio](/docs/ops/deployment/requirements/).

### Enabling security

Istio will configure services in the mesh to use mTLS when talking to one another when possible. Istio will run in "permissive mTLS" mode by default, which means services will accept both encrypted and unencrypted traffic to allow traffic from non-mesh services to remain functional. After onboarding all your services to the mesh, you can [change the authentication policy to only allow encrypted traffic](/docs/tasks/security/authentication/mtls-migration/). You can then be certain that all your traffic is encrypted.

### Istio's two types of APIs

Istio has APIs for platform owners and service owners. Depending on which role you play, you only need to consider a subset. For example, the platform owners will own the installation, authentication and authorization resources. Traffic management resources will be handled by the service owners. [Learn which APIs are useful to you.](/docs/reference/config/)

### Connect services on virtual machines

Istio isn't just for Kubernetes; it's possible to [add services on virtual machines](/docs/setup/install/virtual-machine/) (or bare metal) into a mesh, to get all the benefits that Istio provides such as mutual TLS, rich telemetry, and advanced traffic management capabilities.

### Monitor your services

Check out traffic flowing through your mesh using [Kiali](/docs/ops/integrations/kiali/), or trace requests using [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) or [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/).

Use the default [Grafana](/docs/ops/integrations/grafana/) dashboards for Istio to get automatic reporting of golden signals for services running in a mesh.

## Operational considerations and Day 2

As the platform owner, you're responsible for installing and keeping the mesh up to date with little impact to the service teams.

### Installation

With istioctl, you can easily install Istio using one of the built-in profiles. As you customize your installation to meet your requirements, it is recommended to define your configuration using the IstioOperator custom resource (CR). This gives you the option of completely delegating the job of install management to an Istio Operator, instead of doing it manually using istioctl. Use an IstioOperator CR for just the control plane and additional IstioOperator CRs for gateways for increased flexibility in upgrading.

### Upgrade safely

When a new version is released, Istio allows for both in-place and canary upgrades. Choosing between the two is a trade off between simplicity and potential downtime. For production environments, it’s recommended to use the [canary upgrade method](/docs/setup/upgrade/canary/). After the new control and data plane versions are verified to be working, you can upgrade your gateways.

### Monitor the mesh

Istio generates detailed telemetry for all service communications within a mesh. These metrics, traces and access logs are vital for understanding how your applications are interacting with one another and identifying any performance bottlenecks. Use this information to help you set circuit breakers, timeouts, and retries and harden your applications.

Just like your apps running in the mesh, Istio control plane components also export metrics. Leverage these metrics and the preconfigured Grafana dashboards to adjust your resource requests, limits and scaling.

## Join the Istio community

Once you're running Istio, you've become a member of a large global community. You can ask questions on [our discussion forum](https://discuss.istio.io/), or [hop on Slack](https://slack.istio.io/). And if you want to improve something, or have a feature request, you can go straight to [GitHub](https://github.com/istio/istio).

Happy meshing!

{{< /centered_block >}}
