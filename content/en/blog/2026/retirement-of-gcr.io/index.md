---
title: "Istio is Migrating Container Registries"
description: What you can do today to ensure your clusters are not impacted by the retirement of `gcr.io/istio-release`.
publishdate: 2026-03-23
attribution: Steven Jin (Microsoft), John Howard (Solo.io)
keywords: [Istio,Helm,Container Registry]
---

Due to changes in Istio's funding model, Istio images will no longer be available at `gcr.io/istio-release` starting January 1st, 2027.
That is, clusters that reference images hosted on `gcr.io/istio-release` might fail to create new pods in 2027.

In fact, we are fully migrating all Istio artifacts out of Google Cloud, including Helm charts.
Future communications will cover the migration of Helm charts and other artifacts.
This post will focus on what you can do today in response to the 2027 container registry migration.

## Am I affected?

By default, Istio installations use Docker Hub (`docker.io/istio`) as their container registry, but many users choose to use the `gcr.io/istio-release` mirror.
You can check whether you are using the mirror using the following command.

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("gcr.io/istio-release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

The above command will list all the pods that use images hosted on `gcr.io/istio-release`.
If there are any such pods, you will likely need to migrate.

{{< tip >}}
Even if you are using Docker Hub as your registry, we suggest that you migrate to `registry.istio.io` in case Istio images are no longer available on Docker Hub in the future.
See below for more details.
{{< /tip >}}

## What to do today

Although we plan to keep images available on `gcr.io/istio-release` until late 2026,
we have set up `registry.istio.io` as the new home for Istio images.
`registry.istio.io` works today, but **it is not ready for production use**.
We expect it to be ready by April 2026, and we will update this post when it is production ready.

For now, **please update your test and development clusters to pull from `registry.istio.io` so we can catch any issues before labeling it as production-ready.**

### Using `istioctl`

If you install Istio using `istioctl`, you can update your `IstioOperator` configuration as follows:

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: registry.istio.io/release
  # Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

and install Istio using this configuration

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

Alternatively, you can pass in the registry as a command line argument

{{< text bash >}}
$ istioctl install --set hub=registry.istio.io/release # the rest of your arguments
{{< /text >}}

### Using Helm

If you use Helm to install Istio, update your values file to have the following:

{{< text yaml >}}
# ...
hub: registry.istio.io/release
global:
  hub: registry.istio.io/release
# Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

Then, update your Helm installation with your new values file.

### Private mirrors

Your organization might pull images from `gcr.io/istio-release`, push them to a private registry, and reference the private registry in your Istio installation.
This process will still work, but you will have to pull from `registry.istio.io/release` instead of `gcr.io/istio-release`.
