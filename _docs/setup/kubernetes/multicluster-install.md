---
title: Istio Multicluster
description: Install Istio with multicluster support.

weight: 65

---

{% include home.html %}

Instructions for the installation of Istio multicluster.

## Prerequisites

* Two or more Kubernetes clusters with **1.7.3 or newer**.

* The ability to deploy the [Istio control plane]({{home}}/docs/setup/kubernetes/quick-start.html)
on **one** Kubernetes cluster.

* The usage of an RFC1918 network, VPN, or alternative more advanced network techniques
to meet the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All nodes' pod CIDR in every cluster must be routable to every other nodes'
pod CIDR.

    * All Kubernetes control plane API servers must be routable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

* Currently only [manual sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#manual-sidecar-injection)
has been validated with multicluster.

## Caveats and known problems

<img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" />
All known caveats and known problems with multicluster for the 0.8 release are [tracked here](https://github.com/istio/istio/issues/4822).

## Deploy all Kubernetes clusters to be used in the mesh

Use your desired technique to deploy all Kubernetes clusters
that are to participate in the mesh with only Kubernetes and
the CNI of choice. Once the remote clusters are deployed, each
one will have a credentials file associated with the admin
context typically located in `$HOME/.kube/config`.

## Gather credential files from remote

> `${CLUSTER_NAME}` here is defined as the name of the remote
cluster used and must be unique across the mesh.  Some Kubernetes
installers do not set this value uniquely.  In this case, manual
modification of the `${CLUSTER_NAME}` fields must be done.

For each remote cluster, execute the following steps:

1. Determine a name for the remote cluster that is unique across
all clusters in the mesh.  Substitute the chosen name for the
remaining steps in `${CLUSTER_NAME}`.

1. Copy the credentials file form the remote Kubernetes cluster
to the local Istio control plane cluster directory
`$HOME/multicluster/${CLUSTER_NAME}`.  The `${CLUSTER_NAME}` must
be unique per remote.

1. Modify the name of the remote cluster's credential file field
`clusters.cluster.name` to match `${CLUSTER_NAME}`.

1. Modify the name of the remote cluster's credential file field
`contexts.context.cluster` to match `${CLUSTER_NAME}`.

## Instantiate the credentials for each remote cluster

Execute this work on the cluster intended to run the Istio control
plane.

Create a namespace for instantiating the secrets:

```bash
kubectl create ns istio-system
```

Create a secret and label it properly for each remote cluster:

```bash
pushd $HOME/multicluster
kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n istio-system
kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n istio-system
popd
```

<img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" />Ordering currently matters.  Secrets must be created prior to the deployment of
the Istio control plane.  Creating secrets after Istio is started will not register the
secrets with Istio properly.

## Deploy the local Istio control plane

Install the [Istio control plane]({{home}}/docs/setup/kubernetes/quick-start.html)
on **one** Kubernetes cluster.

## Install the Istio remote on every remote cluster

<img src="{{home}}/img/exclamation-mark.svg" alt="Important" title="Important" style="width: 32px; display:inline" />
The istio-remote component must be deployed to each remote Kubernetes cluster.

### Use kubectl with Helm to connect the remote cluster to the local

1. Use the helm template command on a remote to specify the Istio control plane service endpoints:

   ```bash
   helm template install/kubernetes/helm/istio-remote --name istio-remote --set pilotEndpoint=`pod_ip_of_pilot_local` --set policyEndpoint=`pod_ip_of_policy_local` --set statsdEndpoint=`pod_ip_of_statsd_local` > $HOME/istio-remote.yaml
    ```

1. Instantiate the remote cluster's connection to the Istio control plane:

   ```bash
   kubectl create -f $HOME/istio-remote.yaml
   ```

### Alternatively use Helm and Tiller to connect the remote cluster to the local

1. If a service account has not already been installed for Helm, please
install one:

   ```bash
   kubectl create -f install/kubernetes/helm/helm-service-account.yaml
   ```

1. Initialize Helm:

   ```bash
   helm init --service-account tiller
   ```

1. Install the Helm chart:

   ```bash
   helm install install/kubernetes/helm/istio-remote --name istio-remote --set pilotEndpoint=`pod_ip_of_pilot_local` --set policyEndpoint=`pod_ip_of_policy_local` --set statsdEndpoint=`pod_ip_of_statsd_local` > $HOME/istio-remote.yaml -n istio-system
   ```

### Helm configuration parameters

The `isito-remote` Helm chart requires the configuration of two specific variables defined in the following table:

| Helm Variable | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `global.pilotEndpoint` | A valid IP address | istio-pilot.istio-system | Specifies the Istio control plane's pilot Pod IP address |
| `global.policyEndpoint` | A valid IP address | istio-policy.istio-system | Specifies the Istio control plane's policy Pod IP address |
| `global.statsdEndpoint` | A valid IP address | istio-statsd-prom-bridge.istio-system | Specifies the Istio control plane's statsd Pod IP address |

> The `pilotEndpoint`, `policyEndpoint`, `statsdEndpoint` need to be resolvable via Kubernetes.

## Uninstalling

> The uninstall method must match the installation method (`Helm and kubectl` or `Helm and Tiller` based).

### Use kubectl to uninstall istio-remote

```bash
kubectl delete -f $HOME/istio-remote.yaml
```

### Alternatively use Helm and Tiller to uninstall istio-remote

```bash
helm delete --purge istio-remote
```
