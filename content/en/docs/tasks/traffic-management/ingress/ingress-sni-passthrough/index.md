---
title: Ingress Gateway without TLS Termination
description: Describes how to configure SNI passthrough for an ingress gateway.
weight: 30
keywords: [traffic-management,ingress,https]
aliases:
  - /docs/examples/advanced-gateways/ingress-sni-passthrough/
---

The [Securing Gateways with HTTPS](/docs/tasks/traffic-management/ingress/secure-ingress-mount/) task describes how to configure HTTPS
ingress access to an HTTP service. This example describes how to configure HTTPS ingress access to an HTTPS service,
i.e., configure an ingress gateway to perform SNI passthrough, instead of TLS termination on incoming requests.

The example HTTPS service used for this task is a simple [NGINX](https://www.nginx.com) server.
In the following steps you first deploy the NGINX service in your Kubernetes cluster.
Then you configure a gateway to provide ingress access to the service via host `nginx.example.com`.

## Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1)

1.  Create a root certificate and private key to sign the certificate for your services:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Create a certificate and a private key for `nginx.example.com`:

    {{< text bash >}}
    $ openssl req -out nginx.example.com.csr -newkey rsa:2048 -nodes -keyout nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in nginx.example.com.csr -out nginx.example.com.crt
    {{< /text >}}

## Deploy an NGINX server

1. Create a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's
   certificate.

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com.key --cert nginx.example.com.crt
    {{< /text >}}

1.  Create a configuration file for the NGINX server:

    {{< text bash >}}
    $ cat <<EOF > ./nginx.conf
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
    $ cat <<EOF | istioctl kube-inject -f - | kubectl apply -f -
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
    printed correctly, i.e., `common name` is equal to `nginx.example.com`.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
    ...
    SSL connection using TLS1.2 / ECDHE_RSA_AES_128_GCM_SHA256
      server certificate verification SKIPPED
      server certificate status verification SKIPPED
      common name: nginx.example.com (matched)
      server certificate expiration date OK
      server certificate activation date OK
      certificate public key: RSA
      certificate version: #3
      subject: CN=nginx.example.com; O=some organization
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: O=example Inc.; CN=example.com

    > GET / HTTP/1.1
    > User-Agent: curl/7.35.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.15.2
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

## Configure an ingress gateway

1.  Define a `Gateway` with a `server` section for port 443. Note the `PASSTHROUGH` TLS mode which instructs
    the gateway to pass the ingress traffic AS IS, without terminating TLS.

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

1.  Configure routes for traffic entering via the `Gateway`:

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
          sni_hosts:
          - nginx.example.com
        route:
        - destination:
            host: my-nginx
            port:
              number: 443
    EOF
    {{< /text >}}

1.  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    to define the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables.

1.  Access the NGINX service from outside the cluster. Note that the correct certificate is returned by the server and
    it is successfully verified (_SSL certificate verify ok_ is printed).

    {{< text bash >}}
    $ curl -v --resolve nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt https://nginx.example.com:$SECURE_INGRESS_PORT
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

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice nginx
    {{< /text >}}

1.  Delete the certificates and keys:

    {{< text bash >}}
    $ rm example.com.crt example.com.key nginx.example.com.crt nginx.example.com.key nginx.example.com.csr
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}
