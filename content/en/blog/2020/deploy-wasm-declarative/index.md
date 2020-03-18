---
title: Declarative WASM deployment for Istio
subtitle: Deploy extensions to Envoy in Istio using a declarative model to align with GitOps workflows
description: Configuring WASM extensions for Envoy and Istio declaratively.
publishdate: 2020-03-16
attribution: "Christian Posta (Solo.io)"
keywords: [wasm,extensibility,alpha,operator]
---

As outlined in the [Istio 2020 trade winds blog](/blog/2020/tradewinds-2020/) and more recently [announced with Istio 1.5](/news/releases/1.5.x/announcing-1.5/), WebAssembly (Wasm) is now an (alpha) option for extending the functionality of the Istio service proxy (Envoy proxy). With Wasm, users can build support for new protocols, custom metrics, loggers, and other filters. Working closely with Google, we in the community ([Solo.io](https://solo.io)) have focused on the user experience of building, socializing, and deploying Wasm extensions to Istio. We've announced [WebAssembly Hub](https://webassemblyhub.io) and [associated tooling](https://docs.solo.io/web-assembly-hub/latest/installation/) to build a "docker-like" experience for working with Wasm.

## Background

With the WebAssembly Hub tooling, we can use the `wasme` CLI to easily bootstrap a Wasm project for Envoy, push it to a repository, and then pull/deploy it to Istio. For example, to deploy a Wasm extension to Istio with `wasme` we can run the following:

{{< text bash >}}
$  wasme deploy istio webassemblyhub.io/ceposta/demo-add-header:v0.2 \
  --id=myfilter \
  --namespace=bookinfo \
  --config 'tomorrow'
{{< /text >}}

This will add the `demo-add-header` extension to all workloads running in the `bookinfo` namespace. We can get more fine-grained control over which workloads get the extension by using the `--labels` parameter:

{{< text bash >}}
$  wasme deploy istio webassemblyhub.io/ceposta/demo-add-header:v0.2 \
  --id=myfilter  \
  --namespace=bookinfo  \
  --config 'tomorrow' \
  --labels app=details
{{< /text >}}

This is a much easier experience than manually creating `EnvoyFilter` resources and trying to get the Wasm module to each of the pods that are part of the workload you're trying to target. However, this is a very imperative approach to interacting with Istio. Just like users typically don't use `kubectl` directly in production and prefer a declarative, resource-based workflow, we want the same for making customizations to our Istio proxies.

## A declarative approach

The WebAssembly Hub tooling also includes [an operator for deploying Wasm extensions to Istio workloads](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/wasme_operator/). The [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) allows users to define their WebAssembly extensions using a declarative format and leave it to the operator to rectify the deployment. For example, we use a `FilterDeployment` resource to define what image and workloads need the extension:

{{< text yaml >}}
apiVersion: wasme.io/v1
kind: FilterDeployment
metadata:
  name: bookinfo-custom-filter
  namespace: bookinfo
spec:
  deployment:
    istio:
      kind: Deployment
      labels:
        app: details
  filter:
    config: 'world'
    image: webassemblyhub.io/ceposta/demo-add-header:v0.2
{{< /text >}}

We could then take this `FilterDeployment` document and version it with the rest of our Istio resources. You may be wondering why we need this Custom Resource to configure Istio's service proxy to use a Wasm extension when Istio already has the `EnvoyFilter` resource.

Let's take a look at exactly how all of this works under the covers.

## How it works

Under the covers the operator is doing a few things that aid in deploying and configuring a Wasm extension into the Istio service proxy (Envoy Proxy).

- Set up local cache of Wasm extensions
- Pull desired Wasm extension into the local cache
- Mount the `wasm-cache` into appropriate workloads
- Configure Envoy with `EnvoyFilter` CRD to use the Wasm filter

{{< image width="75%"
    link="./how-it-works.png"
    alt="How the wasme operator works"
    caption="Understanding how wasme operator works"
    >}}

At the moment, the Wasm image needs to be published into a registry for the operator to correctly cache it. The cache pods run as DaemonSet on each node so that the cache can be mounted into the Envoy container. This is being improved, as it's not the ideal mechanism. Ideally we wouldn't have to deal with mounting anything and could stream the module to the proxy directly over HTTP, so stay tuned for updates (should land within next few days). The mount is established by using the `sidecar.istio.io/userVolume` and `sidecar.istio.io/userVolumeMount` annotations. See [the docs on Istio Resource Annotations](/docs/reference/config/annotations/) for more about how that works.

Once the Wasm module is cached correctly and mounted into the workload's service proxy, the operator then configures the `EnvoyFilter` resources.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: details-v1-myfilter
  namespace: bookinfo
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        filterChain:
          filter:
            name: envoy.http_connection_manager
            subFilter:
              name: envoy.router
    patch:
      operation: INSERT_BEFORE
      value:
        config:
          config:
            configuration: tomorrow
            name: myfilter
            rootId: add_header
            vmConfig:
              code:
                local:
                  filename: /var/local/lib/wasme-cache/44bf95b368e78fafb663020b43cf099b23fc6032814653f2f47e4d20643e7267
              runtime: envoy.wasm.runtime.v8
              vmId: myfilter
        name: envoy.filters.http.wasm
  workloadSelector:
    labels:
      app: details
      version: v1
{{< /text >}}

You can see the `EnvoyFilter` resource configures the proxy to add the `envoy.filter.http.wasm` filter and load the Wasm module from the `wasme-cache`.

Once the Wasm extension is loaded into the Istio service proxy, it will extend the capabilities of the proxy with whatever custom code you introduced.

## Next Steps

In this blog we explored options for installing Wasm extensions into Istio workloads. The easiest way to get started with WebAssembly on Istio is to use the `wasme` tool [to bootstrap a new Wasm project](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/getting_started/) with C++, AssemblyScript [or Rust coming really soon!]. For example, to set up a C++ Wasm module, you can run:

{{< text bash >}}
$ wasme init ./filter --language cpp --platform istio --platform-version 1.5.x
{{< /text >}}

If we didn't have the extra flags, `wasme init` would enter an interactive mode walking you through the correct values to choose.

Take a look at the [WebAssembly Hub wasme tooling](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/getting_started/) to get started with Wasm on Istio.

## Learn more

-   Redefine Extensibility [with WebAssembly on Envoy and Istio](/blog/2020/wasm-announce/)

-   WebAssembly SF talk (video): [Extensions for network proxies](https://www.youtube.com/watch?v=OIUPf8m7CGA), by John Plevyak

-   [Solo blog](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)

-   [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)

-   [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md) and
    its [developer documentation](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md)

-   [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)

-   [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)

-   [Tutorials](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)

-   Videos on the [Solo.io Youtube Channel](https://www.youtube.com/channel/UCuketWAG3WqYjjxtQ9Q8ApQ)
