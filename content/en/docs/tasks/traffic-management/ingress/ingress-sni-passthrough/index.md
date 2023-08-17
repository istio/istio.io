---
title: Ingress Gateway without TLS Termination
description: Describes how to configure SNI passthrough for an ingress gateway.
weight: 30
keywords: [traffic-management,ingress,https]
aliases:
  - /docs/examples/advanced-gateways/ingress-sni-passthrough/
owner: istio/wg-networking-maintainers
test: yes
---

The [Securing Gateways with HTTPS](/docs/tasks/traffic-management/ingress/secure-ingress/) task describes how to configure HTTPS
ingress access to an HTTP service. This example describes how to configure HTTPS ingress access to an HTTPS service,
i.e., configure an ingress gateway to perform SNI passthrough, instead of TLS termination on incoming requests.

The example HTTPS service used for this task is a simple [NGINX](https://www.nginx.com) server.
In the following steps you first deploy the NGINX service in your Kubernetes cluster.
Then you configure a gateway to provide ingress access to the service via host `nginx.example.com`.

{{< boilerplate gateway-api-support >}}

{{< boilerplate gateway-api-experimental >}}

## Before you begin

Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

## Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1):

1.  Create a root certificate and private key to sign the certificate for your services:

    {{< text bash >}}
    $ mkdir example_certs
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs/example.com.key -out example_certs/example.com.crt
    {{< /text >}}

1.  Create a certificate and a private key for `nginx.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs/nginx.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs/nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs/example.com.crt -CAkey example_certs/example.com.key -set_serial 0 -in example_certs/nginx.example.com.csr -out example_certs/nginx.example.com.crt
    {{< /text >}}

## Deploy an NGINX server

1. Create a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's
   certificate.

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs \
      --key example_certs/nginx.example.com.key \
      --cert example_certs/nginx.example.com.crt
    {{< /text >}}

1.  Create a configuration file for the NGINX server:

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name nginx.example.com;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the NGINX server:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Deploy the NGINX server:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
            sidecar.istio.io/inject: "true"
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
    EOF
    {{< /text >}}

1.  To test that the NGINX server was deployed successfully, send a request to the server from its sidecar proxy
    without checking the server's certificate (use the `-k` option of `curl`). Ensure that the server's certificate is
    printed correctly, i.e., `common name (CN)` is equal to `nginx.example.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name})" -c istio-proxy -- curl -sS -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
    ...
    SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
    ALPN, server accepted to use http/1.1
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: May 27 14:18:47 2020 GMT
      expire date: May 27 14:18:47 2021 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.

    > GET / HTTP/1.1
    > User-Agent: curl/7.58.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.17.10
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

## Configure an ingress gateway

1.  Define a `Gateway` exposing port 443 with passthrough TLS mode. This instructs
    the gateway to pass the ingress traffic "as is", without terminating TLS:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - nginx.example.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "nginx.example.com"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Configure routes for traffic entering via the `Gateway`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  gateways:
  - mygateway
  tls:
  - match:
    - port: 443
      sniHosts:
      - nginx.example.com
    route:
    - destination:
        host: my-nginx
        port:
          number: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: nginx
spec:
  parentRefs:
  - name: mygateway
  hostnames:
  - "nginx.example.com"
  rules:
  - backendRefs:
    - name: my-nginx
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Determine the ingress IP and port:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Follow the instructions in
[Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
to set the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Use the following commands to set the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway
$ export INGRESS_HOST=$(kubectl get gtw mygateway -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Access the NGINX service from outside the cluster. Note that the correct certificate is returned by the server and
    it is successfully verified (_SSL certificate verify ok_ is printed).

    {{< text bash >}}
    $ curl -v --resolve "nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" --cacert example_certs/example.com.crt "https://nginx.example.com:$SECURE_INGRESS_PORT"
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify ok.

      < HTTP/1.1 200 OK
      < Server: nginx/1.15.2
      ...
      <html>
      <head>
      <title>Welcome to nginx!</title>
    {{< /text >}}

## Cleanup

1.  Delete the gateway configuration and route:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice nginx
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete gtw mygateway
$ kubectl delete tlsroute nginx
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Remove the NGINX resources and configuration file:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ rm ./nginx.conf
    {{< /text >}}

1)  Delete the certificates and keys:

    {{< text bash >}}
    $ rm -rf ./example_certs
    {{< /text >}}
