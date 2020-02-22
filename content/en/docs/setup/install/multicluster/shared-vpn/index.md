---
title: Shared control plane (single-network)
description: Install an Istio mesh across multiple Kubernetes clusters with a shared control plane and VPN connectivity between clusters.
weight: 5
keywords: [kubernetes,multicluster,federation,vpn]
aliases:
    - /docs/setup/kubernetes/multicluster-install/vpn/
    - /docs/setup/kubernetes/install/multicluster/vpn/
    - /docs/setup/kubernetes/install/multicluster/shared-vpn/
---

Follow this guide to install an Istio [multicluster service mesh](/docs/ops/deployment/deployment-models/#multiple-clusters)
where the Kubernetes cluster services and the applications in each cluster
have the capability to expose their internal Kubernetes network to other
clusters.

In this configuration, multiple Kubernetes clusters running
a remote configuration connect to a shared Istio
[control plane](/docs/ops/deployment/deployment-models/#control-plane-models).
Once one or more remote Kubernetes clusters are connected to the
Istio control plane, Envoy can then form a mesh network across multiple clusters.

{{< image width="80%" link="./multicluster-with-vpn.svg" caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN" >}}

## Prerequisites

* Two or more clusters running a supported Kubernetes version ({{< supported_kubernetes_versions >}}).

* The ability to [deploy the Istio control plane](/docs/setup/install/istioctl/)
  on **one** of the clusters.

* A RFC1918 network, VPN, or an alternative more advanced network technique
  meeting the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All pod CIDRs in every cluster must be routable to each other.

    * All Kubernetes control plane API servers must be routable to each other.

This guide describes how to install a multicluster Istio topology using the
remote configuration profile provided by Istio.

## Deploy the local control plane

[Install the Istio control plane](/docs/setup/install/istioctl/)
on **one** Kubernetes cluster.

### Set environment variables {#environment-var}

Wait for the Istio control plane to finish initializing before following the
steps in this section.

You must run these operations on the Istio control plane cluster to capture the
Istio control plane service endpoints, for example, the Pilot and Policy Pod IP
endpoints.

Set the environment variables with the following commands:

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')jsonpath='{.items[0].status.podIP}')
{{< /text >}}

Normally, automatic sidecar injection on the remote clusters is enabled. To
perform a manual sidecar injection refer to the [manual sidecar example](#manual-sidecar)

## Install the Istio remote

You must deploy the `istio-remote` component to each remote Kubernetes
cluster. You can install the component in one of two ways:

1.  Use the following command on the remote cluster to install
    the Istio control plane service endpoints:

    {{< text bash >}}
    $ istioctl manifest apply \
    --set profile=remote \
    --set values.global.remotePilotAddress=${PILOT_POD_IP} \
    {{< /text >}}

    {{< tip >}}
    All clusters must have the same namespace for the Istio
    components.
    {{< /tip >}}

1.  Label all namespaces in both clusters that need to setup automatic 
    sidecar injection. Do not label the `istio-system` namespace.

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

### Installation configuration parameters

You must configure the remote cluster's sidecars interaction with the Istio
control plane including the following endpoints in the `istio-remote` profile:
`pilot` and tracing service.  The profile
enables automatic sidecar injection in the remote cluster by default. You can
disable the automatic sidecar injection via a separate setting.

The following table shows the `istioctl` configuration values for remote clusters:

| Install setting | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `values.global.remotePilotAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's pilot Pod IP address or remote cluster DNS resolvable hostname |
| `values.global.remotePilotCreateSvcEndpoint` | true, false | false | If set, a selector-less service and endpoint for `istio-pilot` are created with the `remotePilotAddress` IP, which ensures the `istio-pilot.<namespace>` is DNS resolvable in the remote cluster. |
| `values.global.createRemoteSvcEndpoints` | true, false | false | If set, selector-less services and endpoints for `istio-pilot` are created with the corresponding remote IPs: `remotePilotAddress` which ensures the service names are DNS resolvable in the remote cluster. |

## Generate configuration files for remote clusters

The Istio control plane requires access to all clusters in the mesh to
discover services, endpoints, and pod attributes. Create a configuration
file for each remote cluster and install it in the main cluster's istio-system
namespace. This configuration uses the credentials of the `istio-reader-service-account`
service account in each cluster.

    export REMOTE_CLUSTER_KUBECONFIG=<....>
    export REMOTE_CLUSTER_NAME=<...>
    export MAIN_CLUSTER_KUBECONFIG=<....>
    istioctl x create-remote-secret --kubeconfig ${REMOTE_CLUSTER_KUBECONFIG} --name ${REMOTE_CLUSTER_NAME} |
        kubectl --kubeconfig ${MAIN_CLUSTER_KUBECONFIG} apply -f -

This procedure requires the `cluster-admin` user access permission to
the remote cluster.

{{< warning >}}
Do not create a remote secret for the local cluster running the local cluster
running the Istio control plane. Istio is always aware of the local cluster's
Kubernetes credentials.
{{< /warning >}}

## Uninstalling the remote cluster

To uninstall the cluster run the following command:

{{< text bash >}}
    $ istioctl manifest generate \
    --set profile=remote \
    --set values.global.remotePilotAddress=${PILOT_POD_IP} | \
    kubectl delete -f -
{{< /text >}}

## Access services from different clusters

Kubernetes resolves DNS on a cluster basis. Because the DNS resolution is tied
to the cluster, you must define the service object in every cluster where a
client runs, regardless of the location of the service's endpoints. To ensure
this is the case, duplicate the service object to every cluster using
`kubectl`. Duplication ensures Kubernetes can resolve the service name in any
cluster. Since the service objects are defined in a namespace, you must define
the namespace if it doesn't exist, and include it in the service definitions in
all clusters.

## Deployment considerations

The previous procedures provide a simple and step-by-step guide to deploy a
multicluster environment. A production environment might require additional
steps or more complex deployment options. The procedures gather the endpoint
IPs of the Istio services and use them to invoke `istioctl`. This process creates
Istio services on the remote clusters. As part of creating those services and
endpoints in the remote cluster, Kubernetes adds DNS entries to the `kube-dns`
configuration object.

This allows the `kube-dns` configuration object in the remote clusters to
resolve the Istio service names for all Envoy sidecars in those remote
clusters. Since Kubernetes pods don't have stable IPs, restart of any Istio
service pod in the control plane cluster causes its endpoint to change.
Therefore, any connection made from remote clusters to that endpoint are
broken. This behavior is documented in [Istio issue #4822](https://github.com/istio/istio/issues/4822)

To either avoid or resolve this scenario several options are available. This
section provides a high level overview of these options:

* Update the DNS entries
* Use a load balancer service type
* Expose the Istio services via a gateway

### Update the DNS entries

Upon any failure or restart of the local Istio control plane, `kube-dns` on the remote clusters must be
updated with the correct endpoint mappings for the Istio services.  There
are a number of ways this can be done. The most obvious is to rerun the
`istioctl` command in the remote cluster after the Istio services on the control plane
cluster have restarted.

### Use load balance service type

In Kubernetes, you can declare a service with a service type of `LoadBalancer`.
See the Kubernetes documentation on [service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
for more information.

A simple solution to the pod restart issue is to use load balancers for the
Istio services. Then, you can use the load balancers' IPs as the Istio
services' endpoint IPs to configure the remote clusters. You may need load
balancer IPs for these Istio services:

* `istio-pilot`

Currently, the Istio installation doesn't provide an option to specify service
types for the Istio services. You can manually specify the service types in the
Istio manifests.

### Expose the Istio services via a gateway

This method uses the Istio ingress gateway functionality. The remote clusters
have the `istio-pilot`, `istio-telemetry` and `istio-policy` services
pointing to the load balanced IP of the Istio ingress gateway. Then, all the
services point to the same IP.
You must then create the destination rules to reach the proper Istio service in
the main cluster in the ingress gateway.

This method provides two alternatives:

* Re-use the default Istio ingress gateway installed with the provided
  manifests. You only need to add the correct destination rules.

* Create another Istio ingress gateway specifically for the multicluster.

## Security

Istio supports deployment of mutual TLS between the control plane components as
well as between sidecar injected application pods.

### Control plane security

To enable control plane security follow these general steps:

1.  Deploy the Istio control plane cluster with:

    * The control plane security enabled.

    * The `citadel` certificate self signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [Certificate Authority (CA) certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key).

1.  Deploy the Istio remote clusters with:

    * The control plane security enabled.

    * The `citadel` certificate self signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [CA certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key).
      The Certificate Authority (CA) of the main cluster or a root CA must sign
      the CA certificate for the remote clusters too.

    * The Istio pilot service hostname must be resolvable via DNS. DNS
      resolution is required because Istio configures the sidecar to verify the
      certificate subject names using the `istio-pilot.<namespace>` subject
      name format.

    * Set control plane IPs or resolvable host names.

### Mutual TLS between application pods

To enable mutual TLS for all application pods, follow these general steps:

1.  Deploy the Istio control plane cluster with:

    * Mutual TLS globally enabled.

    * The Citadel certificate self-signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [CA certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)

1.  Deploy the Istio remote clusters with:

    * Mutual TLS globally enabled.

    * The Citadel certificate self-signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [CA certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)
      The CA of the main cluster or a root CA must sign the CA certificate for
      the remote clusters too.

{{< tip >}}
The CA certificate steps are identical for both control plane security and
application pod security steps.
{{< /tip >}}

### Example deployment

This example procedure installs Istio with both the control plane mutual TLS
and the application pod mutual TLS enabled. The procedure sets up a remote
cluster with a selector-less service and endpoint. Istio Pilot uses the service
and endpoint to allow the remote sidecars to resolve the
`istio-pilot.istio-system` hostname via Istio's local Kubernetes DNS.

#### Primary cluster: deploy the control plane cluster

1. Create the `cacerts` secret using the Istio certificate samples in the
   `istio-system` namespace:

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. Deploy the Istio control plane with security enabled for the control plane
   and the application pod:

    {{< text bash >}}
    $ istioctl manifest apply \
      --set values.global.mtls.enabled=true \
      --set values.security.selfSigned=false
    {{< /text >}}

#### Remote cluster: deploy Istio components

1. Create the `cacerts` secret using the Istio certificate samples in the
   `istio-system` namespace:

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. Set the environment variables for the IP addresses of the pods as described
   in the [setting environment variables section](#environment-var).

1. The following command deploys the remote cluster's components with security
   enabled for the control plane and the application pod and enables the
   creation of the an Istio Pilot selector-less service and endpoint to get a
   DNS entry in the remote cluster.

    {{< text bash >}}
    $ istioctl manifest apply \
      --set profile=remote \
      --set values.global.mtls.enabled=true \
      --set values.security.selfSigned=false \
      --set values.global.createRemoteSvcEndpoints=true \
      --set values.global.remotePilotCreateSvcEndpoint=true \
      --set values.global.remotePilotAddress=${PILOT_POD_IP} \
      --set values.global.remotePolicyAddress=${POLICY_POD_IP} \
      --set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
      --set gateways.enabled=false \
      --set autoInjection.enabled=true
    {{< /text >}}

1. To generate the `kubeconfig` configuration file for the remote cluster,
   follow the steps in the [Kubernetes configuration section](#kubeconfig)

### Primary cluster: instantiate credentials

You must instantiate credentials for each remote cluster. Follow the
[instantiate credentials procedure](#credentials)
to complete the deployment.

**Congratulations!**

You have configured all the Istio components in both clusters to use mutual TLS
between application sidecars, the control plane components, and other
application sidecars.
