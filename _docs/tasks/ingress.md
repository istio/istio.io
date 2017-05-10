---
title: Enabling Ingress Traffic
overview: Describes how to configure Istio to expose a service outside of the service mesh.

order: 30

layout: docs
type: markdown
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster.
In a Kubernetes environment,
Istio uses [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/)
to configure ingress behavior.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](./installing-istio.html).

* Start the [httpbin](https://github.com/istio/istio/tree/master/demos/apps/httpbin) sample,
  which will be used as the destination service to be exposed externally.  

## Configuring ingress (HTTP)

1. Create the Ingress Resource for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: istio-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     rules:
     - http:
         paths:
         - path: /headers
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
   
   Notice that in this example we are only exposing httpbin's `/headers` and `/delay` endpoints.
   
1. Determine the ingress URL:

   If your cluster is running in an environment that supports external load balancers,
   use the ingress' external address:

   ```bash
   kubectl get ingress -o wide
   ```
   
   ```
   NAME      HOSTS     ADDRESS                 PORTS     AGE
   gateway   *         130.211.10.121          80        1d
   export INGRESS_URL=130.211.10.121:80
   ```

   If load balancers are not supported, use the service NodePort instead:
   
   ```bash
   export INGRESS_URL=$(kubectl get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -o jsonpath='{.spec.ports[0].nodePort}')
   ```

1. Access the httpbin service using _curl_:

   ```bash
   curl http://$INGRESS_URL/headers
   ```

   ```
   .. response ..
   ```

## Configuring secure ingress (HTTPS)

1. Generate keys if necessary

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

1. Create the secret using `kubectl`

   ```bash
   kubectl create secret tls ingress-secret --key /tmp/tls.key --cert /tmp/tls.crt
   ```

1. Create the Ingress Resource for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: secured-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     tls:
       - secretName: ingress-secret
     rules:
     - http:
         paths:
         - path: /html
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
   
   Notice that in this example we are only exposing httpbin's `/html` endpoint.
   
   _Remark:_ Envoy currently only allows a single TLS secret in the ingress since SNI is not yet supported.
   
1. Access the secured httpbin service using _curl_:

   ```bash
   curl -k https://$INGRESS_URL/html
   ```
   
   ```
   <!DOCTYPE html>
   <html>
   ...
   ```


## Setting Istio rules on an edge service

Similar to inter-cluster requests, Istio 
[routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html)
can also be set for edge services
that are called from outside the cluster.
To illustrate we will use [istioctl]({{home}}/docs/reference/commands/istioctl.html)
to set a timeout rule on calls to the httpbin service.

1. Invoke the httpbin `/delay` endpoint you exposed previously:

   ```bash
   time curl http://$INGRESS_URL/delay/5
   ```
   
   ```
   ...
   real    0m5.024s
   user    0m0.003s
   sys     0m0.003s
   ```

   The request should return in approximately 5 seconds.

1. Use `istioctl` to set a 3s timeout on calls to the httpbin service

   ```bash
   cat <<EOF | istioctl create
   type: route-rule
   name: httpbin-3s-rule
   spec:
     destination: httpbin.default.svc.cluster.local
     http_req_timeout:
       simple_timeout:
         timeout: 3s
   EOF
   ```
   
   Note that you may need to change `default` namespace to the namespace of `httpbin` application.

1. Wait a few seconds, then issue the _curl_ request again:
 
   ```bash
   time curl http://$INGRESS_URL/delay/5
   ```

   ```
   ...
   real    0m3.022s
   user    0m0.004s
   sys     0m0.003s
   ```
   
   This time the response appears after
   3 seconds.  Although _httpbin_ was waiting 5 seconds, Istio cut off the request at 3 seconds.


## Understanding ...

Here's an interesting thing to know about the steps you just did.

## What's next

* Learn more about [this](...).

* See this [related task](...).
