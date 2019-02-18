---
title: VPN Connectivity
description: Install an Istio mesh across multiple Kubernetes clusters with direct network access to remote pods.
weight: 5
keywords: [kubernetes,multicluster,federation,vpn]
aliases:
    - /docs/setup/kubernetes/multicluster-install
---

Instructions for installing an Istio [multicluster service mesh](/docs/concepts/multicluster-deployments/)
where Kubernetes cluster services and applications in each cluster have the capability to expose
their internal Kubernetes network to other clusters.

In this configuration, multiple Kubernetes control planes running
a remote configuration connect to a **single** Istio control plane.
Once one or more remote Kubernetes clusters are connected to the
Istio control plane, Envoy can then communicate with the **single**
control plane and form a mesh network across multiple clusters.

{{< image width="80%" link="./multicluster-with-vpn.svg" caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN" >}}

## Prerequisites

* Two or more clusters running **Kubernetes version 1.9 or newer**.

* The ability to deploy the [Istio control plane](/docs/setup/kubernetes/quick-start/)
  on **one** of the clusters.

* A RFC1918 network, VPN, or an alternative more advanced network technique
  meeting the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All pod CIDRs in every cluster must be routable to each other.

    * All Kubernetes control plane API servers must be routable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

This guide describes how to install a multicluster Istio topology using the
manifests and Helm charts provided within the Istio repository.

## Deploy the local control plane

Install the [Istio control plane](/docs/setup/kubernetes/quick-start/#installation-steps)
on **one** Kubernetes cluster.

## Install the Istio remote

You must deploy the `istio-remote` component to each remote Kubernetes
cluster. You can install the component in one of two ways:

{{< tabset cookie-name="install-istio-remote" >}}

{{% tab name="Helm+kubectl" cookie-value="Helm+kubectl" %}}
[Use Helm and `kubectl` to install and manage the remote cluster](#helm-k)
{{% /tab %}}
{{% tab name="Helm+Tiller" cookie-value="Helm+Tiller" %}}
[Use Helm and Tiller to install and manage the remote cluster](#tiller)
{{% /tab %}}
{{< /tabset >}}

### Set environment variables {#environment-var}

Wait for the Istio control plane to finish initializing before following the
steps in this section.

You must run these operations on the Istio control plane cluster to capture the
Istio control plane service endpoints, for example, the Pilot and Policy Pod IP
endpoints.

If you use Helm with Tiller on each remote, you must copy the environment
variables to each node before using Helm to connect the remote
cluster to the Istio control plane.

Set the environment variables with the following commands:

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
{{< /text >}}

Next, you must connect the remote cluster to the local cluster. Proceed to your preferred option:

* Via [`kubectl` with Helm](#helm-k)

* Via [Helm plus Tiller](#tiller)

Normally, automatic sidecar injection on the remote clusters is enabled. To
perform a manual sidecar injection refer to the [manual sidecar example](#manual-sidecar)

### Install and manage the remote cluster

{{< tabset cookie-name="install-istio-remote" >}}

{{% tab name="Helm+kubectl" cookie-value="Helm+kubectl" %}}

#### With Helm and `kubectl` {#helm-k}

1.  Use the following `helm template` command on the remote cluster to specify
    the Istio control plane service endpoints:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --namespace istio-system \
    --name istio-remote \
    --values install/kubernetes/helm/istio/values-istio-remote.yaml \
    --set global.remotePilotAddress=${PILOT_POD_IP} \
    --set global.remotePolicyAddress=${POLICY_POD_IP} \
    --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

1.  Create an `istio-system` namespace for remote Istio with the following
    command:

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

    {{< tip >}}
    All clusters must have the same namespace for the Istio
    components. It is possible to override the `istio-system` name on the main
    cluster as long as the namespace is the same for all Istio components in
    all clusters.
    {{< /tip >}}

1.  Instantiate the remote cluster's connection to the Istio control plane with
    the following command:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-remote.yaml
    {{< /text >}}

1.  The following command example labels the `default` namespace. Use similar
    commands to label all the remote cluster's namespaces requiring automatic
    sidecar injection.

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    Repeat for all Kubernetes namespaces that need to setup automatic sidecar
    injection.

{{% /tab %}}

{{% tab name="Helm+Tiller" cookie-value="Helm+Tiller" %}}

#### With Helm and Tiller {#tiller}

1. If you haven't installed a service account for Helm, install one with the
   following command:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. Initialize Helm with the following command:

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. Install the Helm chart for the `istio-remote` with the following command:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio \
    --name istio-remote --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-remote.yaml \
    --set global.remotePilotAddress=${PILOT_POD_IP} \
    --set global.remotePolicyAddress=${POLICY_POD_IP} \
    --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP}
    {{< /text >}}

{{% /tab %}}

{{< /tabset >}}

### Helm chart configuration parameters

You must configure the remote cluster's sidecars interaction with the Istio
control plane including the following endpoints in the `istio-remote` Helm
chart: `pilot`, `policy`, `telemetry` and tracing service.  The chart
enables automatic sidecar injection in the remote cluster by default. You can
disable the automatic sidecar injection via a chart variable.

The following table shows the accepted `istio-remote` Helm chart's
configuration values:

| Helm Variable | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `global.remotePilotAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's pilot Pod IP address or remote cluster DNS resolvable hostname |
| `global.remotePolicyAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's policy Pod IP address or remote cluster DNS resolvable hostname |
| `global.remoteTelemetryAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's telemetry Pod IP address or remote cluster DNS resolvable hostname |
| `sidecarInjectorWebhook.enabled` | true, false | true | Specifies whether to enable automatic sidecar injection on the remote cluster |
| `global.remotePilotCreateSvcEndpoint` | true, false | false | If set, a selector-less service and endpoint for `istio-pilot` are created with the `remotePilotAddress` IP, which ensures the `istio-pilot.<namespace>` is DNS resolvable in the remote cluster. |

## Generate configuration files for remote clusters {#kubeconfig}

The Istio control plane requires access to all clusters in the mesh to
discover services, endpoints, and pod attributes. The following steps
describe how to generate a `kubeconfig` configuration file for the Istio control plane to use a remote cluster.

The `istio-remote` Helm chart creates a Kubernetes service account named
`istio-multi` in the remote cluster with the minimal required RBAC access. This
procedure generates the remote cluster's `kubeconfig` file using
the credentials of said `istio-multi` service account.

Perform this procedure on each remote cluster to add the cluster to the service
mesh. This procedure requires the `cluster-admin` user access permission to
the remote cluster.

1.  Set the environment variables needed to build the `kubeconfig` file for the
    `istio-multi` service account with the following commands:

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-multi
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< tip >}}
    An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.
    {{< /tip >}}

1. Create a `kubeconfig` file in the working directory for the
    `istio-multi` service account with the following command:

    {{< text bash >}}
    $ cat <<EOF > ${KUBECFG_FILE}
    apiVersion: v1
    clusters:
       - cluster:
           certificate-authority-data: ${CA_DATA}
           server: ${SERVER}
         name: ${CLUSTER_NAME}
    contexts:
       - context:
           cluster: ${CLUSTER_NAME}
           user: ${CLUSTER_NAME}
         name: ${CLUSTER_NAME}
    current-context: ${CLUSTER_NAME}
    kind: Config
    preferences: {}
    users:
       - name: ${CLUSTER_NAME}
         user:
           token: ${TOKEN}
    EOF
    {{< /text >}}

1. _(Optional)_  Create file with environment variables to create the remote cluster's secret:

    {{< text bash >}}
    $ cat <<EOF > remote_cluster_env_vars
    export CLUSTER_NAME=${CLUSTER_NAME}
    export KUBECFG_FILE=${KUBECFG_FILE}
    export NAMESPACE=${NAMESPACE}
    EOF
    {{< /text >}}

At this point, you created the remote clusters' `kubeconfig` files in the
current directory. The filename of the `kubeconfig` file is the same as the
original cluster name.

## Instantiate the credentials {#credentials}

Perform this procedure on the cluster running the Istio control plane. This
procedure uses the `WORK_DIR`, `CLUSTER_NAME`, and `NAMESPACE` environment
values set and the file created for the remote cluster's secret from the
[previous section](#kubeconfig).

If you created the environment variables file for the remote cluster's
secret, source the file with the following command:

    {{< text bash >}}
    $ source remote_cluster_env_vars
    {{< /text >}}

You can install Istio in a different namespace. This procedure uses the
`istio-system` namespace.

{{< warning >}}
Do not store and label the secrets for the local cluster
running the Istio control plane. Istio is always aware of the local cluster's
Kubernetes credentials.
{{< /warning >}}

Create a secret and label it properly for each remote cluster:

{{< text bash >}}
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

{{< warning >}}
The Kubernetes secret data keys must conform with the
`DNS-1123 subdomain` [format](https://tools.ietf.org/html/rfc1123#page-13). For
example, the filename can't have underscores.  Resolve any issue with the
filename simply by changing the filename to conform with the format.
{{< /warning >}}

## Uninstalling the remote cluster

You must uninstall remote clusters using the same method you used to install
them. Use either `kubectl and Helm` or `Tiller and Helm` as appropriate.

{{< tabset cookie-name="uninstall-istio-remote" >}}

{{% tab name="kubectl" cookie-value="kubectl" %}}

### With `kubectl`

To uninstall the cluster, you must remove the configuration made with the
`istio-remote` .YAML file. To uninstall the cluster run the following command:

{{< text bash >}}
$ kubectl delete -f $HOME/istio-remote.yaml
{{< /text >}}

{{% /tab %}}

{{% tab name="Tiller" cookie-value="Tiller" %}}

### With Tiller

To uninstall the cluster, you must remove the configuration made with the
`istio-remote` .YAML file. To uninstall the cluster run the following command:

{{< text bash >}}
$ helm delete --purge istio-remote
{{< /text >}}

{{% /tab %}}

{{< /tabset >}}

## Manual sidecar injection example {#manual-sidecar}

The following example shows how to use the `helm template` command to generate
the manifest for a remote cluster with the automatic sidecar injection
disabled. Additionally, the example shows how to use the `configmaps` of the
remote cluster with the `istioctl kube-inject` command to generate any
application manifests for the remote cluster.

Perform the following procedure against the remote cluster.

Before you begin, set the endpoint IP environment variables as described in the
[set the environment variables section](#environment-var)

1. Use the `helm template` command on the remote cluster to specify the Istio
   control plane service endpoints:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio \
    --namespace istio-system --name istio-remote \
    --values install/kubernetes/helm/istio/values-istio-remote.yaml \
    --set global.remotePilotAddress=${PILOT_POD_IP} \
    --set global.remotePolicyAddress=${POLICY_POD_IP} \
    --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
    --set sidecarInjectorWebhook.enabled=false > $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1. Create the `istio-system` namespace for remote Istio:

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1. Instantiate the remote cluster's connection to the Istio control plane:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1. [Generate](#kubeconfig) the `kubeconfig` configuration file for each remote
   cluster.

1. [Instantiate the credentials](#credentials) for each remote cluster.

### Manually inject the sidecars into the application manifests

The following example `istioctl` command injects the sidecars into the
application manifests. Run the following commands in a shell with the
`kubeconfig` context set up for the remote cluster.

{{< text bash >}}
$ ORIGINAL_SVC_MANIFEST=mysvc-v1.yaml
$ istioctl kube-inject --injectConfigMapName istio-sidecar-injector --meshConfigMapName istio -f ${ORIGINAL_SVC_MANIFEST} | kubectl apply -f -
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
IPs of the Istio services and use them to invoke Helm. This process creates
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

Upon any failure or pod, restart `kube-dns` on the remote clusters can be
updated with the correct endpoint mappings for the Istio services.  There
are a number of ways this can be done. The most obvious is to rerun the Helm
install in the remote cluster after the Istio services on the control plane
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
* `istio-telemetry`
* `istio-policy`

Currently, the Istio installation doesn't provide an option to specify service
types for the Istio services. You can manually specify the service types in the
Istio Helm charts or the Istio manifests.

### Expose the Istio services via a gateway

This method uses the Istio ingress gateway functionality. The remote clusters
have the `istio-pilot`, `istio-telemetry` and `istio-policy` services
pointing to the load balanced IP of the Istio ingress gateway. Then, all the
services point to the same IP.
You must then create the destination rules to reach the proper Istio service in
the main cluster in the ingress gateway.

This method provides two alternatives:

* Re-use the default Istio ingress gateway installed with the provided
  manifests or Helm charts. You only need to add the correct destination rules.

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
      [Certificate Authority (CA) certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key).

1.  Deploy the Istio remote clusters with:

    * The control plane security enabled.

    * The `citadel` certificate self signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key).
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
      [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)

1.  Deploy the Istio remote clusters with:

    * Mutual TLS globally enabled.

    * The Citadel certificate self-signing disabled.

    * A secret named `cacerts` in the Istio control plane namespace with the
      [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)
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

#### Primary Cluster: Deploy the control plane cluster

1. Create the `cacerts` secret using the Istio certificate samples in the
   `istio-system` namespace:

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. Deploy the Istio control plane with security enabled for the control plane
   and the application pod:

    {{< text bash >}}
    $ helm template --namespace=istio-system \
      --values install/kubernetes/helm/istio/values.yaml \
      --set global.mtls.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      install/kubernetes/helm/istio > ${HOME}/istio-auth.yaml
    $ kubectl apply -f ${HOME}/istio-auth.yaml
    {{< /text >}}

#### Remote Cluster: Deploy Istio components

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
    $ helm template install/kubernetes/helm/istio \
      --name istio-remote \
      --namespace istio-system \
      --values install/kubernetes/helm/istio/values-istio-remote.yaml \
      --set global.mtls.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.remotePilotCreateSvcEndpoint=true \
      --set global.remotePilotAddress=${PILOT_POD_IP} \
      --set global.remotePolicyAddress=${POLICY_POD_IP} \
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > ${HOME}/istio-remote-auth.yaml
    $ kubectl apply -f ${HOME}/istio-remote-auth.yaml
    {{< /text >}}

1. To generate the `kubeconfig` configuration file for the remote cluster,
   follow the steps in the [Kubernetes configuration section](#kubeconfig)

### Primary Cluster: Instantiate credentials

You must instantiate credentials for each remote cluster. Follow the
[instantiate credentials procedure](#credentials)
to complete the deployment.

**Congratulations!**

You have configured all the Istio components in both clusters to use mutual TLS
between application sidecars, the control plane components, and other
application sidecars.
