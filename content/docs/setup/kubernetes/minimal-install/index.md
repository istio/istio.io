---
title: Minimal Istio Installation
description: Install minimal Istio using Helm.
weight: 30
keywords: [kubernetes,helm, minimal]
icon: helm
---

Quick start instructions for the minimal setup and configuration of Istio using Helm.
This minimal install provides traffic management features of Istio.

## Prerequisites

Refer to the [prerequisites](/docs/setup/kubernetes/quick-start/#prerequisites) described in the Quick Start guide.

## Installation steps

Choose one of the following two **mutually exclusive** options described below.

### Option 1: Install with Helm via `helm template`

1. Render Istio's core components to a Kubernetes manifest called `istio-minimal.yaml`:

    {{< text bash >}}
    $ cat install/kubernetes/namespace.yaml > $HOME/istio-minimal.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-1* >> $HOME/istio-minimal.yaml
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set security.enabled=false \
      --set ingress.enabled=false \
      --set gateways.istio-ingressgateway.enabled=false \
      --set gateways.istio-egressgateway.enabled=false \
      --set galley.enabled=false \
      --set sidecarInjectorWebhook.enabled=false \
      --set mixer.policy.enabled=false \
      --set mixer.telemetry.enabled=false \
      --set prometheus.enabled=false \
      --set global.proxy.envoyStatsd.enabled=false \
      --set pilot.sidecar=false >> $HOME/istio-minimal.yaml
    {{< /text >}}

1. Install the Pilot component via the manifest:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-minimal.yaml
    {{< /text >}}

### Option 2: Install with Helm and Tiller via `helm install`

This option allows Helm and
[Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components)
to manage the lifecycle of Istio.

1. If a service account has not already been installed for Tiller, install one:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. Install Tiller on your cluster with the service account:

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. Install the `istio-init` chart to bootstrap all the Istio's [CRDs]:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

1. Install the `istio` chart:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio-minimal --namespace istio-system \
      --set security.enabled=false \
      --set ingress.enabled=false \
      --set gateways.istio-ingressgateway.enabled=false \
      --set gateways.istio-egressgateway.enabled=false \
      --set galley.enabled=false \
      --set sidecarInjectorWebhook.enabled=false \
      --set mixer.policy.enabled=false \
      --set mixer.telemetry.enabled=false \
      --set prometheus.enabled=false \
      --set global.proxy.envoyStatsd.enabled=false \
      --set pilot.sidecar=false
    {{< /text >}}

1. Ensure the `istio-pilot-*` Kubernetes pod is deployed and its container is up and running:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-pilot-58c65f74bc-2f5xn             1/1       Running   0          1m
{{< /text >}}

## Uninstall

* For option 1, uninstall using `kubectl`:

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio-minimal.yaml
    {{< /text >}}

* For option 2, uninstall using Helm:

> Uninstalling this chart does not delete Istio's registered CRDs. Istio by design expects
> CRDs to leak into the Kubernetes environment. As CRDs contain all runtime configuration
> data in CutomResources the Istio designers feel it is better to explicitly delete this
> configuration rather then unexpectedly lose it.

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    $ helm delete --purge istio-init
    {{< /text >}}

* If desired, run the following command to delete all CRDs:

> Warning: Deleting CRDs will delete any configuration that you have made to Istio.

    {{< text bash >}}
    $ for i in install install/kubernetes/helm/istio-init/files/*crd-1*yaml; do kubectl delete -f $i; done
    {{< /text >}}
