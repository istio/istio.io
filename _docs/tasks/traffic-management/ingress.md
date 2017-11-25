---
title: Istio Ingress Controller
overview: Describes how to configure the Istio ingress controller on Kubernetes.

order: 30

layout: docs
type: markdown
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster.
In a Kubernetes environment, the [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/)
allows users to specify services that should be exposed outside the
cluster. However, the Ingress Resource specification is very minimal,
allowing users to specify just hosts, paths and their backing services.
To take advantage of Istio's advanced routing capabilities, we recommend
combining a minimal Ingress Resource specification with Istio's route
rules.

> Note: Istio does not support `ingress.kubernetes.io` annotations in the ingress resource
> specifications. Any annotation other than `kubernetes.io/ingress.class: istio` will be ignored.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).
  
* Make sure your current directory is the `istio` directory.
  
* Start the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) sample,
  which will be used as the destination service to be exposed externally.

  If you installed the [Istio-Initializer]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection), do

  ```bash
  kubectl apply -f samples/httpbin/httpbin.yaml
  ```

  Without the Istio-Initializer:

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
  ```

## Configuring ingress (HTTP)

1. Create a basic Ingress Resource for the httpbin service

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
         - path: /.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
 
   `/.*` is a special Istio notation that is used to indicate a prefix
   match, specifically a configuration of the form (`prefix: /`). This
   configuration above will allow access to all URIs in the httpbin
   service. However we wish to enable access only to specific URIs under the
   httpbin service. Let us define a default _deny all_ route rule that
   provides this behavior:

   ```bash
   cat <<EOF | istioctl create -f -
   ## Deny all access from istio-ingress
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: deny-route
   spec:
     destination:
       name: httpbin
     match:
       # Limit this rule to istio ingress pods only
       source:
         name: istio-ingress
         labels:
           istio: ingress
     precedence: 1
     route:
     - weight: 100
     httpFault:
       abort:
         percent: 100
         httpStatus: 403 #Forbidden for all URLs
   EOF
   ```   
2. Now, allow requests to `/status/` prefix by defining a route rule of
   higher priority.

   ```bash
   cat <<EOF | istioctl create -f -
   ## Allow requests to /status prefix
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: status-route
   spec:
     destination:
       name: httpbin
     match:
       # Limit this rule to istio ingress pods only
       source:
         name: istio-ingress
         labels:
           istio: ingress
       request:
         headers:
           uri:
             prefix: /status
     precedence: 2 #must be higher precedence than the deny-route
     route:
     - weight: 100
   EOF
   ```
  You can use other features of the route rules such as redirects,
  rewrites, regular expression based match in HTTP headers, websocket
  upgrades, timeouts, retries, and so on. Please refer to the
  [routing rules]({{home}}/docs/reference/config/traffic-rules/routing-rules.html)
  for more details.

## Verifying ingress

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
     export INGRESS_HOST=130.211.10.121
     ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:
   
     ```bash
     kubectl -n istio-system get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
     ```

     ```bash
     169.47.243.100
     ```

     along with the istio-ingress service's nodePort for port 80:
   
     ```bash
     kubectl -n istio-system get svc istio-ingress
     ```
   
     ```bash
     NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
     istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
     ```
   
     ```bash
     export INGRESS_HOST=169.47.243.100:31486
     ```
   
1. Access the httpbin service using _curl_:

   ```bash
   curl -I http://$INGRESS_HOST/status/200
   ```

   ```bash
   HTTP/1.1 200 OK
   Server: meinheld/0.6.1
   Date: Thu, 05 Oct 2017 21:23:17 GMT
   Content-Type: text/html; charset=utf-8
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Credentials: true
   X-Powered-By: Flask
   X-Processed-Time: 0.00105214118958
   Content-Length: 0
   Via: 1.1 vegur
   Connection: Keep-Alive
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 403

   ```bash
   curl -I http://$INGRESS_HOST/headers
   ```

   ```bash
   HTTP/1.1 403 FORBIDDEN
   Server: meinheld/0.6.1
   Date: Thu, 05 Oct 2017 21:24:47 GMT
   Content-Type: text/html; charset=utf-8
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Credentials: true
   X-Powered-By: Flask
   X-Processed-Time: 0.000759840011597
   Content-Length: 0
   Via: 1.1 vegur
   Connection: Keep-Alive
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
     name: secure-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     tls:
       - secretName: istio-ingress-certs # currently ignored
     rules:
     - http:
         paths:
         - path: /.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   Create the _deny rule_ and the rule for `/status` prefix as described
   earlier. Set the INGRESS_HOST to point to the ip address and the
   port number of the ingress service as shown earlier.

   > Note: Envoy currently only allows a single TLS secret in the ingress since SNI is not yet supported. That means that the secret name field in ingress resource is not used, and the secret must be called `istio-ingress-certs` in `istio-system` namespace.

    
1. Access the secured httpbin service using _curl_:

   ```bash
   curl -I -k https://$INGRESS_HOST/status/200
   ```

## Configuring ingress for gRPC

The ingress controller currently doesn't support `.` characters in the `path`
field. This is an issue for gRPC services using namespaces. In order to work
around the issue, traffic can be directed through a common dummy service, with
route rules set up to intercept traffic and redirect to the intended services.

1. Create a dummy ingress service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: v1
   kind: Service
   metadata:
     name: ingress-dummy-service
   spec:
     ports:
     - name: grpc
       port: 1337
   EOF
   ```

1. Create a catch-all ingress pointing to the dummy service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: all-istio-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     rules:
     - http:
         paths:
         - backend:
             serviceName: ingress-dummy-service
             servicePort: grpc
   EOF
   ```

1. Create a RouteRule for each service, redirecting from the dummy service to
   the correct gRPC service:

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: foo-service-route
   spec:
     destination:
       name: ingress-dummy-service
     match:
       request:
         headers:
           uri:
             prefix: "/foo.FooService"
     precedence: 1
     route:
     - weight: 100
       destination:
         name: foo-service
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: bar-service-route
   spec:
     destination:
       name: ingress-dummy-service
     match:
       request:
         headers:
           uri:
             prefix: "/bar.BarService"
     precedence: 1
     route:
     - weight: 100
       destination:
         name: bar-service
   EOF      
   ```


## Understanding ingresses

Ingresses provide gateways for external traffic to enter the Istio service mesh
and make the traffic management and policy features of Istio available for edge services.

In the preceding steps we created a service inside the Istio service mesh and showed how
to expose both HTTP and HTTPS endpoints of the service to external traffic.
We also showed how to control the ingress traffic using an Istio route rule.

## Cleanup

1. Remove the secret, Ingress Resource definitions and Istio rule.
    
   ```bash
   istioctl delete routerule deny-route status-route
   kubectl delete ingress simple-ingress secure-ingress 
   kubectl delete -n istio-system secret istio-ingress-certs
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```bash
   kubectl delete -f samples/httpbin/httpbin.yaml
   ```


## Further reading

* Learn more about [Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/).

* Learn more about [routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html).
