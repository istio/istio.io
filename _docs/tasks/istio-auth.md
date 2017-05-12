---
title: Enabling Istio Auth
overview: This task shows you how to setup Istio-Auth to provide mutual TLS authentication between services.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

Through this task,
you will learn how to do the following for Istio Auth with **per-cluster Istio CA**:

* Enable Istio Auth

* Disable Istio Auth

* Verify Istio Auth setup

## Per-cluster CA vs. per-namespace CA

There are two deployment modes for Istio CA, per-cluster and per-namespace.
The following describes the differences between them.

**Per-cluster CA**:

This task focuses on Istio Auth with per-cluster CA.

Only a single Istio CA is present in a Kubernetes cluster,
which is always deployed in a dedicated namespace. The Istio CA issues certificates and keys to
all pods in the Kubernetes cluster. It offers the following benefits:

* In the near future, Istio will enforce the dedicated namespace to use
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) to provide security
boundary. This will offer strong security for Istio CA.

* Services in the same Kubernetes cluster but different namespaces are able to talk to each other through Istio Auth
without extra trust setup.

**Per-namespace CA**:

[The Istio installation guide]({{home}}/docs/tasks/installing-istio.html#installing-on-an-existing-cluster)
with "Install Istio and enable Istio Auth feature" in step 4 instructs enabling Istio Auth with per-namespace CA.

An Istio CA is deployed in each Kubernetes namespace that enables Istio Auth.
This CA issues certificates and keys to all pods in the same namespace.
This approach is convenient for doing experiments.
Because each Istio CA is scoped within a namespace, Istio CAs in different namespaces will not interfere with each other
and they are easy to [uninstall]({{home}}/docs/tasks/installing-istio.html#uninstalling).

## Before you begin

This task assumes you have:

* Disabled Istio Auth (if you enabled it) for all namespaces in the Kubernetes cluster.
Otherwise, this process will deploy a CA that conflicts with existing CAs.

* Completed steps 1 - 3 in [the Istio installation guide]({{home}}/docs/tasks/installing-istio.html#installing-on-an-existing-cluster).

## Enabling Istio Auth

### Deploying CA

The Istio CA only needs to be deployed once for the cluster.
The following command creates namespace *istio-system* and deploys CA into the namespace:

```bash
kubectl apply -f templates/istio-auth/istio-cluster-ca.yaml
```

### Deploying other services

The following command will enable mTLS for the services in the "default" namespace,
and the services are able to use the per-cluster CA deployed in the last step.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

```bash
kubectl apply -f templates/istio-auth/isio-auth-per-cluster-ca.yaml
```

Follow [the general Istio installation guide]({{home}}/docs/tasks/installing-istio.html) from step 5.

## Disabling Istio Auth

This section shows how to disable Istio Auth in an Istio cluster.
Disabling Istio Auth requires all Istio services and applications to be reconfigured and restarted with auth disabled.

### Removing per-cluster Istio CA

If you would like to disable auth for the entire cluster, you may want to remove the Istio CA.
The following command removes Istio CA and its namespace *istio-system*.

```bash
kubectl delete -f templates/istio-auth/istio-cluster-ca.yaml
```

### Redeploying Istio and applications

Run the following command to uninstall auth-enabled Istio, and redeploy Istio without auth.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

```bash
kubectl delete -f templates/istio-auth/istio-auth-per-cluster-ca.yaml
kubectl apply -f istio.yaml
```

Also, redeploy your application by running:

```bash
kubectl replace -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Verifying Istio Auth setup

### Verifying Istio CA

Verify the per-cluster CA is running in namespace *istio-system*:

```bash
kubectl get pods -n istio-system
```

```bash
NAME                      READY     STATUS    RESTARTS   AGE
istio-ca-11513534-q3dz1   1/1       Running   0          45s
```

### Verifying service configuration

The following commands assume the services are deployed in the default namespace.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

1. Verify AuthPolicy setting in ConfigMap.

   ```bash
   kubectl get configmap istio -o yaml | grep authPolicy
   ```

   Istio Auth is enabled if the line "authPolicy: MUTUAL\_TLS" is uncommented.

2. Check the certificate and key files are mounted onto the application pod *app-pod*.

   ```bash
   kubectl exec <app-pod> -c proxy -- ls /etc/certs
   ```

   ```bash
   cert-chain.pem key.pem root-cert.pem
   ```

3. Check Istio Auth is enabled on Envoy proxies.

   When Istio Auth is enabled for a pod, the *ssl_context* stanzas should be in the pod's proxy config.
   The following commands verifies the proxy config on *app-pod* has *ssl_context* configured:

   ```bash
   kubectl exec <app-pod> -c proxy -- ls /etc/envoy
   ```

   The output should contain the config file "envoy-revX.json". Use the file name in the following command:

   ```bash
   kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-revX.json | grep ssl_context
   ```

   If you see *ssl_context* lines in the output, the proxy has enabled Istio Auth.
