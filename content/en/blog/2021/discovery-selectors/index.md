---
title: "Use DiscoverySelectors To Configure Namespaces For Your Istio Service Mesh"
description: Learn how to use DiscoverySelectors and how it intersects with Sidecar resources.
publishdate: 2021-04-30
attribution: "Lin Sun (Solo.io), Christian Posta (Solo.io), Harvey Xia (Solo.io)"
keywords: [discoveryselectors,Istio,namespaces,sidecar]
---

As users move their services to run in the mesh, they are often surprised that the Istio control plane watches and processes all of the Istio and Kubernetes resources from all namespaces in the cluster by default. This can be an issue for very large clusters with lots of namespaces and deployments or even for a moderately sized cluster with rapidly churning resources (ie, think Spark jobs).

Both [in the community](https://github.com/istio/istio/issues/26679) as well as for our large-scale customers at [Solo.io](https://solo.io), we need a way to dynamically restrict the set of namespaces that are part of the mesh so that the Istio control plane only processes Istio and Kubernetes resources in those namespaces. The ability to restrict the namespaces enables Istiod to watch and push fewer resources and associated changes to the sidecars, thus improving the overall performance on the control plane and data plane.

## Background

By default, Istio watches all namespaces/services/endpoints/pods information in a cluster. For example, in my Kubernetes cluster, I deployed the sleep service in the default namespace, and the httpbin service in the ns-x namespace. I’ve added sleep services to the mesh and I have no plan to add the httpbin service in the ns-x namespace to the mesh or have any service in the mesh interact with the httpbin service in the ns-x namespace.

Use `istioctl pc endpoint` command to display all the endpoints for the sleep deployment:

{{< image link="./endpoints-default.png" caption="Endpoints for Sleep Deployment" >}}

Note that the httpbin service endpoint in the ns-x namespace is in the list of discovered endpoints. This may not be an issue when you only have a few services. However, when you have hundreds of services that don't interact with any of the services running in the Istio service mesh, you probably don't want your Istio control plane to watch these services and send their information to the sidecars of your services in the mesh.

## Introduce DiscoverySelectors

In Istio 1.10, we introduced the new “discoverySelectors” option to [MeshConfig](https://preliminary.istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig), which is an array of k8s selectors (the exact type will be `[]LabelSelector`, as defined here, allowing both simple selectors and set-based selectors). These selectors apply to labels on namespaces.

You can configure each label selector for expressing a variety of use cases, including but not limited to: 
* Arbitrary label names/values, for example, all namespaces with label `istio-discovery=enabled`
* A list of namespace labels using set-based selectors which carries OR semantics, for example, all namespaces with label `istio-discovery=enabled` OR `region=us-east1`
* Inclusion and/or exclusion of namespaces, for example, all namespaces with label istio-discovery=enabled AND label key `app` equal to `helloworld`

Note: DiscoverySelectors is not a security boundary. Istiod will continue to have access to all namespaces even when you have configured your DiscoverySelectors.

## DiscoverySelectors in Action

Assuming you know which namespaces to include as part of the service mesh, as a mesh administrator, you can configure DiscoverySelectors at installation time or post-installation by adding your desired discovery selectors to Istio’s MeshConfig resource. For example, you can configure Istio to discover only the namespace that has the label `istio-discovery=enabled`.

1. Enable all namespaces with this label. Using our examples earlier, let’s enable namespace default with label istio-discovery=enabled.

```bash
kubectl label namespace default istio-discovery=enabled
```

2. Use istioctl to apply the yaml with discoverySelectors to update your Istio installation. Note, to avoid any impact to your stable environment, we recommend you to use a different revision for your Istio installation:

```bash
istioctl install --skip-confirmation -f - <<EOF
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
```

3. Display endpoint configuration from sleep pod:

{{< image link="./endpoints-with-discovery-selectors.png" caption="Endpoints for Sleep Deployment With DiscoverySelectors" >}}

Note this time the httpbin service in the ns-x namespace is NOT in the list of discovered endpoints, along with many other services that are not in the default namespace. If you display routes (or cluster or listeners) information for the sleep deployment, you will also notice a much reduced configuration are returned:

{{< image link="./routes-with-discovery-selectors.png" caption="Routes for Sleep Deployment With DiscoverySelectors" >}}

You can use matchLabels to configure multiple labels with AND semantics or use matchLabels sets to configure OR semantics among multiple labels. Whether you deploy services or pods to namespaces with different sets of labels or multiple application teams in your organization use different labeling conventions, discoverySelectors provides the flexibility you need. Furthermore, you could use matchLabels and matchExpressions together per our [documentation](https://github.com/istio/api/blob/master/mesh/v1alpha1/config.proto#L792). Refer to the Kubernetes [selector docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) for additional detail on selector semantics.

## DiscoverySelectors vs Sidecar Resource

The DiscoverySelectors configuration enables users to dynamically restrict the set of namespaces that are part of the mesh. A [Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/) resource also controls the visibility of sidecar configurations and what gets pushed to the sidecar proxy. What are the differences between them?  

The DiscoverySelectors configuration declares what Istio control plane watches and processes. Without DiscoverySelectors configuration, the Istio control plane watches and processes all namespaces/services/endpoints/pods in the cluster regardless of the sidecar resources you have.

DiscoverySelectors are configured globally for the mesh by the mesh administrators. While sidecar resources can also be configured for the mesh globally by the mesh administrators in the MeshConfig root namespace,  they are commonly configured by service owners for their namespaces.

You can use DiscoverySelectors with Sidecar resources. You can use DiscoverySelectors to configure at the mesh-wide level what namespaces the Istio control plane should watch and process. For these namespaces in the Istio service mesh, you can create Sidecar resources globally or per namespace to further control what gets pushed to the sidecar proxies.  Let us add bookinfo services to the ns-y namespace in the mesh as shown below in the diagram. DiscoverySelectors enables us to define the default and ns-y namespaces are part of the mesh. How can we configure sleep service not to see anything other than the default namespace? Adding a sidecar resource for the default namespace, we can effectively configure the sleep sidecar to only have visibility to the clusters/routes/listeners/endpoints associated with its current namespace plus any other required namespaces.

{{< image link="./discovery-selectors-vs-sidecar.png" caption="DiscoverySelectors vs Sidecar Resource" >}}

## Let Us Wrap Up

DiscoverySelector is a powerful configuration to tune the Istio control plane only to watch and process specific namespaces. If you don't want all namespaces in your Kubernetes cluster to be part of the service mesh or you have multiple Istio service meshes within your Kubernetes cluster, we highly recommend you to explore this configuration and reach out to us for feedback on our Istio [slack](https://istio.slack.com) or GitHub.