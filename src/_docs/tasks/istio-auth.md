---
title: Enabling Istio Auth
overview: This task shows you how to setup Istio-Auth to provide mutual TLS authentication between services.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to set up Istio Auth in a Kubernetes cluster. You'll learn
how to:

* Enable Istio Auth

* Disable Istio Auth

* Verify Istio Auth setup


## Before you begin

This task assumes you have:

* Read the [Istio Auth concepts]({{home}}/docs/concepts/network-and-auth/index.html).

* Cloned https://github.com/istio/istio to your local machine
  (Step 1 in [the Istio installation guide](./installing-istio.html#installing-on-an-existing-cluster)).

In real world systems, only a single Istio CA should be present in a Kubernetes cluster,
which is always deployed in a dedicated namespace. The Istio CA issues certificates/keys to
all pods in the Kubernetes cluster. This offers strong security and automatic trust between namespaces in the same cluster.
However, this task also instructs how to deploy a namespace-scoped Istio CA,
for easy setup and clean up during the experiments.

## Enabling Istio Auth

### Option 1: using per-namespace CA

Per namespace CA is convenient for doing experiments.
Because each Istio CA is scoped within a namespace, Istio CAs in different namespaces will not interfere with each other
and they are easy to clean up through a single command.

We have the YAML files *istio-auth-X.yaml* for deploying all Istio components including Istio CA into the namespace.
Follow [the Istio installation guide](./installing-istio.html),
and **choose "If you would like to enable Istio Auth" in step 3**.

### Option 2: (recommended) using per-cluster CA

Only a single Istio CA is deployed for the Kubernetes cluster, in a dedicated namespace.
Doing this offers the following benefits:

* In the near future, the dedicated namespace will use
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) to provide security
boundary. This will offer strong security for Istio CA.

* Services in the same Kubernetes cluster but different namespaces are able to talk to each other through Istio Auth
without extra trust setup.

#### Deplying CA

The following command creates  namespace *istio-system* and deploys CA into the namespace:

```bash
kubectl apply -f ./kubernetes/istio-auth/istio-cluster-ca.yaml
```

#### Enabling Istio Auth in Istio config

The following command uncomments the line *authPolicy: MUTUAL_TLS* in the file *kubernetes/istio-X.yaml*,
and backs up the original file as *istio-X.yaml.bak*
(*X* corresponds to the Kubernetes server version, choose "15" or "16").

```bash
sed "s/# authPolicy: MUTUAL_TLS/authPolicy: MUTUAL_TLS/" ./kubernetes/istio-X.yaml > ./kubernetes/istio-auth-X.yaml
```

#### Deploying other services

Follow [the general Istio installation guide](./installing-istio.html),
and **choose "If you would like to enable Istio Auth" in step 3**.

## Disabling Istio Auth

Disabling Istio Auth requires all Istio services and applications to be reconfigured and restarted without auth config.

### For per-namespace CA Istio Auth

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f ./kubernetes/istio-auth-X.yaml
kubectl apply -f ./kubernetes/istio-X.yaml
```

Also, redeploy your application by running:

```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

### For per-cluster CA Istio Auth

#### Removing per-cluster Istio CA

The following command removes Istio CA and its namespace *istio-system*.

```bash
kubectl delete -f ./kubernetes/istio-auth/istio-cluster-ca.yaml
```

#### Redeploying Istio and applications

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f ./kubernetes/istio-auth-X.yaml
kubectl apply -f ./kubernetes/istio-X.yaml
```

Also, redeploy your application by running:

```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

#### Recovering the original config files

The following command will recover the original *istio-auth-X.yaml* file.

```bash
git checkout ./kubernetes/istio-auth-X.yaml
```

## Verifying Istio Auth setup

The following instructions assume the applications are deployed in the "default" namespace.
They can be modified for deployments in a separate namespace.

Verify AuthPolicy setting in ConfigMap:

```bash
kubectl get configmap istio -o yaml | grep authPolicy
```
```bash
# Istio Auth is enabled if the line "authPolicy: MUTUAL_TLS" is uncommented.
```

Check the certificate and key files are mounted onto the application pod *app-pod*:

```bash
kubectl exec <app-pod> -c proxy -- ls /etc/certs
```
```bash
# Expected files: cert-chain.pem, key.pem and root-cert.pem.
```

When Istio Auth is enabled for a pod, *ssl_context* stanzas should be in the pod's proxy config.
The following commands verifies the proxy config on *app-pod* has *ssl_context* configured:

```bash
kubectl exec <app-pod> -c proxy -- ls /etc/envoy
```
```bash
# Get the config file named "envoy-revX.json".
```
```bash
kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-revX.json | grep ssl_context
```
```bash
# Expect ssl_context in the output.
```

