---
title: Istio Multicluster
description: Install Istio with multicluster support.
weight: 65
keywords: [kubernetes,multicluster]
---

Instructions for the installation of Istio multicluster.

## Prerequisites

* Two or more Kubernetes clusters with **1.7.3 or newer**.

* The ability to deploy the [Istio control plane](/docs/setup/kubernetes/quick-start/)
on **one** Kubernetes cluster.

*   The usage of an RFC1918 network, VPN, or alternative more advanced network techniques
to meet the following requirements:

    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique
across the multicluster environment and may not overlap.

    * All pod CIDRs in every cluster must be routable to each other.

    * All Kubernetes control plane API servers must be routable to each other.

* Helm **2.7.2 or newer**.  The use of Tiller is optional.

* Currently only [manual sidecar injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection)
has been validated with multicluster.

## Caveats and known problems

{{< warning_icon >}}
All known caveats and known problems with multicluster for the 0.8 release are [tracked here](https://github.com/istio/istio/issues/4822).

## Overview

Multicluster functions by enabling Kubernetes control planes running
a remote configuration to connect to **one** Istio control plane.
Once one or more remote Kubernetes clusters are connected to the
Istio control plane, Envoy can then communicate with the **single**
Istio control plane and form a mesh network across multiple Kubernetes
clusters.

## Create service account in remote clusters and generate `kubeconfigs`

The Istio control plane requires access to all clusters in the mesh to
discover services, endpoints, and pod attributes.  The following
describes how to create a Kubernetes service account in a remote cluster with
the minimal RBAC access required.  The procedure then generates a `kubeconfig`
file for the remote cluster using the credentials of the service account.

The following procedure should be performed on each remote cluster to be
added to the service mesh.  The procedure requires cluster-admin user access
to the remote cluster.

1. Create a `ClusterRole` named `istio-reader` for the Istio control plane access:

     ```command
      cat <<EOF | kubectl  create -f -
      kind: ClusterRole
      apiVersion: rbac.authorization.k8s.io/v1
      metadata:
        name: istio-reader
      rules:
         - apiGroups: ['']
           resources: ['nodes', 'pods', 'services', 'endpoints']
           verbs: ['get', 'watch', 'list']
    EOF
    ```

1.  Create a `ServiceAccount` named `istio-multi` for the Istio control plane:

    ```command
    $ export SERVICE_ACCOUNT=istio-multi
    $ export NAMESPACE=istio-system
    $ kubectl create ns ${NAMESPACE}
    $ kubectl create sa ${SERVICE_ACCOUNT} -n ${NAMESPACE}
    ```

1.  Bind the `ServiceAccount` named `istio-multi` to the `ClusterRole` named `istio-reader`:

    ```command
    $ kubectl create clusterrolebinding istio-multi --clusterrole=istio-reader --serviceaccount=${NAMESPACE}:${SERVICE_ACCOUNT}
    ```

1.  Prepare environment variables for building the `kubeconfig` file for `ServiceAccount` `istio-multi`:

    ```command
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    ```

    __NOTE__: An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.

1. Create a `kubeconfig` file in the working directory for the `ServiceAccount` `istio-multi`:

     ```command
      cat <<EOF > ${KUBECFG_FILE}
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
    ```

At this point, the remote clusters' `kubeconfig` files have been created in the current directory.
The filename for a cluster is the same as the original `kubeconfig` cluster name.

## Instantiate the credentials for each remote cluster

> Execute this work on the cluster intended to run the Istio control
plane.

> Istio can be installed in a different namespace other than
istio-system.

Create a namespace for instantiating the secrets:

```command
$ kubectl create ns istio-system
```

> You can create the secrets either before or after deploying the Istio control
plane. Creating secrets will register the secrets with Istio properly.

> The local cluster running the Istio control plane does not need
it's secrets stored and labeled. The local node is always aware of
its Kubernetes credentials, but the local node is not aware of
the remote nodes' credentials.

Create a secret and label it properly for each remote cluster:

```command
$ cd $WORK_DIR
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n istio-system
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n istio-system
```

{{< warning_icon >}}
The secret name and the corresponding file name need to be the same.  Kubernetes secret
data keys have to conform to `DNS-1123 subdomain`
[format](https://tools.ietf.org/html/rfc1123#page-13), so the filename can't have
underscores for example.  To resolve any issue you can simply change the filename and
secret name to conform to the format.

## Deploy the local Istio control plane

Install the [Istio control plane](/docs/setup/kubernetes/quick-start/#installation-steps)
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

> As decumented in [tracked here](https://github.com/istio/istio/issues/4822),
if any one of the endpoints in below restarts, then connection from remote
clusters to that endpoint will be broken. See [Stable access to istio control
plane services](#stable-access-to-istio-control-plane-services] for details on
how to avoid it.

```command
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
$ export STATSD_POD_IP=$(kubectl -n istio-system get pod -l istio=statsd-prom-bridge -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
$ export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].status.podIP}')
```

### Use kubectl with Helm to connect the remote cluster to the local

1.  Use the helm template command on a remote to specify the Istio control plane service endpoints:

    ```command
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.pilotEndpoint=${PILOT_POD_IP} --set global.policyEndpoint=${POLICY_POD_IP} --set global.statsdEndpoint=${STATSD_POD_IP} --set global.telemetryEndpoint=${TELEMETRY_POD_IP} --set global.zipkinEndpoint=${ZIPKIN_POD_IP} > $HOME/istio-remote.yaml
    ```

1.  Create a namespace for remote Istio.

    ```command
    $ kubectl create ns istio-system
    ```

1.  Instantiate the remote cluster's connection to the Istio control plane:

    ```command
    $ kubectl create -f $HOME/istio-remote.yaml
    ```

### Alternatively use Helm and Tiller to connect the remote cluster to the local

1.  If a service account has not already been installed for Helm, please
install one:

    ```command
    $ kubectl create -f @install/kubernetes/helm/helm-service-account.yaml@
    ```

1.  Initialize Helm:

    ```command
    $ helm init --service-account tiller
    ```

1.  Install the Helm chart:

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
| --- | --- | --- | --- |https://istio.io/docs/setup/kubernetes/multicluster-install/
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

## Stable access to istio control plane services

In the above procedure, endpoint IPs of istio services are gathered and used to
invoke helm that will create istio services on the remote clusters. As a result,
kube-dns in the remote clusters can be used to resolve the istio service names.
Since Kubernetes pods don't have stable IPs, restart of any istio service pod in
the control plane cluster will cause its endpoint to be changed. Therefore, any
connection made from remote clusters to that endpoint will be broken. One way to
fix it is to rerun the helm install and have the istio services on the remote
clusters to be updated with the new endpoints. Thus, kube-dns will be updated as
well. However, it requires manual intervention and may still causes service
disruption.

In addition, some deployments may choose to deploy multiple instances of an
istio service such as pilot. In that case, accessing an istio service with only
one of its endpoints doesn't even make sense any more.

In this guide, we'll describe how to use load balancer service type to stable
access to the istio control plane services.

### Use load balancer service type

In Kubernetes, you can declare a service with a service type to be [load
balancer](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types).
A simple solution to the pod restart issue is to use load balancers for the
istio services. You can then use the load balancer IPs as the istio services's
endpoint IPs to configure the remote clusters. You may need balancer IPs for
these istio services: `istio-pilot, istio-telemetry, istio-policy,
istio-statsd-prom-bridge, zipkin`

Currenly, istio installation doesn't provide an option to specify service types
for the istio services. But you can modify the istio helm charts or manifests
yourself as described in below.

#### Modify the istio helm charts or istio manifests

The helm charts are located at ./install/kubernetes/helm/istio/charts/. To
use load balancer for pilot, for example, modify
./install/kubernetes/helm/istio/charts/pilot/templates/service.yaml as in
below:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: istio-pilot
  namespace: {{ .Release.Namespace }}
  labels:
    app: istio-pilot
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  ports:
  - port: 15003
    name: http-old-discovery # mTLS or non-mTLS depending on auth setting
  - port: 15005
    name: https-discovery # always mTLS
  - port: 15007
    name: http-discovery # always plain-text
  - port: 15010
    name: grpc-xds # direct
  - port: 15011
    name: https-xds # mTLS
  - port: 8080
    name: http-legacy-discovery # direct
  - port: 9093
    name: http-monitoring
  selector:
    istio: pilot
  type: LoadBalancer
```

Noticed that `type: LoadBalancer` at the end of the file.

Similarly, you can modify istio-telemetry, istio-policy,
istio-statsd-prom-bridge, zipkin to use load balancer.

You can then follow the [helm installation
process](/docs/setup/kubernetes/helm-install) to install istio.

You can also manually change istio manifests to achieve the same. When following
the [istio installation
steps](/docs/setup/kubernetes/quick-start/#installation-steps), before applying
the istio manifest, locate service definitions for the istio services in
istio-demo.yaml (or istio-demo-auth.yaml), and add `type: LoadBalancer` for the
istio services.
