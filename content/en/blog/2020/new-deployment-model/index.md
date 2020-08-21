---
title: A New Istiod Deployment Model
subtitle: Clear Separation between Mesh Operator and Mesh Users
description: A new deployment model for Istio.
publishdate: 2020-08-19
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [multicluster,install,deploy,'1.7']
---

## Background

From experience working with various service mesh users and vendors, we believe there are 3 key personas for a typical service mesh:
* Mesh Operator
* Platform Owner
* Service Owner

It is common to have all these personas work on the same clusters without any clear separation.  For example, there are multiple ways to deploy Istio according to the docs, which all started with mesh operator, platform owner and service owner sharing the single cluster first and then gradually expanding the mesh to multiple clusters or VMs.  None of these provided a clear separation between mesh operator and platform/service owner at the boundary of a cluster.  You may be thinking you could set up [Kubernetes RBAC rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) and namespaces to control which personas can do what within the cluster, however, sometimes you need stronger separation between the istio control plane and the rest at the cluster level.  Introduce a new deployment model for Istio which enables mesh operators to install and manage mesh control plane on dedicated clusters, separated from the data plane clusters.  This new deployment model could easily enable Istio vendors to run Istio control plane for service mesh users while users can focus on their workloads and Istio resources without worrying about installing or managing the Istio control plane.


## New Deployment model

Let’s take a close look of what has been deployed in your cluster if you install Istio following the default install:
* Deployment and Services:
    * Istiod: Istio control plane component, which includes an XDS server, CA server and a webhook server.
    * Gateway: the default Istio ingress and egress gateways.
* Configs:
    * CRDs: Various Istio CRDs such as Gateway, Virtual Services, Destination Rules etc.
    * ConfigMaps: Istio mesh configurations and Injection templates.
    * Webhook configurations: configurations for two Istio webhooks (validation webhook and sidecar injector webhook)
    * Service account, role binding, etc: Istio security settings
    * Secrets: stores key and certs and credentials related to service account or Istiod.

Below diagram shows how resources are deployed in the cluster after following the [default install](https://istio.io/latest/docs/setup/install/istioctl/#install-istio-using-the-default-profile).

{{< image
    link="./default-install.jpeg"
    caption="default deployment model for istio"
>}}

With istio 1.7, it is possible to run Istiod on a separate cluster like the diagram below.

{{< image
    link="./central-istiod-single-cluster.jpeg"
    caption="New deployment model for one data plane cluster"
    >}}

In this setup, the `cluster1` should be set up first with `istiodRemote` and `base` components, then istiod on the control plane cluster is installed second, with its KUBECONFIG configured to `cluster1`. With this new deployment model, mesh operators can work purely on the control plane cluster when there is a need to upgrade or reconfig istio. Platform owners and service owners can instead work solely on cluster1 to focus on their istio configs or services.  

To support this, we introduced a new `istiodRemote` component in Isito 1.7. You can see now in cluster1, it only has istio configs and services that belong to data plane. Istiod runs in a separate cluster(control plane cluster) and is pointing its KUBECONFIG to cluster1.  Some sample snippet you can reference to install Istio on cluster1:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  addonComponents:
    prometheus:
      enabled: false
  components:
    base:
      enabled: true
    ingressGateways:
    - enabled: true
    istiodRemote:
      enabled: true
    pilot:
      enabled: false

{{< /text >}}

And sample snippet you can reference to install Istio on control plane cluster:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    base:
      enabled: false
    ingressGateways:
    - enabled: false
    pilot:
      enabled: true
values:
  global:
    operatorManageWebhooks: true

{{< /text >}}

If you are interested in exploring this, you can follow the [central istiod single cluster step by step guide.](https://github.com/istio/istio/wiki/Central-Istiod-single-cluster-steps)

The diagram above shows a single cluster as data plane for an Istio mesh, however, you may expand the setup to multiple clusters as data plane where these multiple clusters are managed by Istiod running on the control plane cluster and are getting configs from the config cluster per diagram below. 

{{< image width="100%" link="./central-istiod-multi-cluster.jpeg" caption="New deployment model for multi data plane clusters" >}}

You can further expand this deployment model to manage multiple istio mesh from a centralized control plane cluster that runs multiple Istiods, per diagram below:

{{< image width="100%" link="./central-istiod-multi-mesh.jpeg" caption="New deployment model for multi mesh" >}}

Control plane cluster can be used to host multiple Istiods and each Istiod manages his own data plane remotely.  In this model we can install Istio into the control plane cluster and use Istio ingress gateway and virtual services to route traffic between different istiod instances.

## Conclusion

This new deployment model enables the Istio control plane to be managed by others who have operation expertise in Istio and are able to keep up with the constant innovation of the Istio project.  We believe this deployment model will provide the best experience to platform/service owners where they can focus on architecturing the deployment or configuration of their services or the core business logic of their services.  While Istio has been perceived as complex by some users, the Istio community will continue working on making Istio simpler so users can focus on their core business.
