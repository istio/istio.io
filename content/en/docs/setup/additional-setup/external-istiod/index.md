---
title: Installing External Istiod 
description: Install external Istiod and remote config cluster
weight: 46
keywords: [external,istiod,remote,config]
aliases:
    - /docs/setup/kubernetes/additional-setup/external-istiod/
owner: istio/wg-environments-maintainers
test: no
---

## Introduction

The external control plane deployment model enables mesh operators to install and manage mesh control planes on separate external clusters. This deployment model allows a clear separation between mesh operators and mesh admins. Istio mesh operators can now run Istio control planes for mesh admins while mesh admins can still control the configuration of the control plane without worrying about installing or managing the control plane.

## Requirements

### Cluster

This guide requires that you have two Kubernetes clusters with any of the
supported Kubernetes versions: {{< supported_kubernetes_versions >}}. First cluster is the external control plane cluster where it has istio default profile installed in the istio-system namespace.   It also has external istiod installed in the external-istiod namespace.  The external istiod is exposed on the ingress gateway from the istio-system namespace.  The second cluster is a remote config cluster.

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

For example:

{{< text bash >}}
$ export CTX_EXTERNAL_CP=external_cp_cluster
$ export CTX_USER_CLUSTER=user_cluster
{{< /text >}}

## Setup

### Setup management cluster

1. Install istio using the default profile management cluster.

cat <<EOF > istiod-management.yaml
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
```
```
istioctl apply -f istiod-management.yaml --context="${CTX_EXTERNAL_CP}"
```

```
Export SSL_SECRET_NAME and Expose external istiod on istio ingress gw.

cat <<EOF > external-istiod-gw.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
 name: istiod-external-gw
 namespace: istiod-external
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
   name: istiod-external-vs
   namespace: istiod-external
spec:
   hosts:
   - $REMOTE_ISTIOD_ADDR
   gateways:
   - istiod-external-gw
   http:
   - match:
     - port: 15012
     route:
     - destination:
         host: istiod.istiod-external.svc.cluster.local
         port:
           number: 15012
   - match:
     - port: 15017
     route:
     - destination:
         host: istiod.istiod-external.svc.cluster.local
         port:
           number: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: istiod-external-dr
 namespace: istiod-external
spec:
 host: istiod.istiod-external.svc.cluster.local
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
```

kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CP}"


### Setup remote cluster
1. Configure REMOTE_ISTIOD_ADDR environment variable
2. Install Istio without Istiod on a remote config cluster in namespace istiod-external.

```
cat <<EOF > remote-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: istiod-external
spec:
 meshConfig:
   rootNamespace: istiod-external
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
     istioNamespace: istiod-external
 
   istiodRemote:
     injectionURL: https://$REMOTE_ISTIOD_ADDR:15017/inject
 
   base:
     validationURL: https://REMOTE_ISTIOD_ADDR:15017/validate
EOF
```

istioctl apply -f remote-config-cluster.yaml --context="${CTX_USER_CLUSTER}"


### Setup external Istiod on management cluster

```
k create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CP}"

istioctl x create-remote-secret \
  --context="${CTX_USER_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CP}"

```

```
cat <<EOF > external-istiod.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: istiod-external
spec:
 meshConfig:
   defaultConfig:
     discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
     rootNamespace: istiod-external
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
     istioNamespace: istiod-external
     operatorManageWebhooks: true
   pilot:
     env:
       INJECTION_WEBHOOK_CONFIG_NAME: ""
       VALIDATION_WEBHOOK_CONFIG_NAME: ""
EOF
```

```
istioctl apply -f external-istiod.yaml --context="${CTX_EXTERNAL_CP}"
```

###Validate the installation

Check gateway on the remote config cluster is running

Deploy sleep/httpbin on remote config cluster with a namespace has sidecar injector enabled.  Both should reach running in a few seconds.