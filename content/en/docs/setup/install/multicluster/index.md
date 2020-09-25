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
Follow this guide to install an Istio {{< gloss >}}service mesh{{< /gloss >}}
that spans multiple {{< gloss "cluster" >}}clusters{{< /gloss >}}.

This guide covers some of the most common concerns when creating a
{{< gloss >}}multicluster{{< /gloss >}} mesh:

- [Network topologies](/docs/ops/deployment/deployment-models#network-models):
  one or two networks

- [Control plane topologies](/docs/ops/deployment/deployment-models#control-plane-models):
  multi-primary, primary-remote

Before you begin, review the [deployment models guide](/docs/ops/deployment/deployment-models)
which describes the foundational concepts used throughout this guide.

## Requirements

This guide requires that you have two Kubernetes clusters with any of the
[supported Kubernetes versions](/docs/setup/platform-setup).

The API Server in each cluster must be accessible to the other clusters in the
mesh. Many cloud providers make API Servers publicly accessible via network
load balancers (NLB). If the API Server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations below could also be used
to enable access to the API Server.

## Environment Variables

This guide will refer to two clusters named `CLUSTER1` and `CLUSTER2`. The following
environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_CLUSTER1` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `CLUSTER1` cluster.
`CTX_CLUSTER2` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the `CLUSTER2` cluster.

For example:

{{< text bash >}}
$ export CTX_CLUSTER1=cluster1
$ export CTX_CLUSTER2=cluster2
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
to generate and push a ca certificate secrets to both the `CLUSTER1` and `CLUSTER2`
clusters.

{{< tip >}}
If you currently have a single cluster with a self-signed CA (as described
in [Getting Started](/docs/setup/getting-started/)), you need to
change the CA using one of the methods described in
[certificate management](/docs/tasks/security/cert-management/). Changing the
CA typically requires reinstalling Istio. The installation instructions
below may have to be altered based on your choice of CA.
{{< /tip >}}

## Install Istio

The steps for installing Istio on multiple clusters depend on your
requirements for network and control plane topology. This section
illustrates the options for two clusters. Meshes that span many clusters may
employ more than one of these options. See
[deployment models](/docs/ops/deployment/deployment-models) for more
information.

{{< tabset category-name="install-istio" >}}

{{< tab name="Multi-Primary" category-value="multi-primary" >}}

The steps that follow will install the Istio control plane on both `CLUSTER1` and
`CLUSTER2`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. Both
clusters reside on the `NETWORK1` network, meaning there is direct
connectivity between the pods in both clusters.

Each control plane observes the API Servers in both clusters for endpoints.

Service workloads communicate directly (pod-to-pod) across cluster boundaries.

{{< image width="75%"
    link="multi-primary.svg"
    caption="Multiple primary clusters on the same network"
    >}}

<h3>Configure CLUSTER1 as a primary</h3>

Install Istio on `CLUSTER1`:

{{< text bash >}}
$ cat <<EOF > ./cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER1
      network: NETWORK1
      meshNetworks:
        NETWORK1:
          endpoints:
          - fromRegistry: CLUSTER1
          - fromRegistry: CLUSTER2
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER1} -f cluster1.yaml
{{< /text >}}

<h3>Configure CLUSTER2 as a primary</h3>

Install Istio on `CLUSTER2`:

{{< text bash >}}
$ cat <<EOF > ./cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER2
      network: NETWORK1
      meshNetworks:
        NETWORK1:
          endpoints:
          - fromRegistry: CLUSTER2
          - fromRegistry: CLUSTER1
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER2} -f cluster2.yaml
{{< /text >}}

<h3>Enable Endpoint Discovery</h3>

Install a remote secret in `CLUSTER2` that provides access to `CLUSTER1`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_CLUSTER1} \
    --name=CLUSTER1 | \
    kubectl apply -f - --context=${CTX_CLUSTER2}
{{< /text >}}

Install a remote secret in `CLUSTER1` that provides access to `CLUSTER2`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_CLUSTER2} \
    --name=CLUSTER2 | \
    kubectl apply -f - --context=${CTX_CLUSTER1}
{{< /text >}}

{{< /tab >}}

{{< tab name="Multi-Primary, Multi-Network" category-value="multi-primary-multi-network" >}}

The following steps will install the Istio control plane on both `CLUSTER1` and
`CLUSTER2`, making each a {{< gloss >}}primary cluster{{< /gloss >}}. `CLUSTER1` is
on the `NETWORK1` network, while `CLUSTER2` is on the `NETWORK2` network. This means there
is no direct connectivity between pods across cluster boundaries.

Both `CLUSTER1` and `CLUSTER2` observe the API Servers in each cluster for endpoints.

Service workloads across cluster boundaries communicate indirectly, via
dedicated gateways for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic. The gateway in each cluster must be reachable from the other cluster.

{{< image width="75%"
    link="multi-primary-multi-network.svg"
    caption="Multiple primary clusters on separate networks"
    >}}

<h3>Configure CLUSTER1 as a primary with services exposed</h3>

Install Istio on `CLUSTER1`:

{{< text bash >}}
$ cat <<EOF > ./cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER1
      network: NETWORK1
      meshNetworks:
        NETWORK1:
          endpoints:
          - fromRegistry: CLUSTER1
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        NETWORK2:
          endpoints:
          - fromRegistry: CLUSTER2
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER1} -f cluster1.yaml
{{< /text >}}

Install a gateway in `CLUSTER1` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=CLUSTER1 NETWORK=NETWORK1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_CLUSTER1} -f -
{{< /text >}}

Since the clusters are on separate networks, we need to expose all services
(*.local) on the east-west gateway in both clusters. While this gateway is
public on the Internet, services behind it can only be accessed by services
with a trusted mTLS certificate and workload ID, just as if they were on the
same network.

{{< text bash >}}
$ kubectl --context=${CTX_CLUSTER1} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

<h3>Configure CLUSTER2 as a primary with services exposed</h3>

Install Istio on `CLUSTER2`:

{{< text bash >}}
$ cat <<EOF > ./cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER2
      network: NETWORK2
      meshNetworks:
        NETWORK1:
          endpoints:
          - fromRegistry: CLUSTER1
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        NETWORK2:
          endpoints:
          - fromRegistry: CLUSTER2
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER2} -f cluster2.yaml
{{< /text >}}

As we did with `CLUSTER1` above, install a gateway in `CLUSTER2` that is dedicated
to east-west traffic and expose user services.

{{< text bash >}}
$ CLUSTER=CLUSTER2 NETWORK=NETWORK2 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_CLUSTER2} -f -
{{< /text >}}

{{< text bash >}}
$ kubectl --context=${CTX_CLUSTER2} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

<h3>Enable Endpoint Discovery for CLUSTER1 and CLUSTER2</h3>

Install a remote secret in `CLUSTER2` that provides access to `CLUSTER1`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
  --context=${CTX_CLUSTER1} \
  --name=CLUSTER1 | \
  kubectl apply -f - --context=${CTX_CLUSTER2}
{{< /text >}}

Install a remote secret in `CLUSTER1` that provides access to `CLUSTER2`’s API server.

{{< text bash >}}
$ istioctl x create-remote-secret \
  --context=${CTX_CLUSTER2} \
  --name=CLUSTER2 | \
  kubectl apply -f - --context=${CTX_CLUSTER1}
{{< /text >}}

{{< /tab >}}

{{< tab name="Primary-Remote" category-value="primary-remote" >}}

The following steps will install the Istio control plane on `CLUSTER1` (the
{{< gloss >}}primary cluster{{< /gloss >}}) and configure `CLUSTER2` (the
{{< gloss >}}remote cluster{{< /gloss >}}) to use the control plane in `CLUSTER1`.
Both clusters reside on the `NETWORK1` network, meaning there is direct
connectivity between the pods in both clusters.

`CLUSTER1` will be configured to observe the API Servers in both clusters for
endpoints. In this way, the control plane will be able to provide service
discovery for workloads in both clusters.

Service workloads communicate directly (pod-to-pod) across cluster boundaries.

Services in `CLUSTER2` will reach the control plane in `CLUSTER1` via a
dedicated gateway for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic.

{{< image width="75%"
    link="primary-remote.svg"
    caption="Primary and remote clusters on the same network"
    >}}

<h3>Configure CLUSTER1 as a primary with control plane exposed</h3>

Install Istio on `CLUSTER1`:

{{< text bash >}}
$ cat <<EOF > ./cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER1
      network: NETWORK1
      meshNetworks:
        ${NETWORK1}:
          endpoints:
          - fromRegistry: CLUSTER1
          - fromRegistry: CLUSTER2
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER1} -f cluster1.yaml
{{< /text >}}

Install a gateway in `CLUSTER1` that is dedicated to
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=CLUSTER1 NETWORK=NETWORK1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_CLUSTER1} -f -
{{< /text >}}

Before we can install on `CLUSTER2`, we need to first expose the control plane in
`CLUSTER1` so that services in `CLUSTER2` will be able to access service discovery:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER1} -f \
    samples/multicluster/expose-istiod.yaml
{{< /text >}}

<h3>Configure CLUSTER2 as a remote</h3>

Save the address of `CLUSTER1`’s ingress gateway.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_CLUSTER1} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Now install a remote configuration on `CLUSTER2`.

{{< text bash >}}
$ cat <<EOF > ./cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER2
      network: NETWORK1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
$ istioctl install --context=${CTX_CLUSTER2} -f cluster2.yaml
{{< /text >}}

<h3>Enable Endpoint Discovery for CLUSTER2</h3>

Create a remote secret that will allow the control plane in `CLUSTER1` to access the
API Server in `CLUSTER2` for endpoints.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_CLUSTER2} \
    --name=CLUSTER2 | \
    kubectl apply -f - --context=${CTX_CLUSTER1}
{{< /text >}}

{{< /tab >}}

{{< tab name="Primary-Remote, Multi-Network" category-value="primary-remote-multi-network" >}}

The following steps will install the Istio control plane on `CLUSTER1` (the
{{< gloss >}}primary cluster{{< /gloss >}}) and configure `CLUSTER2` (the
{{< gloss >}}remote cluster{{< /gloss >}}) to use the control plane in `CLUSTER1`.
`CLUSTER1` is on the `NETWORK1` network, while `CLUSTER2` is on the `NETWORK2` network.
This means there is no direct connectivity between pods across cluster
boundaries.

`CLUSTER1` will be configured to observe the API Servers in both clusters for
endpoints. In this way, the control plane will be able to provide service
discovery for workloads in both clusters.

Service workloads across cluster boundaries communicate indirectly, via
dedicated gateways for [east-west](https://en.wikipedia.org/wiki/East-west_traffic)
traffic. The gateway in each cluster must be reachable from the other cluster.

Services in `CLUSTER2` will reach the control plane in `CLUSTER1` via the
same east-west gateway.

{{< image width="75%"
    link="primary-remote-multi-network.svg"
    caption="Primary and remote clusters on separate networks"
    >}}

<h3>Configure CLUSTER1 as a primary with control plane and services exposed</h3>

{{< text bash >}}
$ cat <<EOF > ./cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER1
      network: NETWORK1
      meshNetworks:
        NETWORK1:
          endpoints:
          - fromRegistry: CLUSTER1
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        NETWORK2:
          endpoints:
          - fromRegistry: CLUSTER2
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
$ istioctl install --context=${CTX_CLUSTER1} -f cluster1.yaml
{{< /text >}}

Install a gateway in `CLUSTER1` that is dedicated to east-west traffic. By
default, this gateway will be public on the Internet. Production systems may
require additional access restrictions (e.g. via firewall rules) to prevent
external attacks. Check with your cloud vendor to see what options are
available.

{{< text bash >}}
$ CLUSTER=CLUSTER1 NETWORK=NETWORK1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_CLUSTER1} -f -
{{< /text >}}

Before we can install on `CLUSTER2`, we need to first expose the control plane in
`CLUSTER1` so that services in `CLUSTER2` will be able to access service discovery:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER1} -f \
    samples/multicluster/expose-istiod.yaml
{{< /text >}}

Since the clusters are on separate networks, we also need to expose all user
services (*.local) on the east-west gateway in both clusters. While this
gateway is public on the Internet, services behind it can only be accessed by
services with a trusted mTLS certificate and workload ID, just as if they were
on the same network.

{{< text bash >}}
$ kubectl --context=${CTX_CLUSTER1} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

<h3>Configure CLUSTER2 as a remote with services exposed</h3>

Save the address of `CLUSTER1`’s ingress gateway.

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_CLUSTER1} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

Now install a remote configuration on `CLUSTER2`.

{{< text bash >}}
$ cat <<EOF > ./cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: MESH1
      multiCluster:
        clusterName: CLUSTER2
      network: NETWORK2
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
$ istioctl install --context=${CTX_CLUSTER2} -f - cluster2.yaml
{{< /text >}}

As we did with `CLUSTER1` above, install a gateway in `CLUSTER2` that is dedicated
to east-west traffic and expose user services.

{{< text bash >}}
$ CLUSTER=CLUSTER2 NETWORK=NETWORK2 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_CLUSTER2} -f -
{{< /text >}}

{{< text bash >}}
$ kubectl --context=${CTX_CLUSTER2} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
{{< /text >}}

<h3>Enable Endpoint Discovery for CLUSTER2 on NETWORK2</h3>

Create a remote secret that will allow the control plane in `CLUSTER1` to access the API Server in `CLUSTER2` for endpoints.

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context=${CTX_CLUSTER2} \
    --name=CLUSTER2 | \
    kubectl apply -f - --context=${CTX_CLUSTER1}
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Verify the Installation

To verify that your Istio installation is working as intended, we will deploy
the `HelloWorld` application `V1` to `CLUSTER1` and `V2` to `CLUSTER2`. Upon receiving a
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
$ kubectl create --context=${CTX_CLUSTER1} namespace sample
$ kubectl create --context=${CTX_CLUSTER2} namespace sample
{{< /text >}}

Enable automatic sidecar injection for the `sample` namespace:

{{< text bash >}}
$ kubectl label --context=${CTX_CLUSTER1} namespace sample \
    istio-injection=enabled
$ kubectl label --context=${CTX_CLUSTER2} namespace sample \
    istio-injection=enabled
{{< /text >}}

Create the `HelloWorld` service in both clusters:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER1} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
$ kubectl apply --context=${CTX_CLUSTER2} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
{{< /text >}}

### Deploy `HelloWorld` `V1`

Deploy the `helloworld-v1` application to `CLUSTER1`:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER1} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v1 -n sample
{{< /text >}}

Confirm the `helloworld-v1` pod status:

{{< text bash >}}
$ kubectl get pod --context=${CTX_CLUSTER1} -n sample
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v1` is `Running`.

### Deploy `HelloWorld` `V2`

Deploy the `helloworld-v2` application to `CLUSTER2`:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER2} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v2 -n sample
{{< /text >}}

Confirm the status the `helloworld-v2` pod status:

{{< text bash >}}
$ kubectl get pod --context=${CTX_CLUSTER2} -n sample
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
{{< /text >}}

Wait until the status of `helloworld-v2` is `Running`.

### Deploy `Sleep`

Deploy the `Sleep` application to both clusters:

{{< text bash >}}
$ kubectl apply --context=${CTX_CLUSTER1} \
    -f samples/sleep/sleep.yaml -n sample
$ kubectl apply --context=${CTX_CLUSTER2} \
    -f samples/sleep/sleep.yaml -n sample
{{< /text >}}

Confirm the status `Sleep` pod on `CLUSTER1`:

{{< text bash >}}
$ kubectl get pod --context=${CTX_CLUSTER1} -n sample -l app=sleep
sleep-754684654f-n6bzf           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

Confirm the status of the `Sleep` pod on `CLUSTER2`:

{{< text bash >}}
$ kubectl get pod --context=${CTX_CLUSTER2} -n sample -l app=sleep
sleep-754684654f-dzl9j           2/2     Running   0          5s
{{< /text >}}

Wait until the status of the `Sleep` pod is `Running`.

### Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the
`HelloWorld` service several times using the `Sleep` pod. To ensure load
balancing is working properly, call the `HelloWorld` service from all
clusters in your deployment.

Send one request from the `Sleep` pod on `CLUSTER1` to the `HelloWorld` service:

{{< text bash >}}
$ kubectl exec --context=${CTX_CLUSTER1} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_CLUSTER1} -n sample -l \
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

Now repeat this process from the `Sleep` pod on `CLUSTER2`:

{{< text bash >}}
$ kubectl exec --context=${CTX_CLUSTER2} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_CLUSTER2} -n sample -l \
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
