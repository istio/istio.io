---
title: Install Istio with an External Control Plane
description: Install an external control plane and remote cluster.
weight: 80
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: yes
---

## Introduction

This guide walks you through the installation of an {{< gloss >}}external control plane{{< /gloss >}}. The
external control plane [deployment model](/docs/ops/deployment/deployment-models/#control-plane-models)
enables mesh operators to install and manage mesh control planes on separate
external clusters. This deployment model allows a clear separation between mesh
operators and mesh admins. The mesh operators can install and manage the Istio control planes
while the mesh admins only need to configure the mesh resources.

This feature is currently considered [alpha](/about/feature-stages/).

{{< image width="75%"
    link="external-controlplane.svg"
    caption="External control plane cluster and remote cluster"
    >}}

## Requirements

### Clusters

This guide requires that you have two Kubernetes clusters with any of the
supported Kubernetes versions: {{< supported_kubernetes_versions >}}.

The first cluster contains the external control plane installed
in the `external-istiod` namespace. An ingress gateway is also installed in the `istio-system`
namespace to provide mesh sidecars access to the external control plane.

The second cluster is a {{< gloss >}}remote cluster{{< /gloss >}} running the mesh workloads.
Its Kubernetes API server also provides the configuration for the control plane (istiod)
running in the external cluster.

### API Server Access

The Kubernetes API server in the remote cluster must be accessible to the external
control plane cluster. Many cloud providers make API servers publicly accessible
via network load balancers (NLBs). If the API server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations could also be used
to enable access to the API server.

## Environment Variables

The following environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_EXTERNAL_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the external control plane cluster.
`CTX_REMOTE_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the remote cluster.
`REMOTE_CLUSTER_NAME` | The name of the remote cluster.
`EXTERNAL_ISTIOD_ADDR` | The hostname for the ingress gateway on the external control plane cluster. This is used by the remote cluster to access the external control plane.
`SSL_SECRET_NAME` | The name of the secret that holds the TLS certs for the ingress gateway on the external control plane cluster.

Set the `CTX_EXTERNAL_CLUSTER`, `CTX_REMOTE_CLUSTER`, and `REMOTE_CLUSTER_NAME` now. You will set the others later.

{{< text syntax=bash snip_id=none >}}
$ export CTX_EXTERNAL_CLUSTER=<your external cluster context>
$ export CTX_REMOTE_CLUSTER=<your remote cluster context>
$ export REMOTE_CLUSTER_NAME=<your remote cluster name>
{{< /text >}}

## Cluster configuration

### Set up a gateway in the external cluster

Create the Istio install configuration for the ingress gateway that exposes the external control plane ports to other clusters:

{{< text bash >}}
$ cat <<EOF > controlplane-gateway.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            ports:
              - port: 15021
                targetPort: 15021
                name: status-port
              - port: 15012
                targetPort: 15012
                name: tls-xds
              - port: 15017
                targetPort: 15017
                name: tls-webhook
EOF
{{< /text >}}

Install the configuration to create the ingress gateway in the `istio-system` namespace of the external cluster:

{{< text bash >}}
$ istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

You may notice an istiod deployment created in the `istio-system` namespace. This is used only to configure the ingress gateway and is NOT the control plane used by remote clusters. This ingress gateway could, in fact, be configured to host multiple external control planes, in different namespaces on the cluster, even though in this example you will only deploy a single external istiod in the `external-istiod` namespace.

Configure your environment to expose the Istio ingress gateway service using a public hostname with TLS. Set the `EXTERNAL_ISTIOD_ADDR` environment variable to the hostname and `SSL_SECRET_NAME` environment variable to the secret that holds the TLS certs:

{{< text syntax=bash snip_id=none >}}
$ export EXTERNAL_ISTIOD_ADDR=<your external istiod host>
$ export SSL_SECRET_NAME=<your external istiod secret>
{{< /text >}}

Create the Istio `Gateway`, `VirtualService`, and `DestinationRule` configuration for the **yet to be installed** external
control plane:

{{< text bash >}}
$ cat <<EOF > external-istiod-gw.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: external-istiod-gw
  namespace: external-istiod
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 15012
        protocol: https
        name: https-XDS
      tls:
        mode: SIMPLE
        credentialName: $SSL_SECRET_NAME
      hosts:
      - $EXTERNAL_ISTIOD_ADDR
    - port:
        number: 15017
        protocol: https
        name: https-WEBHOOK
      tls:
        mode: SIMPLE
        credentialName: $SSL_SECRET_NAME
      hosts:
      - $EXTERNAL_ISTIOD_ADDR
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
   name: external-istiod-vs
   namespace: external-istiod
spec:
    hosts:
    - $EXTERNAL_ISTIOD_ADDR
    gateways:
    - external-istiod-gw
    http:
    - match:
      - port: 15012
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 15012
    - match:
      - port: 15017
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: external-istiod-dr
  namespace: external-istiod
spec:
  host: istiod.external-istiod.svc.cluster.local
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 15012
      tls:
        mode: SIMPLE
      connectionPool:
        http:
          h2UpgradePolicy: UPGRADE
    - port:
        number: 443
      tls:
        mode: SIMPLE
EOF
{{< /text >}}

Create the `external-istiod` namespace and apply the configuration:

{{< text bash >}}
$ kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
$ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

### Set up the remote cluster

Create the remote Istio install configuration:

{{< text bash >}}
$ cat <<EOF > remote-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
  profile: remote
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    pilot:
      enabled: false
    istiodRemote:
      enabled: true

  values:
    global:
      istioNamespace: external-istiod
      meshID: mesh1
      multiCluster:
        clusterName: $REMOTE_CLUSTER_NAME
    istiodRemote:
      injectionURL: https://$EXTERNAL_ISTIOD_ADDR:15017/inject
    base:
      validationURL: https://$EXTERNAL_ISTIOD_ADDR:15017/validate
EOF
{{< /text >}}

Install the configuration on the remote cluster:

{{< text bash >}}
$ kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"
$ istioctl manifest generate -f remote-config-cluster.yaml  | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
{{< /text >}}

**NOTE:** An ingress gateway, for accessing services in the remote cluster mesh, is included in the above installation. However it will not start working until you install the external control plane in the next section.

### Set up the control plane in the external cluster

The control plane in the external cluster needs access to the remote cluster to discover services, endpoints, and pod attributes. Create a secret with credentials to access the remote cluster’s `kube-apiserver` and install it in the external cluster.

{{< text bash >}}
$ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
$ istioctl x create-remote-secret \
  --context="${CTX_REMOTE_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

Create the Istio install configuration to create the control plane in the `external-istiod` namespace of the external cluster:

{{< text bash >}}
$ cat <<EOF > external-istiod.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: external-istiod
spec:
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    base:
      enabled: false
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      operatorManageWebhooks: true
      meshID: mesh1
      multiCluster:
        clusterName: $REMOTE_CLUSTER_NAME
    pilot:
      env:
        INJECTION_WEBHOOK_CONFIG_NAME: ""
        VALIDATION_WEBHOOK_CONFIG_NAME: ""
EOF
{{< /text >}}

Apply the Istio configuration on the external cluster:

{{< text bash >}}
$ istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

## Validate the installation

Confirm that the Istio ingress gateway is now running on the remote cluster.

{{< text bash >}}
$ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Deploy the `helloworld` sample to the remote cluster. Wait a few seconds for the `helloworld` pods to be running with sidecars injected.

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --context="${CTX_REMOTE_CLUSTER}"
$ kubectl apply -f samples/helloworld/helloworld.yaml --context="${CTX_REMOTE_CLUSTER}"
$ kubectl get pod -l app=helloworld --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Expose the `helloworld` application on the ingress gateway:

{{< text bash >}}
$ kubectl apply -f samples/helloworld/helloworld-gateway.yaml --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Follow [these instructions](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) to
set `GATEWAY_URL` and then confirm you can access the `helloworld` application:

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/hello" | grep -o "Hello"
{{< /text >}}

**Congratulations!** You successfully installed an external control plane and used it to manage
services running in a remote cluster!
