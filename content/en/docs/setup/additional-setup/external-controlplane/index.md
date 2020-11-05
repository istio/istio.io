---
title: Install Istio with an External Control Plane [experimental]
description: Install external control plane and remote cluster.
weight: 46
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: no
---

{{< warning >}}
This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
considered `pre-alpha`.
{{< /warning >}}

## Introduction

This guide walks you through the installation of an {{< gloss >}}external control plane{{< /gloss >}}. The
external control plane [deployment model](/docs/ops/deployment/deployment-models/#control-plane-models)
enables mesh operators to install and manage mesh control planes on separate
external clusters. This deployment model allows a clear separation between mesh
operators and mesh admins. Istio mesh operators can run Istio control planes
for mesh admins while mesh admins control the configuration of the control
plane without worrying about installing or managing it.

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

The second cluster is a {{< gloss >}}remote cluster{{< /gloss >}} hosting the mesh.
Its Kubernetes API server also provides the configuration for the control plane (istiod)
running in the external cluster.

### API Server Access

The API Server in the remote cluster must be accessible to the external
control plane cluster. Many cloud providers make API Servers publicly accessible
via network load balancers (NLBs). If the API Server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations could also be used
to enable access to the API Server.

## Environment Variables

This guide will refer to two clusters named `external_cluster` and `remote_cluster`.
The following environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_EXTERNAL_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the external control plane cluster.
`CTX_REMOTE_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the remote cluster.
`EXTERNAL_ISTIOD_ADDR` | The host name for the `remote_cluster` to access the external control plane.
`SSL_SECRET_NAME` | The secret name used to access the ingress gateway on the external control plane cluster.

For example:

{{< text bash >}}
$ export CTX_EXTERNAL_CLUSTER=external_cluster
$ export CTX_REMOTE_CLUSTER=remote_cluster
$ export REMOTE_ISTIOD_ADDR=myexternal-istiod.cloud.com
$ export SSL_SECRET_NAME=myexternal-istiod-secret
{{< /text >}}

## Setup

### Setup the external cluster

Create the configuration for the ingress gateway that exposes the external control plane ports to other clusters:

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

Apply the configuration in the `istio-system` namespace of `external_cluster`:

{{< text bash >}}
$ istioctl apply -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
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
      - "$REMOTE_ISTIOD_ADDR"
    - port:
        number: 15017
        protocol: https
        name: https-WEBHOOK
      tls:
        mode: SIMPLE
        credentialName: $SSL_SECRET_NAME
      hosts:
      - "$REMOTE_ISTIOD_ADDR"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
   name: external-istiod-vs
   namespace: external-istiod
spec:
    hosts:
    - $REMOTE_ISTIOD_ADDR
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

Apply the configuration on `external_cluster`:

{{< text bash >}}
$ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

### Set up the remote (mesh) cluster

Generate the Istio configuration for `remote_cluster` and the `external-istiod` namespace:

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
      discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
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
      caAddress: $REMOTE_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      meshID: mesh1
      multiCluster:
        clusterName: remote_cluster
    istiodRemote:
      injectionURL: https://$REMOTE_ISTIOD_ADDR:15017/inject
    base:
      validationURL: https://REMOTE_ISTIOD_ADDR:15017/validate
EOF
{{< /text >}}

Install the configuration in `remote_cluster`:

{{< text bash >}}
$ istioctl apply -f remote-config-cluster.yaml --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

You may notice the ingress gateway in `remote_cluster` is not running yet.
This is expected until the external control plane is running, which you will install next.

### Setup external control plane in the control plane cluster

Create remote secret to allow external control plane in `external_cluster` to
access the `remote_cluster`:

{{< text bash >}}
$ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
$ istioctl x create-remote-secret \
  --context="${CTX_REMOTE_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

Generate the Istio configuration for the `external-istiod`
namespace in `external_cluster`:

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
      discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
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
      caAddress: $REMOTE_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      operatorManageWebhooks: true
      meshID: mesh1
      multiCluster:
        clusterName: external_cluster
    pilot:
      env:
        INJECTION_WEBHOOK_CONFIG_NAME: ""
        VALIDATION_WEBHOOK_CONFIG_NAME: ""
EOF
{{< /text >}}

Apply the Istio configuration in `external_cluster`:

{{< text bash >}}
$ istioctl apply -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
{{< /text >}}

### Validate the installation

Confirm the Istio ingress gateway in `remote_cluster` is running.

{{< text bash >}}
$ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Deploy the helloworld sample in `remote_cluster` with a namespace
has [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) enabled.
The helloworld pods should reach running in a few seconds with sidecar injected.

{{< text bash >}}
$ kubectl apply -f samples/helloworld/helloworld.yaml --context="${CTX_REMOTE_CLUSTER}"
$ kubectl get pod -l app=helloworld --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Expose the helloworld application on the gateway:

{{< text bash >}}
$ kubectl apply -f samples/helloworld/helloworld-gateway.yaml --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Follow [these instructions](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) to
set `GATEWAY_URL`. Confirm you can access the hello application:

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/hello" | grep -o "Hello"
{{< /text >}}

**Congratulations!** You successfully installed an external control plane that manages
services running in the remote cluster!
