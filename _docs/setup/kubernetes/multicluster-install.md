---
title: Istio Multicluster
overview: Install Istio with multicluster support.

order: 65

layout: docs
type: markdown
---

{% include home.html %}

Instructions for the installation of Istio multicluster.

## Prerequisites

* Two or more Kubernetes clusters.

* The usage of a RFC1918 network, VPN, or other more advanced network techniques
to meet the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All nodes' pod CIDR in every cluster must be routable to every other nodes'
pod CIDR.

    * All Kubernetes control plane API servers must be routeable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

* If using Tiller, the ability to modify RBAC rules required to install Helm
or alternatively Helm should already installed.

* Kubernetes **1.7.3 or newer**.

* Istio secret `istio.default` replicated to all remote Kubernetes clusters
from the Istio control plane per application namespace.

* The local cluster and all remote Kubernetes cluster credentials (typically
stored in `$HOME/.kube/config`) copied to
`$HOME/multicluster/${UNIQUE_IDENTIFIER}.kube.conf`.

* A [deployed Istio control plane]({{home}}/docs/setup/kubernetes/quick-start.html)
on **one** Kubernetes cluster.  Note that Istio must be [deployed with Helm]({{home}}/docs/setup/kubernetes/helm-install.html) using the `--set global.multicluster.enabled=true` flag.  This is currently mandatory.

* Currently only [manual sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html)
has been validated with multicluster.

## Install a multicluster configmap on the Istio control plane

**Important**: Pilot will not start until the configmap in these instructions
is created.  This is normal behavior but different from what is seen with
multicluster disabled.

Create a clusterregistry descriptor to describe each Kubernetes cluster's role
in the multicluster environment.  These files should be stored in the directory
$HOME/multicluster, have a `.yaml` extension, and have a unique filename.

An example clusterregistry configuration descriptor is shown below:

```yaml
apiVersion: clusterregistry.k8s.io/v1alpha1
kind: Cluster
metadata:
  name: "falkor07"
  annotations:
    config.istio.io/pilotEndpoint: "192.168.1.1:9080"
    config.istio.io/platform: "Kubernetes"
    config.istio.io/pilotCfgStore: True
    config.istio.io/accessConfigFile: "falkor07.kube.conf"
  spec:
    kubernetesApiEndpoints:
      serverEndpoints:
        - clientCIDR: "10.23.230.0/28"
          serverAddress: "10.23.230.11"
```

A unique security context is required to describe how to securely access
each Kubernetes cluster in the system.  In the above example,
`falkor07.kube.conf` is the Istio control plane credential file. The
config.istio.io/pilotCfgStore = `True` since this is the Istio control plane.
For remotes, pilotCfgStore should = `False`.

**Important**: The implementation only uses the
`config.istio.io/pilotCfgStore` and `config.istio.io/accessConfigFile`
annotations, although every other annotation and spec is validated for
correct syntax.  They may be set to dummy values, as long as they are
syntactically correct.

If the prequisites are met, the credentials for each Kubernetes cluster
will also be present in `$HOME/multicluster`.

Assemble and create the configmap from these files in the Kubernetes cluster
where the Istio control plane is operational:

```bash
kubectl create configmap -n istio-system multicluster -f $HOME/multicluster
```

## Deploy on the remote cluster

Multicluster makes **one** Istio service mesh from all Kubernetes clusters
that participate in multicluster.  Multicluster uses **one** Kubernetes
cluster to run the Istio control plane.  **Any reasonable** number of remote
Kubernetes clusters may be attached to the **one** Istio control plane.

### Use kubectl with Helm to connect the remote cluster

1. Use the helm template command on a remote to specify the Istio control plane:

   ```bash
   helm template install/kubernetes/helm/istio-remote --name istio-remote --set pilotEndpoint=`pod_ip_of_pilot_master` --set mixerEndpoint=`pod_ip_of_mixer_master` > $HOME/istio-remote.yaml
    ```

1. Instantiate the remote cluster's connection to the Istio control plane:

   ```bash
   kubectl create -f $HOME/istio-remote.yaml
   ```

### Alternatively use Helm and Tiller to connect the remote cluster

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
   helm install install/kubernetes/helm/istio-remote --name istio-remote --set pilotEndpoint=pod_ip_of_pilot_master --set mixerEndpoint=pod_ip_of_mixer_master`
   ```

### Mandatory Helm configuration parameters

The isito-remote Helm chart requires the configuration of two specific variables defined in the following table:

**Note** The `pilotEndpoint` and `mixerEndpoint` need to be resolvable via
Kubernetes.

| Helm Variable | Accepted Values | Default | Purpose of Value |
| --- | --- | --- | --- |
| `global.pilotEndpoint` | A valid IPv4 address | none | Specifies the Istio control plane's pilot Pod IP address |
| `global.mixerEndpoint` | A valid IPv4 address | none | Specifies the Istio control plane's mixer Pod IP address |

## Uninstalling

** Note the uninstallation method must match the installation method (`kubectl` or `tiller` based) **

### Using kubectl to uninstall the istio-remote

* Uninstall an Istio remote:

  ```bash
  kubectl delete -f $HOME/istio-remote.yaml
  ```

### Using tiller to uninstall the istio-remote

  ```bash
  helm delete --purge istio-remote
  ```
