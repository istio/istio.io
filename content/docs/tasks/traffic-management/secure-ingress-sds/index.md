---
title: Securing Gateways with SDS
description: Describes how to configure Istio to expose a service outside of the service mesh, over TLS or Mutual TLS, using SDS.
weight: 31
keywords: [traffic-management,ingress,sds]
---

The [Securing Gateways with HTTPS](/docs/tasks/traffic-management/secure-ingress) task describes how to configure an ingress
gateway to expose an HTTP endpoint of a service to external traffic with either simple or mutual TLS.
This task shows you how to do the same, but using an ingress gateway agent to provision key/cert and root cert to ingress gateway dynamically.

{{< boilerplate before-you-begin-ingress >}}

## Configure a TLS ingress gateway with secret discovery service enabled

In this section you will configure a TLS ingress gateway that fetches credentials from the ingress gateway agent via secret discovery service (SDS).
The ingress gateway agent is running in the same pod as the ingress gateway, and watches credentials created in the same namespace as the ingress gateway.
Enabling SDS at ingress gateway brings the following benefits.

* The ingress gateway is able to dynamically add/delete/update ingress gateway key/certificate and root certificate. You do not have to restart the ingress gateway.

* The secret volume mount is no longer needed. Once you create a `kubernetes` secret, that secret is captured by the gateway agent and sent to ingress gateway as key/certificate or root certificate.

* The gateway agent is able to watch multiple key/certificate pairs. You only need to create secrets for multiple hosts and update the gateway definitions.

1.  Enable SDS at ingress gateway and deploy the ingress gateway agent.
    This feature is disabled by default, you need to enable the feature flag [`istio-ingressgateway.sds.enabled`]({{<github_blob>}}/install/kubernetes/helm/subcharts/gateways/values.yaml) in helm,
    and then generate the `istio-ingressgateway.yaml` file:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio --namespace istio-system -x charts/gateways/templates/deployment.yaml \
    --set gateways.istio-egressgateway.enabled=false --set gateways.istio-ingressgateway.sds.enabled=true > $HOME/istio-ingressgateway.yaml
    $ kubectl apply -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1.  Set the environment variables `INGRESS_HOST` and `SECURE_INGRESS_PORT`

    {{< text bash >}}
    $ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

1.  Start the `httpbin` sample

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - name: http
        port: 8000
      selector:
        app: httpbin
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: httpbin
            version: v1
        spec:
          containers:
          - image: docker.io/citizenstig/httpbin
            imagePullPolicy: IfNotPresent
            name: httpbin
            ports:
            - containerPort: 8000
    EOF
    {{< /text >}}

1.  Create a secret for ingress gateway

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic httpbin-credential --from-file=key=httpbin.example.com/3_application/private/httpbin.example.com.key.pem --from-file=cert=httpbin.example.com/3_application/certs/httpbin.example.com.cert.pem
    {{< /text >}}

1.  Define a Gateway with a server section for port 443, and specify `credentialName` to be `httpbin-credential`, which should be the same as the secret name.
    TLS mode should be specified as SIMPLE. `serverCertificate` and `privateKey` should not be empty.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
          mode: SIMPLE
          serverCertificate: "use sds"         # arbitrary non-empty string
          privateKey: "use sds"                # arbitrary non-empty string
          credentialName: "httpbin-credential" # must be the same as secret
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the Gateway. Define the same `VirtualService`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "httpbin.example.com"
      gateways:
      - mygateway
      http:
      - match:
        - uri:
            prefix: /status
        - uri:
            prefix: /delay
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

