---
category: Tasks
title: Enabling Istio Auth
overview: This task shows you how to setup Istio-Auth to provide mutual TLS authentication between services.

order: 70

bodyclass: docs
layout: docs
type: markdown
---

This task shows how to set up Istio auth in a Kubernetes cluster. You'll learn
how to:
* Enable Istio auth
* Disable Istio auth
* Verify Istio auth setups


## Before you begin
The tutorial assumes you have:
* Read the Istio auth concepts.
* Cloned https://github.com/istio/istio to your local machine.

If you haven’t done so, please refer to
[the general Istio installation guide](https://istio.io/docs/tasks/installing-istio.html).

In the real world systems, Istio CA should always be deployed in a dedicated namespace, and it issues certificates/keys to
all pods in the Kubernetes cluster. This offers strong security and automatic trusts between namespaces in the same cluster.
However, this tutorial also instructs how to deploy a namespace-scoped Istio CA, for easy setup and clean up during the
experiments.

## Enabling Istio Auth

### Option 1: Using Per-Namespace CA

Per namespace CA is convenient for doing experiments.
Because each Istio CA is scoped within a namespace, Istio CAs in different namespaces will not interfere with each other
and they are easy to clean up.

We have one-off scripts *istio-auth-X.yaml* for deploying all Istio components including Istio CA into the namespace.
Follow the general instructions on [Installing Istio](https://istio.io/docs/tasks/installing-istio.html),
and **follow "With Istio auth Enabled" steps**.

### Option 2: (Recommended) Using Per-Cluster CA

Only a single Istio CA is deployed for the Kubernetes cluster, in a dedicated namespace.
Doing this offers the following benefits:
* In the near future, the dedicated namespace will use
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) to provide security
boundary. This will offer strong security for Istio CA.
* Services in the same Kubernetes cluster but different namespaces are able to talk to each other through Istio auth
without extra trust setup.

#### Deplying CA

The following command creates  namespace *istio-system* and deploys CA into the namespace:

```bash
kubectl apply -f ./kubernetes/istio-auth/istio-cluster-ca.yaml
```

#### <a name="istioconfig"></a>Enable Istio Auth in Istio Config

The following command uncomments the line *authPolicy: MUTUAL_TLS* in the file *kubernetes/istio-X.yaml*,
and backs up the original file as *istio-X.yaml.bak*
(*X* corresponds to the Kubernetes server version, choose "15" or "16").

```bash
sed -i.bak "s/# authPolicy: MUTUAL_TLS/authPolicy: MUTUAL_TLS/" ./kubernetes/istio-X.yaml
```

#### <a name="otherservices"></a>Deploying Other Services

Follow [the general Istio installation guide](https://istio.io/docs/tasks/installing-istio.html),
and **follow "With Istio auth Disabled" steps**.

## Disabling Istio Auth

Disabling Istio auth requires all Istio services and applications to be reconfigured and restarted without auth config.

### For Per-Namespace CA Istio Auth

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f ./kubernetes/istio-auth-X.yaml
kubectl apply -f ./kubernetes/istio-X.yaml
```

Also, redeploy your applications by running:
```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

### For Per-Cluster CA Istio Auth

#### Removing Per-Cluster Istio CA

The following command removes Istio CA and its namespace *istio-system*.
```bash
kubectl delete -f ./kubernetes/istio-auth/istio-cluster-ca.yaml
```

#### Recovering the Original Non-Auth ConfigMap

The following command will recover the original *istio-X.yaml* file using the backup file created in
[previous steps](<a name="istioconfig"></a>).
```bash
mv ./kubernetes/istio-X.yaml.bak ./kubernetes/istio-X.yaml
```

#### Redeploying Istio And Applications

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f ./kubernetes/istio-X.yaml
kubectl apply -f ./kubernetes/istio-X.yaml
```

Also, redeploy your applications by running:
```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

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