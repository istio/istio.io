---
title: "An Update on Our Container Registry Migration"
description: What you can do today to ensure your clusters are not impacted by the retirement of `gcr.io/istio-release` and `registry.istio.io`.
publishdate: 2026-07-23
attribution: Steven Jin (Microsoft)
keywords: [Istio,Container Registry]
---

In a [previous blog post](../retirement-of-gcr.io/), we announced that Istio will retire the `gcr.io/istio-release` container registry in late 2026 and switch to `registry.istio.io/release` as the new home for Istio images.
The original design was that `registry.istio.io/release` would be a Cloudflare worker that proxied requests to any OCI-compliant registry, allowing us to switch registries without any interruption to Istio users.
Currently, we proxy to `gcr.io/istio-release`.

As mentioned before, we are retiring `gcr.io/istio-release` in late 2026.
With a limited infrastructure budget for 2027, we plan to use free container hosting platforms to host Istio images.
Unfortunately, proxying through Cloudflare means that we funnel all traffic through a few egress IPs, triggering rate-limiting policies on free container hosting platforms.

After discussions with hosting platforms regarding this limitation, we have made the difficult decision to retire `registry.istio.io/release`.
We will keep hosting `registry.istio.io/release` until late 2026.
As always, we will publish Istio images to `docker.io/istio` and plan on publishing to mirrors in the future.

## Am I affected?

By default, Istio 1.30 installations use `registry.istio.io/release` as their container registry.
All other Istio versions default to `docker.io/istio`.
You can check whether you are affected by running the following:

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("registry.istio.io/release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

The above command will list all the pods that use images hosted on `registry.istio.io/release`.
If there are any such pods, you will likely need to migrate.

Note that we will still retire `gcr.io/istio-release` in late 2026 as mentioned in the previous post, so you should check for `gcr.io/istio-release` usage too.

## What to do today

Although we plan to keep images available on `registry.istio.io/release` and `gcr.io/istio-release` until late 2026,
we suggest you migrate to `docker.io/istio` as soon as possible.
Even better, configure a pull-through cache to ensure maximum availability.

### Using `istioctl`

If you install Istio using `istioctl`, you can update your `IstioOperator` configuration as follows:

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: docker.io/istio  # or your pull-through cache
  # Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

And install Istio using this configuration:

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

Alternatively, you can pass in the registry as a command-line argument

{{< text bash >}}
$ istioctl install --set hub=docker.io/istio # or your pull-through cache
{{< /text >}}

### Using Helm

If you use Helm to install Istio, update your values file as follows:

{{< text yaml >}}
# ...
hub: docker.io/istio  # or your pull-through cache
global:
  hub: docker.io/istio  # or your pull-through cache
# Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

Then, update your Helm installation with your new values file.
