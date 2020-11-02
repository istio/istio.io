---
title: Installing External Istiod 
description: Install external Istiod and remote config cluster.
weight: 46
keywords: [external,istiod,remote,config]
aliases:
    - /docs/setup/kubernetes/additional-setup/external-istiod/
owner: istio/wg-environments-maintainers
test: no
---

## Introduction

The {{< gloss >}}external control plane{{< /gloss >}} deployment model enables mesh operators to install and manage mesh control planes on separate external clusters. This deployment model allows a clear separation between mesh operators and mesh admins. Istio mesh operators can now run Istio control planes for mesh admins while mesh admins can still control the configuration of the control plane without worrying about installing or managing the control plane.

## Requirements

### Cluster

This guide requires that you have two Kubernetes clusters with any of the
supported Kubernetes versions: {{< supported_kubernetes_versions >}}. First cluster is the {{< gloss >}}external control plane{{< /gloss >}} cluster where it has Istio default profile installed in the istio-system namespace.   It also has external istiod installed in the external-istiod namespace.  The external istiod is exposed on the ingress gateway from the istio-system namespace.  The second cluster is a {{< gloss >}}remote cluster{{< /gloss >}} which also provides configuration for the external istiod.

### API Server Access

The API Server in the remote config cluster must be accessible to the external control plane cluster. Many cloud providers make API Servers publicly accessible via network
load balancers (NLB). If the API Server is not directly accessible, you will
have to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in
the multi-network and primary-remote configurations could also be used
to enable access to the API Server.

## Environment Variables

This guide will refer to two clusters named `external_cp_cluster` and `user_cluster`. The following environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_EXTERNAL_CP` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the external control plane cluster.
`CTX_USER_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the remote config cluster.
`REMOTE_ISTIOD_ADDR` | The external istiod host name for `user_cluster` to access external istiod.
`SSL_SECRET_NAME` | The secret name used by the `external-istiod-gw` gateway resource on the external control plane cluster.

For example:

{{< text bash >}}
$ export CTX_EXTERNAL_CP=external_cp_cluster
$ export CTX_USER_CLUSTER=user_cluster
$ export REMOTE_ISTIOD_ADDR=myexternal-istiod.cloud.com
$ export SSL_SECRET_NAME = myexternal-istiod-secret
{{< /text >}}

## Setup

### Setup the external control plane cluster

Create the Istio configuration for `external_cp_cluster`, using the default profile with the following ports on the ingress gateway to expose the external istiod:

{{< text bash >}}
$ cat <<EOF > external-cp.yaml
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

Apply the configuration in `external_cp_cluster` in the <code>istio-system</code> namespace.

{{< text bash >}}
$ istioctl apply -f external-cp.yaml --context="${CTX_EXTERNAL_CP}"
{{< /text >}}

Expose the **to be installed** external istiod on Istio ingress gateway installed in the <code>istio-system</code> namespace. Create the Istio network configuration:

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

Apply the Istio configuration in `external_cp_cluster`:

{{< text bash >}}
$ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CP}"
{{< /text >}}

### Setup remote cluster

Generate the Istio configuration for `user_cluster` and the <code>external-istiod</code> namespace:

{{< text bash >}}
$ cat <<EOF > remote-config-cluster.yaml
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
   pilot:
     enabled: false
   istiodRemote:
     enabled: true

 values:
   global:
     caAddress: $REMOTE_ISTIOD_ADDR:15012
     istioNamespace: external-istiod
   istiodRemote:
     injectionURL: https://$REMOTE_ISTIOD_ADDR:15017/inject
   base:
     validationURL: https://REMOTE_ISTIOD_ADDR:15017/validate
EOF
{{< /text >}}

Install the configuration in `user_cluster` in the <code>external-istiod</code> namespace:

{{< text bash >}}
$ istioctl apply -f remote-config-cluster.yaml --context="${CTX_USER_CLUSTER}"
{{< /text >}}

You may notice the ingress gateway on the cluster is not running yet.  This is normal as the ingress gateway won't reach running until its external Istiod reaches running, which you will install next.

### Setup external istiod on management cluster

Create remote secret to allow external istiod in `external_cp_cluster` to access the `user_cluster`:

{{< text bash >}}
$ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CP}"
$ istioctl x create-remote-secret \
  --context="${CTX_USER_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CP}"
{{< /text >}}

Generate the Istio configuration for `external_cp_cluster` and the <code>external-istiod</code> namespace:

{{< text bash >}}
$ cat <<EOF > external-istiod.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
 meshConfig:
   defaultConfig:
     discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
     rootNamespace: external-istiod
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
   pilot:
     env:
       INJECTION_WEBHOOK_CONFIG_NAME: ""
       VALIDATION_WEBHOOK_CONFIG_NAME: ""
EOF
{{< /text >}}

Apply the Istio configuration in `external_cp_cluster`:

{{< text bash >}}
$ istioctl apply -f external-istiod.yaml --context="${CTX_EXTERNAL_CP}"
{{< /text >}}

### Validate the installation

Confirm the Istio ingress gateway in `user_cluster` is running.

{{< text bash >}}
$ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_USER_CLUSTER}"
{{< /text >}}

Deploy the sleep sample in `user_cluster` with a namespace has [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) enabled.  The sleep pod should reach running in a few seconds.

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml --context="${CTX_USER_CLUSTER}"
$ kubectl get pod -l app=sleep --context="${CTX_USER_CLUSTER}"
{{< /text >}}

**Congratulations!** You successfully installed an external Istiod that manages services running in the remote config cluster!