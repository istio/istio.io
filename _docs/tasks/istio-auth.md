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

* Read the [Istio Auth concepts]({{home}}/docs/concepts/network-and-auth/auth.html).

* Completed steps 1 - 3 in [the Istio installation guide](./installing-istio.html#installing-on-an-existing-cluster).

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

We have the YAML file [istio-auth.yaml](https://github.com/istio/istio/blob/master/install/kubernetes/istio-auth.yaml)
for deploying all Istio components including Istio CA into the namespace.
Follow [the Istio installation guide](./installing-istio.html),
and **choose "If you would like to enable Istio Auth" in step 4**.

### Option 2: (recommended) using per-cluster CA

Note: if you have already enabled Istio auth for any namespace in the cluster, this process will deploy a CA that conflicts with
existing CAs. Please follow [Disabling Istio Auth](#disableauth) section to disable auth first.

Only a single Istio CA is deployed for the Kubernetes cluster, in a dedicated namespace.
Doing this offers the following benefits:

* In the near future, the dedicated namespace will use
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) to provide security
boundary. This will offer strong security for Istio CA.

* Services in the same Kubernetes cluster but different namespaces are able to talk to each other through Istio Auth
without extra trust setup.

#### Deploying CA

The following command creates  namespace *istio-system* and deploys CA into the namespace:

```bash
kubectl apply -f templates/istio-auth/istio-cluster-ca.yaml
```

#### Enabling Istio Auth in Istio config

The following commands back up the file *istio-auth.yaml* as *istio-auth.yaml.bak*,
and generates a new *istio-auth.yaml* by uncommenting the line *authPolicy: MUTUAL_TLS* in *istio.yaml*.

```bash
mv istio-auth.yaml istio-auth.yaml.bak
sed "s/# authPolicy: MUTUAL_TLS/authPolicy: MUTUAL_TLS/" istio.yaml > istio-auth.yaml
```

#### Deploying other services

Follow [the general Istio installation guide](./installing-istio.html),
and **choose "If you would like to enable Istio Auth" in step 4**.

## <a name="disableauth"></a>Disabling Istio Auth

Disabling Istio Auth requires all Istio services and applications to be reconfigured and restarted without auth config.

### For per-namespace CA Istio Auth

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f istio-auth.yaml
kubectl apply -f istio.yaml
```

Also, redeploy your application by running:

```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

### For per-cluster CA Istio Auth

#### Removing per-cluster Istio CA

The following command removes Istio CA and its namespace *istio-system*.

```bash
kubectl delete -f templates/istio-auth/istio-cluster-ca.yaml
```

#### Redeploying Istio and applications

Run the following command to uninstall Istio, and redeploy Istio without auth:

```bash
kubectl delete -f istio-auth.yaml
kubectl apply -f istio.yaml
```

Also, redeploy your application by running:

```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

#### Recovering the original config files

The following command will recover the original *istio-auth.yaml* file.

```bash
mv istio-auth.yaml.bak istio-auth.yaml
```

## Verifying Istio Auth setup

The following instructions assume the applications are deployed in the "default" namespace.
They can be modified for deployments in a separate namespace.

Verify AuthPolicy setting in ConfigMap:

```bash
kubectl get configmap istio -o yaml | grep authPolicy
```

Istio Auth is enabled if "authPolicy: MUTUAL\_TLS" is uncommented.

Check the certificate and key files are mounted onto the application pod *app-pod*:

```bash
kubectl exec <app-pod> -c proxy -- ls /etc/certs
```

Expected files: cert-chain.pem, key.pem and root-cert.pem.

When Istio Auth is enabled for a pod, *ssl_context* stanzas should be in the pod's proxy config.
The following commands verifies the proxy config on *app-pod* has *ssl_context* configured:

```bash
kubectl exec <app-pod> -c proxy -- ls /etc/envoy
```

Get the config file named "envoy-revX.json", and use the file name in the following command:

```bash
kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-revX.json | grep ssl_context
```

You should see ssl\_context lines in the output.
