---
title: "Use discovery selectors to configure namespaces for your Istio service mesh"
description: Learn how to use discovery selectors and how they intersect with Sidecar resources.
publishdate: 2021-04-30
attribution: "Lin Sun (Solo.io), Christian Posta (Solo.io), Harvey Xia (Solo.io)"
keywords: [discoveryselectors,Istio,namespaces,sidecar]
---

As users move their services to run in the Istio service mesh, they are often surprised that the control plane watches and processes all of the Kubernetes resources, from all namespaces in the cluster, by default. This can be an issue for very large clusters with lots of namespaces and deployments, or even for a moderately sized cluster with rapidly churning resources (for example, Spark jobs).

Both [in the community](https://github.com/istio/istio/issues/26679) as well as for our large-scale customers at [Solo.io](https://solo.io), we need a way to dynamically restrict the set of namespaces that are part of the mesh so that the Istio control plane only processes resources in those namespaces. The ability to restrict the namespaces enables Istiod to watch and push fewer resources and associated changes to the sidecars, thus improving the overall performance on the control plane and data plane.

## Background

By default, Istio watches all Namespaces, Services, Endpoints and Pods in a cluster. For example, in my Kubernetes cluster, I deployed the `sleep` service in the default namespace, and the `httpbin` service in the `ns-x` namespace. I’ve added the `sleep` service to the mesh, but I have no plan to add the `httpbin` service to the mesh, or have any service in the mesh interact with the `httpbin` service.

Use `istioctl proxy-config endpoint` command to display all the endpoints for the `sleep` deployment:

{{< image link="./endpoints-default.png" caption="Endpoints for Sleep Deployment" >}}

Note that the `httpbin` service endpoint in the `ns-x` namespace is in the list of discovered endpoints. This may not be an issue when you only have a few services. However, when you have hundreds of services that don't interact with any of the services running in the Istio service mesh, you probably don't want your Istio control plane to watch these services and send their information to the sidecars of your services in the mesh.

## Introducing Discovery Selectors

Starting with Istio 1.10, we are introducing the new `discoverySelectors` option to [MeshConfig](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig), which is an array of Kubernetes [selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements). The exact type is `[]LabelSelector`, as defined [here](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements), allowing both simple selectors and set-based selectors. These selectors apply to labels on namespaces.

You can configure each label selector for expressing a variety of use cases, including but not limited to:

* Arbitrary label names/values, for example, all namespaces with label `istio-discovery=enabled`
* A list of namespace labels using set-based selectors which carries OR semantics, for example, all namespaces with label `istio-discovery=enabled` OR `region=us-east1`
* Inclusion and/or exclusion of namespaces, for example, all namespaces with label istio-discovery=enabled AND label key `app` equal to `helloworld`

Note: `discoverySelectors` is not a security boundary. Istiod will continue to have access to all namespaces even when you have configured your `discoverySelectors`.

## Discovery Selectors in Action

Assuming you know which namespaces to include as part of the service mesh, as a mesh administrator, you can configure `discoverySelectors` at installation time or post-installation by adding your desired discovery selectors to Istio’s MeshConfig resource. For example, you can configure Istio to discover only the namespaces that have the label `istio-discovery=enabled`.

1. Using our examples earlier, let’s label the `default` namespace with label `istio-discovery=enabled`.

    {{< text bash >}}
    $ kubectl label namespace default istio-discovery=enabled
    {{< /text >}}

1. Use `istioctl` to apply the yaml with `discoverySelectors` to update your Istio installation. Note, to avoid any impact to your stable environment, we recommend that you use a different revision for your Istio installation:

    {{< text bash >}}
    $ istioctl install --skip-confirmation -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
    namespace: istio-system
    spec:
    # You may override parts of meshconfig by uncommenting the following lines.
      meshConfig:
        discoverySelectors:
          - matchLabels:
              istio-discovery: enabled
    EOF
    {{< /text >}}

1. Display the endpoint configuration for the `sleep` deployment:

    {{< image link="./endpoints-with-discovery-selectors.png" caption="Endpoints for Sleep Deployment With Discovery Selectors" >}}

    Note this time the `httpbin` service in the `ns-x` namespace is NOT in the list of discovered endpoints, along with many other services that are not in the default namespace. If you display routes (or cluster or listeners) information for the `sleep` deployment, you will also notice much less configuration is returned:

    {{< image link="./routes-with-discovery-selectors.png" caption="Routes for Sleep Deployment With Discovery Selectors" >}}

You can use `matchLabels` to configure multiple labels with AND semantics or use `matchLabels` sets to configure OR semantics among multiple labels. Whether you deploy services or pods to namespaces with different sets of labels or multiple application teams in your organization use different labeling conventions, `discoverySelectors` provides the flexibility you need. Furthermore, you could use `matchLabels` and `matchExpressions` together per our [documentation](https://github.com/istio/api/blob/master/mesh/v1alpha1/config.proto#L792). Refer to the [Kubernetes selector docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) for additional detail on selector semantics.

## Discovery Selectors vs Sidecar Resource

The `discoverySelectors` configuration enables users to dynamically restrict the set of namespaces that are part of the mesh. A [Sidecar](/docs/reference/config/networking/sidecar/) resource also controls the visibility of sidecar configurations and what gets pushed to the sidecar proxy. What are the differences between them?

* The `discoverySelectors` configuration declares what Istio control plane watches and processes. Without `discoverySelectors` configuration, the Istio control plane watches and processes all namespaces/services/endpoints/pods in the cluster regardless of the sidecar resources you have.
* `discoverySelectors` is configured globally for the mesh by the mesh administrators. While Sidecar resources can also be configured for the mesh globally by the mesh administrators in the MeshConfig root namespace,  they are commonly configured by service owners for their namespaces.

You can use `discoverySelectors` with Sidecar resources. You can use `discoverySelectors` to configure at the mesh-wide level what namespaces the Istio control plane should watch and process. For these namespaces in the Istio service mesh, you can create Sidecar resources globally or per namespace to further control what gets pushed to the sidecar proxies.  Let us add `Bookinfo` services to the `ns-y` namespace in the mesh as shown in the diagram below. `discoverySelectors` enables us to define the `default` and `ns-y` namespaces are part of the mesh. How can we configure the `sleep` service not to see anything other than the `default` namespace? Adding a Sidecar resource for the default namespace, we can effectively configure the `sleep` sidecar to only have visibility to the clusters/routes/listeners/endpoints associated with its current namespace plus any other required namespaces.

{{< image link="./discovery-selectors-vs-sidecar.png" caption="Discovery Selectors vs Sidecar Resource" >}}

## Wrapping up

Discovery selectors are powerful configurations to tune the Istio control plane to only watch and process specific namespaces. If you don't want all namespaces in your Kubernetes cluster to be part of the service mesh or you have multiple Istio service meshes within your Kubernetes cluster, we highly recommend that you explore this configuration and reach out to us for feedback on our [Istio slack](https://istio.slack.com) or GitHub.
