---
title: Enabling Istio Auth
overview: This task shows you how to setup Istio-Auth to provide mutual TLS authentication between services.
  
order: 70

bodyclass: docs
layout: docs
type: markdown
---

This task shows how to set up Istio auth in a Kubernetes cluster. You'll learn
how to:
* Set up and Deploy Istio CA
* Enable Istio auth
* Disable Istio auth
* Verify Istio auth setups


## Before you begin
The tutorial assumes you have:
* Cloned https://github.com/istio/istio to your local machine
* Installed **istioctl** CLI.
* Sourced istio.VERSION for setting up **istioctl** env variables.

If you haven’t done so, please refer to
[the general Istio installation guide](http://istio.github.io/docs/tasks/istio-installation.html).


## Creating Namespace For Istio CA

Only a single Istio CA should be deployed for your Kubernetes cluster, in a dedicated namespace. Doing this offers the following benefits:
* Services in the same cluster but different namespaces are able to talk to each other through Istio auth without extra
trust set up.
* Eventually, the dedicated namespace will always be access-restricted, with
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) providing security boundary.

In this tutorial, we use the name *istio-admin* for the dedicated namespace.
The following command creates the namespace:

```bash
kubectl create ns istio-admin
```

## <a name="istioca"></a>Deploying Istio CA

The Istio CA issues certificates and keys for the service accounts, which are mounted into the pods.
In the cluster, a single CA is used for issuing certificates and keys for all namespaces.

The following command deploys Istio CA to the *istio-admin* namespace:

```bash
kubectl apply -f kubernetes/istio-auth/istio-cluster-ca.yaml -n istio-admin
```


## <a name="configmap"></a>Adding AuthPolicy to ConfigMap
Currently Istio auth only supports enabling/disabling mutual TLS for the entire cluster
(service-level istio auth enabling/disabling will be supported in the future releases).
To enable/disable it, uncomment/comment line *authPolicy: MUTUAL_TLS* in the file *kubernetes/istio-X.yaml*.
*X* corresponds to the Kubernetes server version, choose "15" or "16". In the following, we use *vim* to edit the file.

```bash
vi ./kubernetes/istio-X.yaml
# Uncomment the line "authPolicy: MUTUAL_TLS" to enable Istio auth.
```

## Enabling Istio Auth

After [deploying Istio CA](#istioca) and [adding AuthPolicy to ConfigMap](#configmap), the Istio manager and services
need to be deployed/redeployed to reflect the new configuration with Istio auth. 
This section covers enabling Istio auth for non-Istio clusters and Istio clusters. 

### Deploying Services in Non-Istio Cluster

After [deploying Istio CA](#istioca) and [adding AuthPolicy to ConfigMap](#configmap),
follow the [general guide](http://istio.github.io/docs/tasks/istio-installation.html) to install Istio and deploy
services.

### <a name="istiocluster"></a>Redeploying Services in Istio Cluster

After [deploying Istio CA](#istioca) and [adding AuthPolicy to ConfigMap](#configmap), services need to be redeployed
with the new configuration.
Instructions below assume the applications are deployed in the "default" namespace. They can be modified for deployments
in a separate namespace.

Run the following command to redeploy ConfigMap for Kubernetes version *X*:

```bash
kubectl replace -f kubernetes/istio-X.yaml
```

Istio Manager needs to be restarted to reload the ConfigMap.
Run the following command to find and restart the Istio Manager:

```bash
kubectl get po | grep istio-manager
# Get the pod Istio manager is running on.
kubectl delete po <istio-manager-pod>
# Istio manager pod is restarted.
```

Each of the existing Istio-enabled deployement need to be reconfigured and redeployed.
For example, to enable auth on pod deployed by kubeconfig *\<app-kubeconfig\>.yaml*,
run the following command:

```bash
kubectl replace -f <(istioctl kube-inject -f <app-kubeconfig>.yaml)
```

## Disabling Istio Auth

### Removing Istio CA

Suppose Istio CA runs in dedicated namespace *istio-admin*, the following command removes Istio CA and the namespace.
```bash
kubectl delete ns istio-admin
```

### Removing AuthPolicy from ConfigMap

Refer to [Adding AuthPolicy to ConfigMap](#configmap) to comment out the following line in *kubernetes/istio-X.yaml*.
```yaml
authPolicy: MUTUAL_TLS
```

### Redeploying Services without Istio Auth

This is the same as [Redeploying Services in Istio Cluster](#istiocluster).

## Verifying Istio Auth Setup

The following instructions assume the applications are deployed in the "default" namespace.
They can be modified for deployments in a separate namespace.

Verify AuthPolicy setting in ConfigMap:
```bash
kubectl get configmap istio -o yaml | grep authPolicy
# Istio Auth is enabled if the line "authPolicy: MUTUAL_TLS" is uncommented.
```

Check the certificate and key files are mounted onto the application pod *app-pod*:
```bash
kubectl exec <app-pod> -c proxy -- ls /etc/certs
# Expected files: cert-chain.pem, key.pem and root-cert.pem.
```

When Istio auth is enabled for a pod, *ssl_context* stanzas should be in the pod's proxy config.
The following commands verifies the proxy config on *app-pod* has *ssl_context* configured:
```bash
kubectl exec <app-pod> -c proxy -- ls /etc/envoy
# Get the config file named "envoy-revX.json".
kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-revX.json | grep ssl_context
# Expect ssl_context in the output.
```