---
category: Tasks
title: Enabling Istio Auth

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


## Creating Dedicated Namespace For Istio CA

It is a good practice to deploy a single Istio CA for the cluster, in a dedicated namespace.
Because with a single CA:
* Services in the same cluster but different namespaces are able to talk to each other through Istio auth without extra trust set up.
* When Istio is fully compatible with Kubernetes V1.6, the dedicated namespace will always be  access-restricted, with
 RBAC in Kubernetes V1.6.

We use the name *istio-admin* for the dedicated namespace. The following command creates the namespace:

```bash
kubectl create ns istio-admin
```

## <a name="istioca"></a>Setting up and Deploying Istio CA

The Istio CA issues certificates and keys for the service accounts, which are mounted into the pods.
In the cluster, a single CA is used for issuing certificates and keys for all namespaces.

The following command deploys Istio CA to the *istio-admin* namespace:

```bash
kubectl apply -f kubernetes/istio-install/istio-ca.yaml -n istio-admin
```


## <a name="configmap"></a>Adding AuthPolicy to ConfigMap
Currently Istio auth only supports enabling/disabling mutual TLS for the entire cluster
(service-level istio auth enabling/disabling will be supported in the future releases).
To enable/disable it, uncomment/comment line *authPolicy: MUTUAL_TLS* in kubernetes/istio-install/istio-manager.yaml.
In the following, we use *vim* to edit the file.

```bash
vi ./kubernetes/istio.yaml
# Uncomment the line "authPolicy: MUTUAL_TLS" to enable Istio auth.
```

## Enabling Istio Auth

This section covers enabling Istio auth for non-Istio clusters and Istio clusters. 

### Enabling Istio Auth in Non-Istio Cluster

After [setting up the CA](#istioca) and [adding AuthPolicy to ConfigMap](#configmap),
follow the [general guide](http://istio.github.io/docs/tasks/istio-installation.html) to install Istio.

### Enabling Istio Auth in Istio Cluster

Instructions below assume the applications are deployed in the "default" namespace. They can be modified for deployments
in a separate namespace.

Run the following command to redeploy ConfigMap:

```bash
kubectl replace -f kubernetes/istio-install/istio-manager.yaml
```

Istio Manager needs to be restarted to reload the ConfigMap.
Run the following command to restart the Istio Manager:

```bash
kubectl delete po <istio-manager-pod>
```

Each of the existing Istio-powered deployement need to be reconfigured and redeployed.
For example, to enable auth on deployment powered by kubeconfig *<app-kubeconfig>.yaml*,
run the following command:

```bash
kubectl replace -f <(istioctl kube-inject -f <app-kubeconfig>.yaml)
```

## Verify Istio Auth Setup

The following instructions assume the applications are deployed in the "default" namespace.
They can be modified for deployments in a separate namespace.

Verify AuthPolicy setting in ConfigMap:
```bash
kubectl get configmap istio -o yaml
# Istio Auth is enabled if the line "authPolicy: MUTUAL_TLS" is uncommented.
```

Check the certificate and key files are mounted onto the application pod <app-pod>:
```bash
kubectl exec <app-pod> -c proxy -- ls /etc/certs
# Expected files: cert-chain.pem, key.pem and root-cert.pem.
```

Check the proxy config on <app-pod>:
```bash
kubectl exec <app-pod> -c proxy -- ls /etc/envoy
# Get the name "envoy-revX.json".
kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-revX.json
# Print the Envoy config to stdout.
```
When Istio auth is enabled for the pod, *ssl_context* stanzas should be in the proxy config.