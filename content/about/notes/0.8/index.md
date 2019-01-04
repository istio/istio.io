---
title: Istio 0.8
weight: 93
icon: notes
---

This is a major release for Istio on the road to 1.0. There are a great many new features and architectural improvements in addition to the usual pile of bug fixes and performance improvements.

{{< relnote_links >}}

## Networking

- **Revamped Traffic Management Model**. We're finally ready to take the wraps off our
[new traffic management APIs](/blog/2018/v1alpha3-routing/). We believe this new model is easier to understand while covering more real world
deployment [use-cases](/docs/tasks/traffic-management/). For folks upgrading from earlier releases there is a
[migration guide](/docs/setup/kubernetes/upgrading-istio/) and a conversion tool built into `istioctl` to help convert your configuration from the old model.

- **Streaming Envoy configuration**. By default Pilot now streams configuration to Envoy using its [ADS API](https://github.com/envoyproxy/data-plane-api/blob/master/XDS_PROTOCOL.md). This new approach increases effective scalability, reduces rollout delay and should eliminate spurious 404 errors.

- **Gateway for Ingress/Egress**. We no longer support combining Kubernetes Ingress specs with Istio routing rules as it has led to several bugs and reliability issues. Istio now supports a platform independent [Gateway](/docs/concepts/traffic-management/#gateways) model for ingress & egress proxies that works across Kubernetes and Cloud Foundry and works seamlessly with routing. The Gateway supports [Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication) based routing,
as well as serving a certificate based on the server name presented by the client.

- **Constrained Inbound Ports**. We now restrict the inbound ports in a pod to the ones declared by the apps running inside that pod.

## Security

- **Introducing Citadel**. We've finally given a name to our security component. What was formerly known as Istio-Auth or Istio-CA is now called Citadel.

- **Multicluster Support**. We support per-cluster Citadel in multicluster deployments such that all Citadels share the same root certificate and workloads can authenticate each other across the mesh.

- **Authentication Policy**. We've created a unified API for [authentication policy](/docs/tasks/security/authn-policy/) that controls whether service-to-service communication uses mutual TLS as well as end user authentication. This is now the recommended way to control these behaviors.

## Telemetry

- **Self-Reporting**. Mixer and Pilot now produce telemetry that flows through the normal
Istio telemetry pipeline, just like services in the mesh.

## Setup

- **A la Carte Istio**. Istio has a rich set of features, however you don't need to install or consume them all together. By using
Helm or `istioctl gen-deploy`, users can install only the features they want. For example, users can install Pilot only and enjoy traffic
management functionality without dealing with Mixer or Citadel.

## Mixer adapters

- **CloudWatch**. Mixer can now report metrics to AWS CloudWatch.
[Learn more](/docs/reference/config/policy-and-telemetry/adapters/cloudwatch/)

## Known issues with 0.8

- A gateway with virtual services pointing to a headless service won't work ([Issue #5005](https://github.com/istio/istio/issues/5005)).

- There is a [problem with Google Kubernetes Engine 1.10.2](https://github.com/istio/istio/issues/5723). The workaround is to use Kubernetes 1.9 or switch the node image to Ubuntu. A fix is expected in GKE 1.10.4.

- There is a known namespace issue with `istioctl experimental convert-networking-config` tool where the desired namespace may be changed to the istio-system namespace, please manually adjust to use the desired namespace after running the conversation tool.   [Learn more](https://github.com/istio/istio/issues/5817)
