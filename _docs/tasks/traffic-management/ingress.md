---
title: Enabling Ingress Traffic
overview: Describes how to configure Istio to expose a service outside of the service mesh.

order: 30

layout: docs
type: markdown
redirect_from: "/docs/tasks/ingress.html"
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster.
In a Kubernetes environment,
Istio uses [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/)
to configure ingress behavior.


## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).
  
* Make sure your current directory is the `istio` directory.
  
* Start the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) sample,
  which will be used as the destination service to be exposed externally.

  If you installed the [Istio-Initializer]({{home}}/docs/setup/kubernetes/automatic-sidecar-inject.html), do

  ```bash
  kubectl apply -f samples/httpbin/httpbin.yaml
  ```

  Without the Istio-Initializer:

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
  ```

## Configuring ingress (HTTP)

1. Create the Ingress Resource for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: simple-ingress
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
   
   Notice that in this example we are only exposing httpbin's two endpoints: `/headers` as an exact URI path and `/delay/` using an URI prefix.
   
1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers,
     use the ingress' external address:

     ```bash
     kubectl get ingress simple-ingress -o wide
     ```
   
     ```bash
     NAME             HOSTS     ADDRESS                 PORTS     AGE
     simple-ingress   *         130.211.10.121          80        1d
     ```

     ```bash
     export INGRESS_URL=130.211.10.121
     ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:
   
     ```bash
     kubectl get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
     ```

     ```bash
     169.47.243.100
     ```

     along with the istio-ingress service's nodePort for port 80:
   
     ```bash
     kubectl get svc istio-ingress
     ```
   
     ```bash
     NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
     istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
     ```
   
     ```bash
     export INGRESS_URL=169.47.243.100:31486
     ```
   
1. Access the httpbin service using _curl_:

   ```bash
   curl http://$INGRESS_URL/headers
   ```

   ```json
   {
     "headers": {
       "Accept": "*/*", 
       "Content-Length": "0", 
       "Host": "httpbin.default.svc.cluster.local:8000", 
       "User-Agent": "curl/7.51.0", 
       "X-Envoy-Expected-Rq-Timeout-Ms": "15000", 
       "X-Request-Id": "3dd59054-6e26-4af5-87cf-a247bc634bab"
     }
   }
   ```


## Configuring secure ingress (HTTPS)

1. Generate keys if necessary

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

1. Update the secret using `kubectl`

   ```bash
   kubectl create -n istio-system secret tls istio-ingress-certs --key /tmp/tls.key --cert /tmp/tls.crt
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
         - path: /ip
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
   
   Notice that in this example we are only exposing httpbin's `/ip` endpoint.
   
   > Note: Envoy currently only allows a single TLS secret in the ingress since SNI is not yet supported. That means that the secret name field in ingress resource is not used, and the secret must be called `istio-ingress-certs` in `istio-system` namespace.
   
1. Determine the secure ingress URL:
 
   * If your cluster is running in an environment that supports external load balancers,
     use the ingress' external address:
 
     ```bash
     kubectl get ingress secured-ingress -o wide
     ```
    
     ```bash
     NAME              HOSTS     ADDRESS                 PORTS     AGE
     secured-ingress   *         130.211.10.121          80, 443   1d
     ```
 
     ```bash
     export SECURE_INGRESS_URL=130.211.10.121
     ```
 
     > Note that in this case SECURE_INGRESS_URL should be the same as INGRESS_URL that you set previously.
    
   * If load balancers are not supported, use the ingress controller pod's hostIP:
    
     ```bash
     kubectl get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
     ```
 
     ```bash
     169.47.243.100
     ```
 
     along with the istio-ingress service's nodePort for port 443:
    
     ```bash
     kubectl get svc istio-ingress
     ```
    
     ```bash
     NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
     istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
     ```
    
     ```bash
     export SECURE_INGRESS_URL=169.47.243.100:32254
     ```
    
1. Access the secured httpbin service using _curl_:

   ```bash
   curl -k https://$SECURE_INGRESS_URL/ip
   ```
   
   ```json
   {
     "origin": "129.42.161.35"
   }
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
   time curl -o /dev/null -s -w "%{http_code}\n" http://$INGRESS_URL/delay/5
   ```
   
   ```bash
   200
   
   real    0m5.024s
   user    0m0.003s
   sys     0m0.003s
   ```

   The request should return 200 (OK) in approximately 5 seconds.

1. Use `istioctl` to set a 3s timeout on calls to the httpbin service

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: httpbin-3s-rule
   spec:
     destination:
       name: httpbin
     http_req_timeout:
       simple_timeout:
         timeout: 3s
   EOF
   ```
   
   Note that you may need to change the `default` namespace to the namespace of the `httpbin` application.

1. Wait a few seconds, then issue the _curl_ request again:
 
   ```bash
   time curl -o /dev/null -s -w "%{http_code}\n" http://$INGRESS_URL/delay/5
   ```

   ```bash
   504
   
   real    0m3.149s
   user    0m0.004s
   sys     0m0.004s
   ```
   
   This time a 504 (Gateway Timeout) appears after 3 seconds.
   Although httpbin was waiting 5 seconds, Istio cut off the request at 3 seconds.

> Note: HTTP fault injection (abort and delay) is not currently supported by ingress proxies.

## Understanding ingresses

Ingresses provide gateways for external traffic to enter the Istio service mesh
and make the traffic management and policy features of Istio available for edge services.

In the preceding steps we created a service inside the Istio service mesh and showed how
to expose both HTTP and HTTPS endpoints of the service to external traffic.
We also showed how to control the ingress traffic using an Istio route rule.


## Cleanup

1. Remove the secret, Ingress Resource definitions and Istio rule.
    
   ```bash
   istioctl delete routerule httpbin-3s-rule
   kubectl delete ingress simple-ingress secured-ingress 
   kubectl delete secret ingress-secret
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```bash
   kubectl delete -f samples/httpbin/httpbin.yaml
   ```


## What's next

* Learn more about [routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

* Learn how to expose external services by [enabling egress traffic](./egress.html).
