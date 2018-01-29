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
The following are the known limitations of Istio ingress:

1. Istio supports standard Kubernetes Ingress specification without
   annotations. There is no support for `ingress.kubernetes.io` annotations
   in the Ingress resource specifications. Any annotation other than
   `kubernetes.io/ingress.class: istio` will be ignored.
2. Regular expressions in paths are not supported.
3. Fault injection at the Ingress is not supported.

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
         - path: /status/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```
 
   `/.*` is a special Istio notation that is used to indicate a prefix
   match, specifically a
   [rule match configuration]({{home}}/docs/reference/config/traffic-rules/routing-rules.html#matchcondition)
   of the form (`prefix: /`).
   
### Verifying ingress

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

   ```
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 48
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```bash
   curl -I http://$INGRESS_HOST/headers
   ```

   ```
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

## Configuring secure ingress (HTTPS)

1. Generate certificate and key for the ingress

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

1. Create the secret

   Create the secret `istio-ingress-certs` in namespace `istio-system` using `kubectl`. The Istio Ingress will automatically
   load the secret.

   > Note: the secret must be called `istio-ingress-certs` in `istio-system` namespace, for it to be mounted on Istio Ingress.

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
         - path: /status/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/.*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   > Note: Because SNI is not yet supported, Envoy currently only allows a single TLS secret in the ingress.
   > That means the secretName field in ingress resource is not used.

### Verifying ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers,
     use the ingress' external address:

     ```bash
     kubectl get ingress secure-ingress -o wide
     ```

     ```bash
     NAME             HOSTS     ADDRESS                 PORTS     AGE
     secure-ingress   *         130.211.10.121          80        1d
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
   curl -I -k https://$INGRESS_HOST/status/200
   ```

   ```
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 96
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```bash
   curl -I -k http://$INGRESS_HOST/headers
   ```

   ```
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

## Using Istio Routing Rules with Ingress

Istio's routing rules can be used to achieve a greater degree of control
when routing requests to backend services. For example, the following
route rule sets a 4s timeout for all calls to the httpbin service on the
/delay URL.

```bash
cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: status-route
spec:
  destination:
    name: httpbin
  match:
    # Optionally limit this rule to istio ingress pods only
    source:
      name: istio-ingress
      labels:
        istio: ingress
    request:
      headers:
        uri:
          prefix: /delay/ #must match the path specified in ingress spec
              # if using prefix paths (/delay/.*), omit the .*.
              # if using exact match, use exact: /status
  route:
  - weight: 100
  httpReqTimeout:
    simpleTimeout:
      timeout: 4s
EOF
```

If you were to make a call to the ingress with the URL
`http://$INGRESS_HOST/delay/10`, you will find that the call returns in 4s
instead of the expected 10s delay.

You can use other features of the route rules such as redirects, rewrites,
routing to multiple versions, regular expression based match in HTTP
headers, websocket upgrades, timeouts, retries, etc. Please refer to the
[routing rules]({{home}}/docs/reference/config/traffic-rules/routing-rules.html)
for more details.

> Note 1: Fault injection does not work at the Ingress

> Note 2: When matching requests in the routing rule, use the same exact
> path or prefix as the one used in the Ingress specification.

## Understanding ingresses

Ingresses provide gateways for external traffic to enter the Istio service
mesh and make the traffic management and policy features of Istio available
for edge services.

The servicePort field in the Ingress specification can take a port number
(integer) or a name. The port name must follow the Istio port naming
conventions (e.g., `grpc-*`, `http2-*`, `http-*`, etc.) in order to
function properly. The name used must match the port name in the backend
service declaration.

In the preceding steps we created a service inside the Istio service mesh
and showed how to expose both HTTP and HTTPS endpoints of the service to
external traffic. We also showed how to control the ingress traffic using
an Istio route rule.

## Cleanup

1. Remove the secret and Ingress Resource definitions.
    
   ```bash
   kubectl delete ingress simple-ingress secure-ingress 
   kubectl delete -n istio-system secret istio-ingress-certs
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```bash
   kubectl delete -f samples/httpbin/httpbin.yaml
   ```


## Further reading

* Learn more about [Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/).

* Learn more about [Routing Rules]({{home}}/docs/reference/config/traffic-rules/routing-rules.html).
