---
title: Multicluster Installation
description: Install an Istio mesh across multiple Kubernetes clusters.
weight: 30
aliases:
    - /docs/setup/kubernetes/multicluster-install/
    - /docs/setup/kubernetes/multicluster/
    - /docs/setup/kubernetes/install/multicluster/
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
When installing Istio across multiple clusters, there are more things to
consider than with a [single cluster installation](/docs/setup/getting-started).

Although there is no default installation procedure for a multicluster mesh, as it will
be different based on your cluster and network architecture, this guide covers some
of the most common concerns:

- [Network topologies](/docs/ops/deployment/deployment-models#network-models):
  one or two networks

- [Control plane topologies](/docs/ops/deployment/deployment-models#control-plane-models):
  multi-primary, primary-remote

Before you begin, review the [deployment models guide](/docs/ops/deployment/deployment-models)
which describes the foundational concepts used throughout this guide.

## Requirements

This guide requires that you have two Kubernetes clusters with any of the
[supported versions](/docs/setup/platform-setup).

If the clusters are on different networks (i.e. no direct connectivity between
pods on different clusters), they must have ingress gateway services which are
accessible from the other cluster, ideally using L4 network load balancers
(NLBs). Not all cloud providers support NLBs and some require special
annotations to use them, so please consult your cloud provider’s documentation
for enabling NLBs for service object type load balancers. When deploying on
platforms without NLB support, it may be necessary to modify the health checks
for the load balancer to register the ingress gateway.

## Environment Variables

This guide will refer to two clusters named `FRED` and `BARNEY`. The following
environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_FRED` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `FRED` cluster.
`CTX_BARNEY` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `BARNEY` cluster.

For example:

{{< text bash >}}
$ export CTX_FRED=cluster-fred
$ export CTX_BARNEY=cluster-barney
{{< /text >}}

## Configure Trust

A multicluster service mesh deployment requires that you establish trust
between all clusters in the mesh. Depending on the requirements for your
system, there may be multiple options available for establishing trust.
See [certificate management](/docs/tasks/security/cert-management/) for
detailed descriptions and instructions for all available options.
Depending on which option you choose, the installation instructions for
Istio may change slightly.

This guide will assume that you use a common root to generate intermediate
certificates for each cluster. Follow the [instructions](/docs/tasks/security/cert-management/plugin-ca-cert/)
to generate and push a secret to both the `FRED` and `BARNEY` clusters.

{{< tip >}}
If you currently have a single cluster with a self-signed CA (as described
in [Getting Started](/docs/setup/getting-started/)), you’ll need to
[change the CA](/docs/tasks/security/cert-management/) to support multiple
clusters and then reinstall Istio using the standard installation
instructions below.
{{< /tip >}}

## Install Istio

The steps for installing Istio on multiple clusters depend on your
requirements for network and control plane topology. This section
illustrates the options for two clusters. Large systems may employ more
than one of these options for meshes that span many clusters. See
[deployment models](/docs/ops/deployment/deployment-models) for more
information.

{{< tabset category-name="install-istio" >}}

{{< tab name="Multi-Primary" category-value="multi-primary" >}}

The steps that follow will install the Istio control plane on both `FRED` and
`BARNEY`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. Both
clusters reside on the `EAST` network.

Each control plane observes the API Servers in both clusters for endpoints.
Service workloads communicate directly (pod-to-pod) across cluster boundaries.

{{< image width="75%"
    link="multi-primary.svg"
    caption="Multiple primary clusters on the same network"
    >}}

### Configure `FRED` as a primary

Install Istio on `FRED`:

{{< text bash >}}
$ istioctl --context=${CTX_FRED} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: EAST
      meshNetworks:
        EAST:
          endpoints:
          - fromRegistry: FRED
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

### Configure `BARNEY` as a primary

Install Istio on `BARNEY`:

{{< text bash >}}
$ istioctl --context=${CTX_BARNEY} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      meshNetworks:
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

### Enable Endpoint Discovery

Install a remote secret in `BARNEY` that provides access to `FRED`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_FRED} \
    --name=FRED | \
    kubectl apply -f - --context=${CTX_BARNEY}
{{< /text >}}

Install a remote secret in `FRED` that provides access to `BARNEY`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
{{< /text >}}

{{< /tab >}}

{{< tab name="Multi-Primary, Multi-Network" category-value="multi-primary-multi-network" >}}

The following steps will install the Istio control plane on both `FRED` and
`BARNEY`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. `FRED` is
on the `WEST` network, while `BARNEY` is on the `EAST` network.

Both `FRED` and `BARNEY` observe the API Servers in each cluster for endpoints.
Service workloads across cluster boundaries communicate indirectly, via
dedicated gateways for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic.

{{< image width="75%"
    link="multi-primary-multi-network.svg"
    caption="Multiple primary clusters on separate networks"
    >}}

### Configure `FRED` as a primary with services exposed

Install Istio on `FRED`:

{{< text bash >}}
$ istioctl --context=${CTX_FRED} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: WEST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

Install a gateway in `FRED` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
{{< /text >}}

Since the clusters are on separate networks, we need to expose all services
(*.local) on the east-west gateway in both clusters. While this gateway is
public on the Internet, services behind it can only be accessed by services
with a trusted mTLS certificate and workload ID, just as if they were on the
same network.

{{< text bash >}}
$ kubectl --context=${CTX_FRED} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

### Configure `BARNEY` as a primary with services exposed

Install Istio on `BARNEY`:

{{< text bash >}}
$ istioctl --context=${CTX_BARNEY} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

As we did with `FRED` above, install a gateway in `BARNEY` that is dedicated
to east-west traffic and expose user services.

{{< text bash >}}
$ CLUSTER=BARNEY NETWORK=EAST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_BARNEY} -f -
{{< /text >}}

{{< text bash >}}
$ kubectl --context=${CTX_BARNEY} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

### Enable Endpoint Discovery for `FRED` and `BARNEY`

Install a remote secret in `BARNEY` that provides access to `FRED`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
  --context=${CTX_FRED} \
  --name=FRED | \
  kubectl apply -f - --context=${CTX_BARNEY}
{{< /text >}}

Install a remote secret in `FRED` that provides access to `BARNEY`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
  --context=${CTX_BARNEY} \
  --name=BARNEY | \
  kubectl apply -f - --context=${CTX_FRED}
{{< /text >}}

{{< /tab >}}

{{< tab name="Primary-Remote" category-value="primary-remote" >}}

The following steps will install the Istio control plane on `FRED` (the
{{< gloss >}}primary cluster{{< /gloss >}}) and configure `BARNEY` (the
{{< gloss >}}remote cluster{{< /gloss >}}) to use the control plane in `FRED`. Both
clusters reside on the `EAST` network.

`FRED` will be configured to observe the API Servers in both clusters for
endpoints. In this way, the control plane will be able to provide service
discovery for workloads in both clusters. Service workloads across cluster
boundaries communicate indirectly, via dedicated
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateways.

{{< image width="75%"
    link="primary-remote.svg"
    caption="Primary and remote clusters on the same network"
    >}}

### Configure `FRED` as a primary with control plane exposed

Install Istio on `FRED`:

{{< text bash >}}
$ istioctl --context=${CTX_FRED} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: EAST
      meshNetworks:
        ${NETWORK1}:
          endpoints:
          - fromRegistry: FRED
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

Install a gateway in the `FRED` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
{{< /text >}}

Before we can install on `BARNEY`, we need to first expose the control plane in
`FRED` so that services in `BARNEY` will be able to access service discovery:

{{< text bash >}}
$ kubectl apply --context=${CTX_FRED} -f \
    samples/multicluster/expose-istiod.yaml
{{< /text >}}

### Configure `BARNEY` as a remote

Save the address of `FRED`’s ingress gateway.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_FRED} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Now install a remote configuration on `BARNEY`.

{{< text bash >}}
$ istioctl --context=${CTX_BARNEY} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

### Enable Endpoint Discovery for `BARNEY`

Create a remote secret that will allow the control plane in `FRED` to access the
API Server in `BARNEY` for endpoints.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
{{< /text >}}

{{< /tab >}}

{{< tab name="Primary-Remote, Multi-Network" category-value="primary-remote-multi-network" >}}

The following steps will install the Istio control plane on `FRED` (the
{{< gloss >}}primary cluster{{< /gloss >}}) and configure `BARNEY` (the
{{< gloss >}}remote cluster{{< /gloss >}}) to use the control plane in `FRED`.
`FRED` is on the `WEST` network, while `BARNEY` is on the `EAST` network.

`FRED` will be configured to observe the API Servers in both clusters for
endpoints. In this way, the control plane will be able to provide service
discovery for workloads in both clusters.

Services in the `BARNEY` will reach the control plane in the `FRED` via a dedicated
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway.

Service workloads across cluster boundaries communicate indirectly, via
the dedicated gateways for east-west traffic.

{{< image width="75%"
    link="primary-remote-multi-network.svg"
    caption="Primary and remote clusters on separate networks"
    >}}

### Configure `FRED` as a primary with control plane and services exposed

{{< text bash >}}
$ istioctl --context=${CTX_FRED} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: WEST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
{{< /text >}}

Install a gateway in `FRED` that is dedicated to east-west traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
{{< /text >}}

Before we can install on `BARNEY`, we need to first expose the control plane in
`FRED` so that services in `BARNEY` will be able to access service discovery:

{{< text bash >}}
$ kubectl apply --context=${CTX_FRED} -f \
    samples/multicluster/expose-istiod.yaml
{{< /text >}}

Since the clusters are on separate networks, we also need to expose all user
services (*.local) on the east-west gateway in both clusters. While this
gateway is public on the Internet, services behind it can only be accessed by
services with a trusted mTLS certificate and workload ID, just as if they were
on the same network.

{{< text bash >}}
$ kubectl --context=${CTX_FRED} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

### Configure `BARNEY` as a remote with services exposed

Save the address of `FRED`’s ingress gateway.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_FRED} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Now install a remote configuration on `BARNEY`.

{{< text bash >}}
$ istioctl --context=${CTX_BARNEY} -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

As we did with `FRED` above, install a gateway in `BARNEY` that is dedicated
to east-west traffic and expose user services.

{{< text bash >}}
$ CLUSTER=BARNEY NETWORK=EAST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_BARNEY} -f -
{{< /text >}}

{{< text bash >}}
$ kubectl --context=${CTX_BARNEY} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

### Enable Endpoint Discovery for `BARNEY` on `EAST`

Create a remote secret that will allow the control plane in `FRED` to access the API Server in `BARNEY` for endpoints.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Verify the Installation

To verify that your Istio installation is working as intended, we will deploy
the `HelloWorld` application `V1` to `FRED` and `V2` to `BARNEY`. Upon receiving a
request, `HelloWorld` will include its version in its response.

We will also deploy the `Sleep` container to both clusters. We will use these
pods as the source of requests to the `HelloWorld` service,
simulating in-mesh traffic. Finally, after generating traffic, we will observe
which cluster received the requests.

### Deploy the `HelloWorld` Service

In order to make the `HelloWorld` service callable from any cluster, the DNS
lookup must succeed in each cluster (see
[deployment models](/docs/ops/deployment/deployment-models#dns-with-multiple-clusters)
for details). We will address this by deploying the `HelloWorld` Service to
each cluster in the mesh.

To begin, create the `sample` namespace in each cluster:

{{< text bash >}}
$ kubectl create --context=${CTX_FRED} namespace sample
$ kubectl create --context=${CTX_BARNEY} namespace sample
{{< /text >}}

Enable automatic sidecar injection for the `sample` namespace:

{{< text bash >}}
$ kubectl label --context=${CTX_FRED} namespace sample \
    istio-injection=enabled
$ kubectl label --context=${CTX_BARNEY} namespace sample \
    istio-injection=enabled
{{< /text >}}

Deploy the `HelloWorld` service to both clusters:

{{< text bash >}}
$ kubectl apply --context=${CTX_FRED} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
$ kubectl apply --context=${CTX_BARNEY} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
{{< /text >}}

### Deploy `HelloWorld` `V1`

Deploy the `helloworld-v1` application to `FRED`:

{{< text bash >}}
$ kubectl apply --context=${CTX_FRED} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v1 -n sample
{{< /text >}}

Confirm the `helloworld-v1` pod status:

{{< text bash >}}
$ kubectl get pod --context=${CTX_FRED} -n sample
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v1` is `Running`.

### Deploy `HelloWorld` `V2`

Deploy the `helloworld-v2` application to `BARNEY`:

{{< text bash >}}
$ kubectl apply --context=${CTX_BARNEY} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v2 -n sample
{{< /text >}}

Confirm the status the `helloworld-v2` pod status:

{{< text bash >}}
$ kubectl get pod --context=${CTX_BARNEY} -n sample
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v2` is `Running`.

### Deploy `Sleep`

Deploy the `Sleep` application to both clusters:

{{< text bash >}}
$ kubectl apply --context=${CTX_FRED} \
    -f samples/sleep/sleep.yaml -n sample
$ kubectl apply --context=${CTX_BARNEY} \
    -f samples/sleep/sleep.yaml -n sample
{{< /text >}}

Confirm the status `Sleep` pod on `FRED`:

{{< text bash >}}
$ kubectl get pod --context=${CTX_FRED} -n sample -l app=sleep
sleep-754684654f-n6bzf           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

Confirm the status of the `Sleep` pod on `BARNEY`:

{{< text bash >}}
$ kubectl get pod --context=${CTX_BARNEY} -n sample -l app=sleep
sleep-754684654f-dzl9j           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

### Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the
`HelloWorld` service several times using the `Sleep` pod. To ensure load
balancing is working properly, call the `HelloWorld` service from all
clusters in your deployment.

Send one request from the `Sleep` pod on `FRED` to the `HelloWorld` service:

{{< text bash >}}
$ kubectl exec --context=${CTX_FRED} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_FRED} -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should toggle between `v1` and `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

Now repeat this process from the `Sleep` pod on `BARNEY`:

{{< text bash >}}
$ kubectl exec --context=${CTX_BARNEY} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_BARNEY} -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
{{< /text >}}

Repeat this request several times and verify that the `HelloWorld` version
should toggle between `v1` and `v2`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

**Congratulations!** You successfully installed and verified Istio on multiple
clusters!
