---
title: Ingress Gateway without TLS Termination
description: Describes how to configure SNI passthrough for an ingress gateway.
weight: 10
keywords: [traffic-management,ingress, https]
---

The [Securing Gateways with HTTPS](/docs/tasks/traffic-management/secure-ingress/) task describes how to configure HTTPS
ingress access to an HTTP service. This example describes how to configure HTTPS ingress access to an HTTPS service,
i.e., configure an ingress gateway to perform SNI passthrough, instead of TLS termination on incoming requests.

The example HTTPS service used for this task is a simple [NGINX](https://www.nginx.com) server.
In the following steps you first deploy the NGINX service in your Kubernetes cluster.
Then you configure a gateway to provide ingress access to the service via host `nginx.example.com`.

## Generate client and server certificates and keys

Generate the certificates and keys in the same way as in the [Securing Gateways with HTTPS](/docs/tasks/traffic-management/secure-ingress/#generate-client-and-server-certificates-and-keys) task.

1.  Clone the <https://github.com/nicholasjackson/mtls-go-example> repository:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  Change directory to the cloned repository:

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1.  Generate the certificates for `nginx.example.com`.
    Use any password with the following command:

    {{< text bash >}}
    $ ./generate.sh nginx.example.com password
    {{< /text >}}

    When prompted, select `y` for all the questions.

1.  Move the certificates into the `nginx.example.com` directory:

    {{< text bash >}}
    $ mkdir ~+1/nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/nginx.example.com
    {{< /text >}}

1.  Return to the root directory:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Deploy an NGINX server

1. Create a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's
   certificate.

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
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
      subject: C=US,ST=Denial,L=Springfield,O=Dis,CN=nginx.example.com
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: C=US,ST=Denial,O=Dis,CN=nginx.example.com

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

1.  Define a `Gateway` with a `server` section for port 443. Note the `PASSTHROUGH` `tls` `mode` which instructs
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
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports)
    to define the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables.

1.  Access the NGINX service from outside the cluster. Note that the correct certificate is returned by the server and
    it is successfully verified (_SSL certificate verify ok_ is printed).

    {{< text bash >}}
    $ curl -v --resolve nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert nginx.example.com/2_intermediate/certs/ca-chain.cert.pem https://nginx.example.com:$SECURE_INGRESS_PORT
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=nginx.example.com
      start date: Aug 15 07:29:07 2018 GMT
      expire date: Aug 25 07:29:07 2019 GMT
      common name: nginx.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=nginx.example.com
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

1.  Delete the directory containing the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm -f ./nginx.conf
    {{< /text >}}
