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

    * All pod CIDRs in every cluster must be routable to each other.

    * All Kubernetes control plane API servers must be routable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

* Currently only [manual sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#manual-sidecar-injection)
has been validated with multicluster.

## Caveats and known problems

<img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" />
All known caveats and known problems with multicluster for the 0.8 release are [tracked here](https://github.com/istio/istio/issues/4822).

## Overview

Multicluster functions by enabling Kubernetes control planes running
a remote configuration to connect to **one** Istio control plane.
Once one or more remote Kubernetes clusters are connected to the
Istio control plane, Envoy can then communicate with the **single**
Istio control plane and form a mesh network across multiple Kubernetes
clusters.

## Deploy all Kubernetes clusters to be used in the mesh

After deployment of remote clusters, each one will have a
credentials file associated with the admin context typically
located in `$HOME/.kube/config`.

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

> Execute this work on the cluster intended to run the Istio control
plane.

> Istio can be installed in a different namespace other than
istio-system.

Create a namespace for instantiating the secrets:

```command
$ kubectl create ns istio-system
```

> Ordering currently matters.  Secrets must be created prior to
the deployment of the Istio control plane.  Creating secrets
after Istio is started will not register the secrets with Istio
properly.

> The local cluster running the Istio control plane does not need
it's secrets stored and labeled. The local node is always aware of
it's Kubernetes credentials, but the local node is not aware of
the remote nodes' credentials.

Create a secret and label it properly for each remote cluster:

```command
$ pushd $HOME/multicluster
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n istio-system
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n istio-system
$ popd
```

## Deploy the local Istio control plane

Install the [Istio control plane]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps)
on **one** Kubernetes cluster.

## Install the Istio remote on every remote cluster

The istio-remote component must be deployed to each remote Kubernetes
cluster.  There are two approaches to installing the remote.  The remote
can be installed and managed entirely by Helm and Tiller, or via Helm and
kubectl.

### Set environment variables for Pod IPs from Istio control plane needed by remote

> Please wait for the Istio control plane to finish initializing
before proceeding to steps in this section.

> These operations must be run on the Istio control plane cluster
to capture the Pilot, Policy, and Statsd Pod IP endpoints.

> If Helm is used with Tiller on each remote, copy the environment
variables to each node before using Helm to connect the remote
cluster to the Istio control plane.

```command
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
$ export STATSD_POD_IP=$(kubectl -n istio-system get pod -l istio=statsd-prom-bridge -o jsonpath='{.items[0].status.podIP}')
```

### Use kubectl with Helm to connect the remote cluster to the local

1. Use the helm template command on a remote to specify the Istio control plane service endpoints:

   ```command
   $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.pilotEndpoint=${PILOT_POD_IP} --set global.policyEndpoint=${POLICY_POD_IP} --set global.statsdEndpoint=${STATSD_POD_IP} > $HOME/istio-remote.yaml
   ```

1. Create a namespace for remote Istio.
   ```command
   $ kubectl create ns istio-system
   ```
1. Instantiate the remote cluster's connection to the Istio control plane:

   ```command
   $ kubectl create -f $HOME/istio-remote.yaml
   ```

### Alternatively use Helm and Tiller to connect the remote cluster to the local

1. If a service account has not already been installed for Helm, please
install one:

   ```command
   $ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
   ```

1. Initialize Helm:

   ```command
   $ helm init --service-account tiller
   ```

1. Install the Helm chart:

   ```command
   $ helm install install/kubernetes/helm/istio-remote --name istio-remote --set global.pilotEndpoint=${PILOT_POD_IP} --set global.policyEndpoint=${POLICY_POD_IP} --set global.statsdEndpoint=${STATSD_POD_IP} --namespace istio-system
   ```

### Helm configuration parameters

> The `pilotEndpoint`, `policyEndpoint`, `statsdEndpoint` need to be resolvable via Kubernetes.
The simplest approach to enabling resolution for these variables is to specify the Pod IP of
the various services.  One problem with this is Pod IP's change during the lifetime of the
service.

The `isito-remote` Helm chart requires the three specific variables to be configured as defined in the following table:

| Helm Variable | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `global.pilotEndpoint` | A valid IP address | istio-pilot.istio-system | Specifies the Istio control plane's pilot Pod IP address |
| `global.policyEndpoint` | A valid IP address | istio-policy.istio-system | Specifies the Istio control plane's policy Pod IP address |
| `global.statsdEndpoint` | A valid IP address | istio-statsd-prom-bridge.istio-system | Specifies the Istio control plane's statsd Pod IP address |

## Uninstalling

> The uninstall method must match the installation method (`Helm and kubectl` or `Helm and Tiller` based).

### Use kubectl to uninstall istio-remote

```command
$ kubectl delete -f $HOME/istio-remote.yaml
```

### Alternatively use Helm and Tiller to uninstall istio-remote

```command
$ helm delete --purge istio-remote
```
