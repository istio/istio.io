---
title: Egress Gateways with TLS Origination (File Mount)
description: Describes how to configure an Egress Gateway to perform TLS origination to external services using file mount certificates.
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/egress-gateway-tls-origination/
owner: istio/wg-networking-maintainers
test: yes
---

The [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/)
example shows how to configure Istio to perform {{< gloss >}}TLS origination{{< /gloss >}}
for traffic to an external service. The [Configure an Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/)
example shows how to configure Istio to direct egress traffic through a
dedicated _egress gateway_ service. This example combines the previous two by
describing how to configure an egress gateway to perform TLS origination for
traffic to external services.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample
    which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), do

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from would do.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
    If you used the [sleep]({{< github_tree >}}/samples/sleep) sample, run:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

*   For macOS users, verify that you are using `openssl` version 1.1 or later:

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g  21 Apr 2020
    {{< /text >}}

    If the previous command outputs a version `1.1` or later, as shown, your `openssl` command
    should work correctly with the instructions in this task. Otherwise, upgrade your `openssl` or try
    a different implementation of `openssl`, for example on a Linux machine.

*   [Deploy Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

*   [Enable Envoy’s access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## Perform TLS origination with an egress gateway

This section describes how to perform the same TLS origination as in the
[TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/) example,
only this time using an egress gateway. Note that in this case the TLS origination will
be done by the egress gateway, as opposed to by the sidecar in the previous example.

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly by sending a request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...
    {{< /text >}}

    Your `ServiceEntry` was configured correctly if you see _301 Moved Permanently_ in the output.

1.  Create an egress `Gateway` for _edition.cnn.com_, port 80, and a destination rule for
    sidecar requests that will be directed to the egress gateway.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 80
          name: https-port-for-tls-origination
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: ISTIO_MUTUAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 80
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct the traffic through the egress gateway, and a `DestinationRule`
    to perform TLS origination for requests to `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 80
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 80
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
    EOF
    {{< /text >}}

1.  Send an HTTP request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    The output should be the same as in the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/)
    example, with TLS origination: without the _301 Moved Permanently_ message.

1.  Check the log of the `istio-egressgateway` pod and you should see a line corresponding to our request.
    If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain>}}
    [2020-06-30T16:17:56.763Z] "GET /politics HTTP/2" 200 - "-" "-" 0 1295938 529 89 "10.244.0.171" "curl/7.64.0" "cf76518d-3209-9ab7-a1d0-e6002728ef5b" "edition.cnn.com" "151.101.129.67:443" outbound|443||edition.cnn.com 10.244.0.170:54280 10.244.0.170:8080 10.244.0.171:35628 - -
    {{< /text >}}

### Cleanup the TLS origination example

Remove the Istio configuration items you created:

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## Perform mutual TLS origination with an egress gateway

Similar to the previous section, this section describes how to configure an egress gateway to perform
TLS origination for an external service, only this time using a service that requires mutual TLS.

This example is considerably more involved because you need to first:

1. generate client and server certificates
1. deploy an external service that supports the mutual TLS protocol
1. redeploy the egress gateway with the needed mutual TLS certs

Only then can you configure the external traffic to go through the egress gateway which will perform
TLS origination.

### Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1)

1.  Create a root certificate and private key to sign the certificate for your services:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Create a certificate and a private key for `my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

1.  Generate client certificate and private key:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### Deploy a mutual TLS server

To simulate an actual external service that supports the mutual TLS protocol,
deploy an [NGINX](https://www.nginx.com) server in your Kubernetes cluster, but running outside of
the Istio service mesh, i.e., in a namespace without Istio sidecar proxy injection enabled.

1.  Create a namespace to represent services outside the Istio mesh, namely `mesh-external`. Note that the sidecar proxy will
    not be automatically injected into the pods in this namespace since the automatic sidecar injection was not
    [enabled](/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) on it.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
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

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the NGINX server:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Deploy the NGINX server:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
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
      namespace: mesh-external
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
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

### Redeploy the egress gateway with the client certificates

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls nginx-client-certs --key client.example.com.key --cert client.example.com.crt
    $ kubectl create -n istio-system secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  To include a volume mounted from the new created secret, update the `istio-egressgateway` deployment.
    To patch the `istio-egressgateway` deployment, create the following `gateway-patch.json` file:

    {{< text bash >}}
    $ cat > gateway-patch.json <<EOF
    [{
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/0",
      "value": {
        "mountPath": "/etc/istio/nginx-client-certs",
        "name": "nginx-client-certs",
        "readOnly": true
      }
    },
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/0",
      "value": {
      "name": "nginx-client-certs",
        "secret": {
          "secretName": "nginx-client-certs",
          "optional": true
        }
      }
    },
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/1",
      "value": {
        "mountPath": "/etc/istio/nginx-ca-certs",
        "name": "nginx-ca-certs",
        "readOnly": true
      }
    },
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/1",
      "value": {
      "name": "nginx-ca-certs",
        "secret": {
          "secretName": "nginx-ca-certs",
          "optional": true
        }
      }
    }]
    EOF
    {{< /text >}}

