---
title: Enabling Istio Auth
overview: This task shows you how to setup Istio-Auth to provide mutual TLS authentication between services.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

Through this task,
you will learn how to do the following for Istio Auth with the **cluster-level Istio CA (Certificate Authority)**:

* Install Istio with Auth

* Verify Istio Auth setup

* Uninstall Istio with Auth

## Cluster-level CA vs. namespace-level CA

There are two deployment modes for Istio CA, cluster-level and namespace-level.
The following describes the differences between them.

**Cluster-level CA**:

This task focuses on Istio Auth with the cluster-level CA.

Only a single Istio CA is present in a Kubernetes cluster,
which is always deployed in a dedicated namespace. The Istio CA issues certificates and keys to
all pods in the Kubernetes cluster. It offers the following benefits:

* In the near future, Istio will enforce the dedicated namespace to use
[Kubernetes RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) (beta in Kubernetes V1.6) to provide security
boundary. This will offer strong security for Istio CA.

* Services in the same Kubernetes cluster but different namespaces are able to talk to each other through Istio Auth
without extra trust setup.

**Namespace-level CA**:

[The Istio installation task]({{home}}/docs/tasks/installing-istio.html#installing-on-an-existing-cluster)
with "Install Istio and enable Istio Auth feature" in step 5 instructs enabling Istio Auth with the namespace-level CA.

An Istio CA is deployed in each Kubernetes namespace that enables Istio Auth.
This CA issues certificates and keys to all pods in the same namespace.
This approach is convenient for doing experiments.
Because each Istio CA is scoped within a namespace, Istio CAs in different namespaces will not interfere with each other
and they are easy to [uninstall]({{home}}/docs/tasks/installing-istio.html#uninstalling).

## Before you begin

This task assumes you have:

* Uninstalled Istio for the namespaces you plan to enable Istio Auth.
To uninstall Istio, please follow the [uninstall instructions]({{home}}/docs/tasks/installing-istio.html#uninstalling).

* Not enabled Istio Auth for any namespace in the Kubernetes cluster.
Otherwise, this process will deploy a CA that conflicts with existing CAs.

* Completed "Prerequisites" and "Installation steps" until step 4
in [the Istio installation task]({{home}}/docs/tasks/installing-istio.html)

## Installing Istio with Auth

### Deploying CA

The Istio CA only needs to be deployed once for the cluster.
The following command creates a namespace *istio-system* and deploys the cluster-level CA into the namespace:

```bash
kubectl apply -f install/kubernetes/templates/istio-auth/istio-cluster-ca.yaml
```

### Deploying other Istio components

Other Istio components should be deployed in the same namespace with your application.
The following command will enable
[mTLS](https://en.wikipedia.org/wiki/Mutual_authentication)
for the services in the "default" namespace,
and the services are able to use the cluster-level CA deployed in the last step.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

```bash
kubectl apply -f install/kubernetes/templates/istio-auth/istio-auth-with-cluster-ca.yaml
```

### Deploying your applicaiton

You can now deploy your own application, or one of the sample applications provided with the installation,
for example [BookInfo]({{home}}/docs/samples/bookinfo.html).

To deploy the application, use [istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject)
to automatically inject Envoy containers in your application pods:

```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Verifying Istio Auth setup

### Verifying Istio CA

Verify the cluster-level CA is running in namespace *istio-system*:

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

   The output should contain the config file "envoy-rev<X>.json". Use the file name in the following command:

   ```bash
   kubectl exec <app-pod> -c proxy -- cat /etc/envoy/envoy-rev<X>.json | grep ssl_context
   ```

   If you see *ssl_context* lines in the output, the proxy has enabled Istio Auth.

## Uninstalling Istio with Auth

This section shows how to uninstall the cluster-level Istio CA and other Istio components.

### Uninstalling the cluster-level Istio CA

If you would like to disable auth for the entire cluster, you may want to remove the Istio CA.
The following command removes Istio CA and its namespace *istio-system*.

```bash
kubectl delete -f install/kubernetes/templates/istio-auth/istio-cluster-ca.yaml
```

### Uninstalling other Istio components

Run the following command to uninstall the Istio components other than the Istio CA.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

```bash
kubectl delete -f install/kubernetes/templates/istio-auth/istio-auth-with-cluster-ca.yaml
```

## Playing with auth 

When running Istio-enabled services, you can use curl in one service's
envoy to send request to other services.
For example, after starting the [BookInfo]({{home}}/docs/samples/bookinfo.html) 
sample application you can ssh into the envoy container of `productpage` service, 
and send request to other services by curl. 

There are several steps:
   
1. get the productpage pod name
   ```bash
   kubectl get pods -l app=productpage 
   ```
   ```bash
   NAME                              READY     STATUS    RESTARTS   AGE
   productpage-v1-4184313719-5mxjc   2/2       Running   0          23h
   ```

   Make sure the pod is "Running".

1. ssh into the envoy container 
   ```bash
   kubectl exec -it productpage-v1-4184313719-5mxjc -c proxy /bin/bash 
   ```

1. make sure the key/cert is in /etc/certs/ directory
   ```bash
   ls /etc/certs/ 
   ```
   ```bash
   cert-chain.pem   key.pem 
   ``` 
   
1. send requests to another service, for example, details.
   ```bash
   curl https://details:9080 -v --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem -k
   ```
   ```bash
   ...
   < HTTP/1.1 200 OK
   < content-type: text/html; charset=utf-8
   < content-length: 1867
   < server: envoy
   < date: Thu, 11 May 2017 18:59:42 GMT
   < x-envoy-upstream-service-time: 2
   ...
   ```
  
The service name and port are defined [here](https://github.com/istio/istio/blob/master/samples/apps/bookinfo/bookinfo.yaml).
   
Note that Istio uses [Kubernetes service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) 
as service identity, which offers stronger security than service name 
(refer [here](https://istio.io/docs/concepts/network-and-auth/auth.html#identity) for more information). 
Thus the certificates used in Istio do not have service name, which is the information that curl needs to verify
server identity. As a result, we use curl option '-k' to prevent the curl client from verifying service identity
in server's (i.e., productpage) certificate. 
Please check secure naming [here](https://istio.io/docs/concepts/network-and-auth/auth.html#workflow) for more information
about how the client verifies the server's identity in Istio.
