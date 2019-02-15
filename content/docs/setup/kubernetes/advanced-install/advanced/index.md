---
title: Advanced Install Options
description: Instructions for customizing the Istio installation.
weight: 35
keywords: [kubernetes]
draft: true
---

This section provides options for piecemeal installation of Istio
components.

## Ingress controller only

It is possible to use Istio as an Ingress controller, leveraging advanced
L7 routing capabilities such as version-aware routing, header based
routing, gRPC/HTTP2 proxying, tracing, etc. Deploy Istio Pilot only and
disable other components. Do not deploy the Istio initializer.

## Ingress controller with policies and telemetry

By deploying Istio Pilot and Mixer, the Ingress controller configuration
described above can be enhanced to provide in-depth telemetry and policy
enforcement capabilities such as rate limits, access controls, etc.

## Intelligent routing and telemetry

If you wish to take advantage of Istio's L7 traffic management
capabilities, in addition to obtaining in-depth telemetry and performing
distributed request tracing, deploy Istio Pilot and Mixer. In addition,
disable policy enforcement at the Mixer.

## Customization example: traffic management and minimal security set

Istio has a rich feature set, but you may only want to use a subset of these. For instance, you might be only interested in installing the minimum necessary services to support traffic management and security functionality.

This example shows how to install the minimal set of components necessary to use [traffic management](/docs/tasks/traffic-management/) features.

Execute the following command to install the Pilot and Citadel:

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false
{{< /text >}}

Ensure the `istio-pilot-*` and `istio-citadel-*` Kubernetes pods are deployed and their containers are up and running:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
{{< /text >}}

With this minimal set you can install your own application and [configure request routing](/docs/tasks/traffic-management/request-routing/). You will need to [manually inject the sidecar](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection).

[Installation Options](/docs/reference/config/installation-options/) has the full list of options allowing you to tailor the Istio installation to your needs. Before you override the default value with `--set` in `helm install`, please check the configurations for the option in `install/kubernetes/helm/istio/values.yaml` and uncomment the commented context if needed.