1.  Access the `httpbin` service with HTTPS by sending an https request

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    {{< /text >}}

    The `httpbin` service will return the [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

1.  Replace the credentials for the ingress gateway. You can change the credentials at ingress gateway by deleting the secret and creating a new one.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    {{< /text >}}

    {{< text bash >}}
    $ pushd mtls-go-example
    $ ./generate.sh httpbin.example.com <password>
    $ mkdir ~+1/httpbin.new.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/httpbin.new.example.com
    $ popd
    $ kubectl create -n istio-system secret generic httpbin-credential --from-file=key=httpbin.new.example.com/3_application/private/httpbin.example.com.key.pem --from-file=cert=httpbin.new.example.com/3_application/certs/httpbin.example.com.cert.pem
    {{< /text >}}

1.  Access the `httpbin` service using _curl_

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.new.example.com.b/2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    HTTP/2 418
    ...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Accessing `httpbin` with previous cert chain will now fail

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * SSL certificate problem: unable to get local issuer certificate
    {{< /text >}}

## Configure a TLS ingress gateway with secret discovery service enabled for multiple hosts

In this section you will configure an ingress gateway for multiple hosts, `httpbin.example.com` and `helloworld-v1.example.com`. The ingress gateway will retrieve unique credentials corresponding to specific `credentialName`.

1.  Start the `helloworld-v1` sample

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld-v1
      labels:
        app: helloworld-v1
    spec:
      ports:
      - name: http
        port: 8000
      selector:
        app: helloworld-v1
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld-v1
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v1
            resources:
              requests:
                cpu: "100m"
            imagePullPolicy: IfNotPresent #Always
            ports:
            - containerPort: 5000
    EOF
    {{< /text >}}

1.  Create a secret for the ingress gateway. Assuming you've already created the `httpbin-credential` secret, now create the `helloworld-credential` secret.

    {{< text bash >}}
    $ pushd mtls-go-example
    $ ./generate.sh helloworld-v1.example.com <password>
    $ mkdir ~+1/helloworld-v1.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/helloworld-v1.example.com
    $ popd
    $ kubectl create -n istio-system secret generic helloworld-credential --from-file=key=helloworld-v1.example.com/3_application/private/helloworld-v1.example.com.key.pem --from-file=cert=helloworld-v1.example.com/3_application/certs/helloworld-v1.example.com.cert.pem
    {{< /text >}}

1.  Define a Gateway with two server sections for port 443, and specify `credentialName` to be `httpbin-credential` and `helloworld-credential` respectively.
    TLS mode should be specified as SIMPLE. `serverCertificate` and `privateKey` should not be empty.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
          name: https-httpbin
          protocol: HTTPS
        tls:
          mode: SIMPLE
          serverCertificate: "use sds"
          privateKey: "use sds"
          credentialName: "httpbin-credential"
        hosts:
        - "httpbin.example.com"
      - port:
          number: 443
          name: https-helloworld
          protocol: HTTPS
        tls:
          mode: SIMPLE
          serverCertificate: "use sds"
          privateKey: "use sds"
          credentialName: "helloworld-credential"
        hosts:
        - "helloworld-v1.example.com"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the Gateway. Define the same `VirtualService`

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: helloworld-v1
    spec:
      hosts:
      - "helloworld-v1.example.com"
      gateways:
      - mygateway
      http:
      - match:
        - uri:
            exact: /hello
        route:
        - destination:
            host: helloworld-v1
            port:
              number: 5000
    EOF
    {{< /text >}}

1. Send an HTTPS request to `helloworld-v1.example.com`

    {{< text bash >}}
    $ curl -v -HHost:helloworld-v1.example.com --resolve helloworld-v1.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert helloworld-v1.example.com/2_intermediate/certs/ca-chain.cert.pem https://helloworld-v1.example.com:$SECURE_INGRESS_PORT/hello
    HTTP/2 200
    {{< /text >}}

1. Send HTTPS request to `httpbin.example.com` still returns teapot

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

## Configure a mutual TLS ingress gateway with secret discovery service enabled

In this section you will extend your gateway's definition to support [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication).
We can change the credentials at ingress gateway by deleting the secret and creating a new one.
This time we need to pass the CA certificate that the server will use to verify its clients, and we must use the name `cacert` to hold the CA certificate.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential  \
    --from-file=key=httpbin.example.com/3_application/private/httpbin.example.com.key.pem \
    --from-file=cert=httpbin.example.com/3_application/certs/httpbin.example.com.cert.pem \
    --from-file=cacert=httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1. Redefine Gateway and change the TLS mode to MUTUAL

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
         mode: MUTUAL
         serverCertificate: "use sds"         # arbitrary non-empty string
         privateKey: "use sds"                # arbitrary non-empty string
         caCertificates: "use sds"            # arbitrary non-empty string
         credentialName: "httpbin-credential" # must be the same as secret
       hosts:
       - "httpbin.example.com"
    EOF
    {{< /text >}}

1. Sending an HTTPS request using the prior approach now fails

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    * TLSv1.2 (OUT), TLS header, Certificate Status (22):
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (IN), TLS handshake, Server key exchange (12):
    * TLSv1.2 (IN), TLS handshake, Request CERT (13):
    * TLSv1.2 (IN), TLS handshake, Server finished (14):
    * TLSv1.2 (OUT), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
    * TLSv1.2 (OUT), TLS change cipher, Client hello (1):
    * TLSv1.2 (OUT), TLS handshake, Finished (20):
    * TLSv1.2 (IN), TLS alert, Server hello (2):
    * error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
    {{< /text >}}

1. Resend the previous request by passing a client certificate and private key to _curl_. This time pass your client certificate (additional --cert option) and your private key (the --key option) to _curl_.

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem --cert httpbin.example.com/4_client/certs/httpbin.example.com.cert.pem --key httpbin.example.com/4_client/private/httpbin.example.com.key.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/

    {{< /text >}}

## Troubleshooting

1.  Inspect the values of the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment variables. Make sure
they have valid values, according to the output of the following commands:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

1.  Verify that the secrets are successfully created in the `istio-system` namespace:

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` and `helloworld-credential` should show in the secrets list.

1.  Verify that the ingress gateway agent has pushed key/certificate to the ingress gateway by checking logs.

    {{< text bash >}}
    $ kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c ingress-sds
    {{< /text >}}

    It should show that secret `httpbin-credential` is added. If using mutual TLS, then secret `httpbin-credential-cacert` is added as well.
    It should also show that the gateway agent receives SDS request from the ingress gateway and the resource name is `httpbin-credential`, and pushes key/certificate to the ingress gateway.
    If using mutual TLS, then it should show that the gateway agent receives SDS request with resource name `httpbin-credential-cacert`, and pushes root certificate to the ingress gateway.

1.  Check `istio-ingressgateway`'s log for error messages:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=ingressgateway -c istio-proxy
    {{< /text >}}

1.  For macOS users, verify that you use _curl_ compiled with the [LibreSSL](http://www.libressl.org) library, as
    described in the [Before you begin](#before-you-begin) section.

## Cleanup

1.  Delete the `Gateway` configuration, the `VirtualService`, and the secrets:

    {{< text bash >}}
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret httpbin-credential helloworld-credential
    $ kubectl delete --ignore-not-found=true virtualservice helloworld-v1
    {{< /text >}}

1.  Delete the directories of the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf httpbin.example.com helloworld-v1.example.com mtls-go-example
    {{< /text >}}

1.  Remove the file you used for redeployment of `istio-ingressgateway`:

    {{< text bash >}}
    $ rm -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1.  Shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

    {{< text bash >}}
    $ kubectl delete service --ignore-not-found=true httpbin
    $ kubectl delete service --ignore-not-found=true helloworld-v1
    {{< /text >}}