1.  Apply `istio-egressgateway` deployment patch with the following command:

    {{< text bash >}}
    $ kubectl -n istio-system patch --type=json deploy istio-egressgateway -p "$(cat gateway-patch.json)"
    {{< /text >}}

1.  Verify that the key and the certificate are successfully loaded in the `istio-egressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -n istio-system "$(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}')" -- ls -al /etc/istio/nginx-client-certs /etc/istio/nginx-ca-certs
    {{< /text >}}

    `tls.crt` and `tls.key` should exist in `/etc/istio/nginx-client-certs`, while `ca-chain.cert.pem` in
    `/etc/istio/nginx-ca-certs`.

### Configure mutual TLS origination for egress traffic

1.  Create an egress `Gateway` for `my-nginx.mesh-external.svc.cluster.local`, port 443, and destination rules and
    virtual services to direct the traffic through the egress gateway and from the egress gateway to the external
    service.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        hosts:
        - my-nginx.mesh-external.svc.cluster.local
        tls:
          mode: ISTIO_MUTUAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-nginx
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: nginx
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: my-nginx.mesh-external.svc.cluster.local
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct the traffic through the egress gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-nginx-through-egress-gateway
    spec:
      hosts:
      - my-nginx.mesh-external.svc.cluster.local
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: nginx
            port:
              number: 443
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: my-nginx.mesh-external.svc.cluster.local
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Add a `DestinationRule` to perform mutual TLS origination

    {{< text bash >}}
    $ kubectl apply -n istio-system -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-mtls-for-nginx
    spec:
      host: my-nginx.mesh-external.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: MUTUAL
            clientCertificate: /etc/istio/nginx-client-certs/tls.crt
            privateKey: /etc/istio/nginx-client-certs/tls.key
            caCertificates: /etc/istio/nginx-ca-certs/example.com.crt
            sni: my-nginx.mesh-external.svc.cluster.local
    EOF
    {{< /text >}}

1.  Send an HTTP request to `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -s http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  Check the log of the `istio-egressgateway` pod for a line corresponding to our request.
    If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
    {{< /text >}}

### Cleanup the mutual TLS origination example

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret istio-egressgateway-certs istio-egressgateway-ca-certs -n istio-system
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete gateway istio-egressgateway
    $ kubectl delete virtualservice direct-nginx-through-egress-gateway
    $ kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
    $ kubectl delete destinationrule egressgateway-for-nginx
    {{< /text >}}

1.  Delete the certificates and private keys:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm ./nginx.conf
    $ rm ./gateway-patch.json
    {{< /text >}}

## Cleanup

Delete the `sleep` service and deployment:

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
