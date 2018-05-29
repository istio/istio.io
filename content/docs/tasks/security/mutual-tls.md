---
title: Testing mutual TLS
description: Shows you how to verify and test Istio's automatic mutual TLS authentication.
weight: 10
---

Through this task, you will learn how to:

* Verify the Istio mutual TLS Authentication setup

* Manually test the authentication

## Before you begin

This task assumes you have a Kubernetes cluster:

* Installed Istio with mutual TLS authentication by following
[the Istio installation task](/docs/setup/kubernetes/quick-start/).
Note to choose "enable Istio mutual TLS Authentication feature" at step 5 in
"[Installation steps](/docs/setup/kubernetes/quick-start/#installation-steps)".

> Starting with Istio  0.7, you can use [authentication policy](/docs/concepts/security/authn-policy/) to config mTLS for all/selected services in a namespace (repeated for all namespaces to get global setting). See [authentication policy task](/docs/tasks/security/authn-policy/)

## Verifying Istio's mutual TLS authentication setup

The following commands assume the services are deployed in the default namespace.
Use the parameter *-n yournamespace* to specify a namespace other than the default one.

### Verifying Citadel

Verify the cluster-level Citadel is running:

```command
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
```

Citadel is up if the "AVAILABLE" column is 1.

### Verifying service configuration

1.  Verify AuthPolicy setting in ConfigMap.

    ```command
    $ kubectl get configmap istio -o yaml -n istio-system | grep authPolicy | head -1
    ```

    Istio mutual TLS authentication is enabled if the line `authPolicy: MUTUAL_TLS` is uncommented (doesn't have a `#`).

## Testing the authentication setup

When running Istio with mutual TLS authentication turned on, you can use curl in one service's
Envoy to send request to other services.
For example, after starting the [Bookinfo](/docs/guides/bookinfo/)
sample application you can ssh into the Envoy container of `productpage` service,
and send request to other services by curl.

There are several steps:

1. get the productpage pod name
   
    ```command
    $ kubectl get pods -l app=productpage
    NAME                              READY     STATUS    RESTARTS   AGE
    productpage-v1-4184313719-5mxjc   2/2       Running   0          23h
    ```

    Make sure the pod is "Running".

1. ssh into the Envoy container
   
    ```command
    $ kubectl exec -it productpage-v1-4184313719-5mxjc -c istio-proxy /bin/bash
    ```

1. make sure the key/cert is in /etc/certs/ directory
   
    ```command
    $ ls /etc/certs/
    cert-chain.pem   key.pem   root-cert.pem
    ```

    > `cert-chain.pem` is Envoy's cert that needs to present to the other side. `key.pem` is Envoy's private key
    paired with Envoy's cert in `cert-chain.pem`. `root-cert.pem` is the root cert to verify the peer's cert.
    In this example, we only have one Citadel in a cluster, so all Envoys have the same `root-cert.pem`.

1. make sure 'curl' is installed by
   
    ```command
    $ curl
    ```
    
    If curl is installed, you should see something like
   
    ```plain
    curl: try 'curl --help' or 'curl --manual' for more information
    ```

    Otherwise run the command below to start over
   
    ```command
    $ kubectl apply -f <(istioctl kube-inject --debug -f samples/bookinfo/kube/bookinfo.yaml)
    ```

    > Istio proxy image does not have curl installed while the debug image does. The "--debug" flag in above command redeploys the service with debug image.

1. send requests to another service, for example, details.
   
    ```command
    $ curl https://details:9080/details/0 -v --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
    ...
    error fetching CN from cert:The requested data were not available.
    ...
    < HTTP/1.1 200 OK
    < content-type: text/html; charset=utf-8
    < content-length: 1867
    < server: envoy
    < date: Thu, 11 May 2017 18:59:42 GMT
    < x-envoy-upstream-service-time: 2
    ...
    ```

The service name and port are defined [here](https://github.com/istio/istio/blob/master/samples/bookinfo/kube/bookinfo.yaml).

Note that Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
as service identity, which offers stronger security than service name
(refer [here](/docs/concepts/security/mutual-tls/#identity) for more information).
Thus the certificates used in Istio do not have service names, which is the information that `curl` needs to verify
server identity. As a result, we use `curl` option `-k` to prevent the `curl` client from aborting when failing to
find and verify the server name (i.e., productpage.ns.svc.cluster.local) in the certificate provided by the server.

Please check [secure naming](/docs/concepts/security/mutual-tls/#workflow) for more information
about how the client verifies the server's identity in Istio.

What we are demonstrating and verifying above is that the server accepts the connection from the client. Try not giving the client `--key` and `--cert` and observe you are not allowed to connect and you do not get an HTTP 200.

## What's next

* Learn more about the design principles behind Istio's automatic mTLS authentication
  between all services in this [blog](/blog/2017/0.1-auth/).
