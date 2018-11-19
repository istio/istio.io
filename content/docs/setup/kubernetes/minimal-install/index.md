---
title: Minimal Istio Installation
description: Install minimal Istio using Helm.
weight: 31
keywords: [kubernetes,helm, minimal]
icon: helm
---

Quick start instructions for the minimal setup and configuration of Istio using Helm.
This minimal install provides traffic management features of Istio.

## Prerequisites

Refer to the [prerequisites](/docs/setup/kubernetes/quick-start/#prerequisites) described in the Quick Start guide.

## Installation steps

1. If using a Helm version prior to 2.10.0, install Istio's [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
via `kubectl apply`, and wait a few seconds for the CRDs to be committed in the kube-apiserver:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. Choose one of the following two
**mutually exclusive** options described below.

### Option 1: Install with Helm via `helm template`

1. Render Istio's core components to a Kubernetes manifest called `istio-minimal.yaml`:

    {{< text bash >}}
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
      --set pilot.sidecar=false > $HOME/istio-minimal.yaml
    {{< /text >}}

1. Install the Pilot component via the manifest:

    {{< text bash >}}
    $ kubectl create namespace istio-system
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

1. Install Istio:

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

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    {{< /text >}}

    If your Helm version is less than 2.10.0, then you need to manually cleanup extra job resource before redeploy new version of Istio chart:

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}

* If desired, delete the CRDs:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}
