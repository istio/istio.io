---
title: Istio Multicluster
description: Install Istio with multicluster support.
weight: 65
keywords: [kubernetes,multicluster]
---

Instructions for the installation of Istio multicluster.

## Prerequisites

* Two or more Kubernetes clusters with **1.9 or newer**.

* The ability to deploy the [Istio control plane](/docs/setup/kubernetes/quick-start/)
on **one** Kubernetes cluster.

*   The usage of an RFC1918 network, VPN, or alternative more advanced network techniques
to meet the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All pod CIDRs in every cluster must be routable to each other.

    * All Kubernetes control plane API servers must be routable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

## Caveats and known problems

All known caveats and known problems with multicluster for the 1.0 release are [tracked here](https://github.com/istio/istio/issues/4822).

## Overview

Multicluster functions by enabling Kubernetes control planes running
a remote configuration to connect to **one** Istio control plane.
Once one or more remote Kubernetes clusters are connected to the
Istio control plane, Envoy can then communicate with the **single**
Istio control plane and form a mesh network across multiple Kubernetes
clusters.

This guide describes how to install a multicluster Istio topology using the
manifests and Helm charts provided within the Istio repository.

## Deploy the local Istio control plane

Install the [Istio control plane](/docs/setup/kubernetes/quick-start/#installation-steps)
on **one** Kubernetes cluster.

## Install the Istio remote on every remote cluster

The istio-remote component must be deployed to each remote Kubernetes
cluster.  There are two approaches to installing the remote.  The remote
can be installed and managed entirely by Helm and Tiller, or via Helm and
kubectl.

### Set environment variables for Pod IPs from Istio control plane needed by remote

Please wait for the Istio control plane to finish initializing
before proceeding to steps in this section.

These operations must be run on the Istio control plane cluster
to capture the Istio control-plane service endpoints--e.g. Pilot, Policy,
and Statsd Pod IP endpoints.

If Helm is used with Tiller on each remote, copy the environment
variables to each node before using Helm to connect the remote
cluster to the Istio control plane.

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
$ export STATSD_POD_IP=$(kubectl -n istio-system get pod -l istio=statsd-prom-bridge -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
$ export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].status.podIP}')
{{< /text >}}

Proceed to one of the options for connecting the remote cluster to the local cluster:

* [via kubectl with helm](#use-kubectl-with-helm-to-connect-the-remote-cluster-to-the-local)

* [via helm plus tiller](#alternatively-use-helm-and-tiller-to-connect-the-remote-cluster-to-the-local)

**Sidecar Injection.**  The default behavior is to enable automatic sidecar injection on the remote clusters.  For manual sidecar injection refer to the [manual sidecar example](#remote-cluster-manual-sidecar-injection-example)

### Use kubectl with Helm to connect the remote cluster to the local

1.  Use the helm template command on a remote to specify the Istio control plane service endpoints:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.proxy.envoyStatsd.enabled=true --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

1.  Create a namespace for remote Istio.

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1.  Instantiate the remote cluster's connection to the Istio control plane:

    {{< text bash >}}
    $ kubectl create -f $HOME/istio-remote.yaml
    {{< /text >}}

1.  Label all the remote cluster's namespaces requiring auto-sidecar injection.  The following example labels the `default` namespace.

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    Repeat for any additional kubernetes namespaces to setup auto-sidecar injection.

### Alternatively use Helm and Tiller to connect the remote cluster to the local

1.  If a service account has not already been installed for Helm, please
install one:

    {{< text bash >}}
    $ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1.  Initialize Helm:

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1.  Install the Helm chart:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-remote --name istio-remote  --namespace istio-system --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.proxy.envoyStatsd.enabled=true --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP}
    {{< /text >}}

### Helm configuration parameters

In order for the remote cluster's sidecars interaction with the Istio control plane, the `pilot`,
`policy`, `telemetry`, `statsd`, and tracing service endpoints need to be configured in
the `istio-remote` helm chart.  The chart enables automatic sidecar injection in the remote
cluster by default but it can be disabled via a chart variable.  The following table describes
the `istio-remote` helm chart's configuration values.

| Helm Variable | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `global.remotePilotAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's pilot Pod IP address or remote cluster DNS resolvable hostname |
| `global.remotePolicyAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's policy Pod IP address or remote cluster DNS resolvable hostname |
| `global.remoteTelemetryAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's telemetry Pod IP address or remote cluster DNS resolvable hostname |
| `global.proxy.envoyStatsd.enabled` | true, false | false | Specifies whether the Istio control plane has statsd enabled |
| `global.proxy.envoyStatsd.host` | A valid IP address or hostname | None | Specifies the Istio control plane's statsd-prom-bridge Pod IP address or remote cluster DNS resolvable hostname.  Ignored if `global.proxy.envoyStatsd.enabled=false`. |
| `global.remoteZipkinAddress` | A valid IP address or hostname | None | Specifies the Istio control plane's tracing application Pod IP address or remote cluster DNS resolvable hostname--e.g. `zipkin` or `jaeger`. |
| `sidecarInjectorWebhook.enabled` | true, false | true | Specifies whether to enable automatic sidecar injection on the remote cluster |
| `global.remotePilotCreateSvcEndpoint` | true, false | false | If set, a selector-less service and endpoint for `istio-pilot` are created with the `remotePilotAddress` IP, which ensures the `istio-pilot.<namespace>` is DNS resolvable in the remote cluster. |

## Generate `kubeconfigs` for remote clusters

The Istio control plane requires access to all clusters in the mesh to
discover services, endpoints, and pod attributes.  The following
describes how to generate a `kubeconfig` file for a remote cluster to be used by
the Istio control plane.

The `istio-remote` helm chart creates a Kubernetes service account named `istio-multi`
in the remote cluster with the minimal RBAC access required.  The following procedure
generates a `kubeconfig` file for the remote cluster using the credentials of the
`istio-multi` service account created by the `istio-remote` helm chart.

The following procedure should be performed on each remote cluster to be
added to the service mesh.  The procedure requires cluster-admin user access
to the remote cluster.

1.  Prepare environment variables for building the `kubeconfig` file for `ServiceAccount` `istio-multi`:

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

    __NOTE__: An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.

1. Create a `kubeconfig` file in the working directory for the `ServiceAccount` `istio-multi`:

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

At this point, the remote clusters' `kubeconfig` files have been created in the current directory.
The filename for a cluster is the same as the original `kubeconfig` cluster name.

## Instantiate the credentials for each remote cluster

Execute this work on the cluster running the Istio control
plane.

Istio can be installed in a different namespace other than
istio-system.

The local cluster running the Istio control plane does not need
it's secrets stored and labeled. The local node is always aware of
its Kubernetes credentials, but the local node is not aware of
the remote nodes' credentials.

Create a secret and label it properly for each remote cluster:

{{< text bash >}}
$ cd $WORK_DIR
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

{{< warning_icon >}}
Kubernetes secret data keys have to conform to `DNS-1123 subdomain`
[format](https://tools.ietf.org/html/rfc1123#page-13), so the filename can't have
underscores for example.  To resolve any issue you can simply change the filename
to conform to the format.

## Uninstalling

> The uninstall method must match the installation method (`Helm and kubectl` or `Helm and Tiller` based).

### Use kubectl to uninstall istio-remote

{{< text bash >}}
$ kubectl delete -f $HOME/istio-remote.yaml
{{< /text >}}

### Alternatively use Helm and Tiller to uninstall istio-remote

{{< text bash >}}
$ helm delete --purge istio-remote
{{< /text >}}

## Remote cluster manual sidecar injection example

The following example shows how to use the `helm template` command to generate the
manifest for the remote cluster with automatic sidecar injection disabled.  Additionally,
the example indicates how to use the remote clusters' configmaps with the `istioctl kube-inject`
command to generate any application manifests for the remote cluster.

The following procedure is to be performed against the remote cluster.

> The endpoint IP environment variables need to be set as in the [above section](#set-environment-variables-for-pod-ips-from-istio-control-plane-needed-by-remote)

1.  Use the helm template command on a remote to specify the Istio control plane service endpoints:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.remotePilotAddress=${PILOT_POD_IP} --set global.remotePolicyAddress=${POLICY_POD_IP} --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} --set global.proxy.envoyStatsd.enabled=true --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} --set global.remoteZipkinAddress=${ZIPKIN_POD_IP} --set sidecarInjectorWebhook.enabled=false > $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1.  Create a namespace for remote Istio.

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1.  Instantiate the remote cluster's connection to the Istio control plane:

    {{< text bash >}}
    $ kubectl create -f $HOME/istio-remote_noautoinj.yaml
    {{< /text >}}

1.  [Generate kubeconfig for remote clusters](#generate-kubeconfigs-for-remote-clusters)

1.  [Instantiate the credentials for each remote cluster](#instantiate-the-credentials-for-each-remote-cluster)

### Manually inject sidecars into application manifests

The following is an example `istioctl` command to inject sidecars into application manifests.  The commands should be run in a shell with `kubeconfig` context setup for the remote cluster.

{{< text bash >}}
$ ORIGINAL_SVC_MANIFEST=mysvc-v1.yaml
$ istioctl kube-inject --injectConfigMapName istio-sidecar-injector --meshConfigMapName istio -f ${ORIGINAL_SVC_MANIFEST} | kubectl apply -f -
{{< /text >}}

## Deployment considerations

The above procedure provides a simple and step by step guide to deploy a multicluster
environment.  A production environment might require additional steps or more complex
deployment options.  The procedure gathers the endpoint IPs of Istio services and uses
them to invoke Helm. This create Istio services on the remote clusters. As part of
creating those services and endpoints in the remote cluster Kubernetes will
add DNS entries into kube-dns.  This allows kube-dns in the remote clusters to
resolve the Istio service names for all envoy sidecars in those remote clusters.
Since Kubernetes pods don't have stable IPs, restart of any Istio service pod in
the control plane cluster will cause its endpoint to be changed. Therefore, any
connection made from remote clusters to that endpoint will be broken. This is
documented in [Istio issue #4822](https://github.com/istio/istio/issues/4822)

There are a number of ways to either avoid or resolve this scenario. This section
provides a high level overview of these options.

* Update the DNS entries
* Use a load balancer service type
* Expose the Istio services via a gateway

### Update the DNS entries

Upon any failure or pod restart kube-dns on the remote clusters can be
updated with the correct endpoint mappings for the Istio services.  There
are a number of ways this can be done. The most obvious is to rerun the Helm
install in the remote cluster after the Istio services on the control plane
cluster have restarted.

### Use load balance service type

In Kubernetes, you can declare a service with a service type to be
[LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types).
A simple solution to the pod restart issue is to use load balancers for the
Istio services. You can then use the load balancer IPs as the Istio services's
endpoint IPs to configure the remote clusters. You may need balancer IPs for
these Istio services: `istio-pilot, istio-telemetry, istio-policy,
istio-statsd-prom-bridge, zipkin`

Currently, Istio installation doesn't provide an option to specify service types
for the Istio services. But you can modify the Istio Helm charts or the Istio
manifests yourself.

### Expose the Istio services via a gateway

This uses the Istio Ingress gateway functionality.  The remote clusters have the
`istio-pilot, istio-telemetry, istio-policy, istio-statsd-prom-bridge, zipkin`
services pointing to the load balanced IP of the Istio ingress.  All the services
can point to the same IP.  The ingress gateway is then provided with destination
rules to reach the proper Istio service in the main cluster.

Within this option there are 2 sub-options.  One is to re-use the default Istio ingress gateway
installed with the provided manifests or helm charts.  The other option is to create another
Istio ingress gateway specifically for multicluster.

## Security

Istio supports deployment of mTLS between the control plane components as well as between
sidecar injected application pods.

### Control plane security

The steps to enable control plane security are as follows:

1.  Istio control plane cluster deployed with
    1.  control plane security enabled
    1.  `citadel` certificate self signing disabled
    1.  a secret named `cacerts` in the Istio control plane namespace with the [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)

1.  Istio remote clusters deployed with
    1.  control plane security enabled
    1.  `citadel` certificate self signing disabled
    1.  a secret named `cacerts` in the Istio control plane namespace with the [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)
        1.  The CA certificate for the remote clusters needs to be signed by the same CA or root CA as the main cluster.
    1.  Istio pilot service hostname resolvable via DNS
        1.  Required because Istio configures the sidecar to verify the certificate subject names using the `istio-pilot.<namespace>` subject name format.
    1.  Control plane IPs or resolvable host names set

### mTLS between application pods

The steps to enable mTLS for all application pods are as follows:

1.  Istio control plane cluster deployed with
    1.  Global mTLS enabled
    1.  `citadel` certificate self signing disabled
    1.  a secret named `cacerts` in the Istio control plane namespace with the [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)

1.  Istio remote clusters deployed with
    1.  Global mTLS enabled
    1.  `citadel` certificate self signing disabled
    1.  a secret named `cacerts` in the Istio control plane namespace with the [CA certificates](/docs/tasks/security/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key)
        1.  The CA certificate for the remote clusters needs to be signed by the same CA or root CA as the main cluster.

> The CA certificate steps are identical for both control plane security and application pod security steps.

### Example deployment

The following is an example procedure to install Istio with both control plane mTLS and application pod
mTLS enabled.  The example sets up a remote cluster with a selector-less service and endpoint for `istio-pilot` to
allow the remote sidecars to resolve `istio-pilot.istio-system` hostname via its local kubernetes DNS.

1.  *Primary Cluster.*  Deployment of the Istio control plane cluster

    1.  Create the `cacerts` secret from the Istio samples certificate in the `istio-system` namespace:

        {{< text bash >}}
        $ kubectl create ns istio-system
        $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
        {{< /text >}}

    1.  Deploy the Istio control plane with control plane and application pod security enabled

        {{< text bash >}}
        $ helm template --namespace=istio-system \
          --values install/kubernetes/helm/istio/values.yaml \
          --set global.mtls.enabled=true \
          --set security.selfSigned=false \
          --set global.controlPlaneSecurityEnabled=true \
          install/kubernetes/helm/istio > ${HOME}/istio-auth.yaml
        $ kubectl create -f ${HOME}/istio-auth.yaml
        {{< /text >}}

1.  *Remote Cluster.*  Deployment of remote cluster's istio components

    1.  Create the `cacerts` secret from the Istio samples certificate in the `istio-system` namespace:

        {{< text bash >}}
        $ kubectl create ns istio-system
        $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
        {{< /text >}}

    1.  Set endpoint IP environment variables as in the [setting environment variables](#set-environment-variables-for-pod-ips-from-istio-control-plane-needed-by-remote) section

    1.  Deploy the remote cluster's components with control plane and application pod security enabled.  Also, enable creation of the `istio-pilot` selector-less service and endpoint to get a DNS entry in the remote cluster.

        {{< text bash >}}
        $ helm template install/kubernetes/helm/istio-remote \
          --name istio-remote \
          --namespace=istio-system \
          --set global.mtls.enabled=true \
          --set security.selfSigned=false \
          --set global.controlPlaneSecurityEnabled=true \
          --set global.remotePilotCreateSvcEndpoint=true \
          --set global.remotePilotAddress=${PILOT_POD_IP} \
          --set global.remotePolicyAddress=${POLICY_POD_IP} \
          --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
          --set global.proxy.envoyStatsd.enabled=true \
          --set global.proxy.envoyStatsd.host=${STATSD_POD_IP} > ${HOME}/istio-remote-auth.yaml
        $ kubectl create -f ${HOME}/istio-remote-auth.yaml
        {{< /text >}}

    1.  [Generate kubeconfig for remote cluster](#generate-kubeconfigs-for-remote-clusters)

1.  *Primary Cluster.*  [Instantiate the credentials for each remote cluster](#instantiate-the-credentials-for-each-remote-cluster)

At this point all of the Istio components in both clusters are configured for mTLS between application
sidecars and the control plane components as well as between the other application sidecars.
