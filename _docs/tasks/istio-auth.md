---
title: Testing Istio Auth
overview: This task shows you how to verify and test Istio-Auth.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

Through this task, you will learn how to:

* Verify Istio Auth setup

* Manually test Istio Auth

## Before you begin

This task assumes you have:

* Installed Istio with Auth by following
[the Istio installation task]({{home}}/docs/tasks/installing-istio.html).
Note to choose "enable Istio Auth feature" at step 5 in
"[Installation steps]({{home}}/docs/tasks/installing-istio.html#installation-steps)".

## Verifying Istio Auth setup

The following commands assume the services are deployed in the default namespace.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

### Verifying Istio CA

Verify the cluster-level CA is running:

```bash
kubectl get deploy -l istio=istio-ca
```

```bash
NAME       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-ca   1         1         1            1           1m
```

Istio CA is up if the "AVAILABLE" column is 1.

### Verifying service configuration

1. Verify AuthPolicy setting in ConfigMap.

   ```bash
   kubectl get configmap istio -o yaml | grep authPolicy
   ```

   Istio Auth is enabled if the line "authPolicy: MUTUAL\_TLS" is uncommented.

1. Check Istio Auth is enabled on Envoy proxies.

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

## Testing Istio Auth

When running Istio auth-enabled services, you can use curl in one service's
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
   cert-chain.pem   key.pem   root-cert.pem
   ``` 
   
   Note that cert-chain.pem is envoy's cert that needs to present to the other side. key.pem is envoy's private key paired with cert-chain.pem. root-cert.pem is the root cert to verify the other side's cert. Currently we only have one CA, so all envoys have the same root-cert.pem.  
   
1. send requests to another service, for example, details.
   ```bash
   curl https://details:9080 -v --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
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
