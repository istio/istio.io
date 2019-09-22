---
title: Integrate Istio with IBM Cloud Kubernetes Service ALB and NLB
description: Use NLB to handle DNS for an Istio ingress gateway. Direct traffic from ALB to an Istio ingress gateway in a secure way.
weight: 43
keywords: [traffic-management,ingress,file-mount-credentials]
---

This example shows how you can use [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/kubernetes-service/)
[ALB](https://cloud.ibm.com/docs/containers?topic=containers-ingress-about) and
[NLB](https://cloud.ibm.com/docs/containers?topic=containers-loadbalancer-about) with Istio.

When you use IBM Cloud Kubernetes Service without Istio, you may control your ingress traffic using ALB. You
configure the ingress-traffic routing using a Kubernetes
[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource with
[ALB-specific annotations](https://cloud.ibm.com/docs/containers?topic=containers-ingress_annotation).

When you start using Istio on IBM Cloud Kubernetes service, you may want to switch to using
the [Istio ingress gateway](/docs/tasks/traffic-management/ingress/ingress-control/) for controlling ingress traffic.
Moreover, when you require Istio {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between the services,
your ALB will not be able to talk to the services inside the mesh, since ALB lacks an Istio
{{< gloss >}}identity{{< /gloss >}}. In such a case you have no other option but to use the Istio ingress gateway.

You still have an option to use ALB with Istio. To do it, direct the incoming traffic to the Istio ingress gateway and
let Istio ingress gateway handle further routing and {{< gloss >}}TLS origination{{< /gloss >}} to the services in the mesh.

This example shows how you can configure ALB to direct traffic to the services inside an Istio service mesh through the
Istio ingress gateway, while using {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between ALB and the
gateway. The traffic to the services without Istio sidecar can continue to flow as before, directly from ALB.

## Before you begin

1.  Use [the managed Istio add-on](https://cloud.ibm.com/docs/containers?topic=containers-istio#istio_tutorial) or
    [Install Istio](https://istio.io/docs/setup/kubernetes/) to your IBM Cloud Kubernetes cluster

1.  Perform the steps in the [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control#determining-the-ingress-ip-and-ports) section, while verifying that you have an external load balancer for the
    `istio-ingressgateway` service.

1.  For macOS users, verify that you use _curl_ compiled with the [LibreSSL](http://www.libressl.org) library:

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    If a version of _LibreSSL_ is printed as in the output above, your _curl_ should work correctly with the
    instructions in this task. Otherwise, try another installation of _curl_, for example on a Linux machine.

##  Initial setting

1.  Create two namespaces for this example, `httptools` and `bookinfo`:

    {{< text bash >}}
    $ kubectl create namespace httptools
    $ kubectl create namespace bookinfo
    namespace/httptools created
    namespace/bookinfo created
    {{< /text >}}

1.  Deploy the `httpbin` sample to `httptools`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n httptools
    service/httpbin created
    deployment.apps/httpbin created
    {{< /text >}}

1.  Deploy the ratings service from [the Bookinfo sample application](/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -l app!=ratings,app!=reviews,app!=details,app!=productpage -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -n bookinfo
    $ kubectl apply -l app=ratings -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -n bookinfo
    serviceaccount/bookinfo-details created
    serviceaccount/bookinfo-ratings created
    serviceaccount/bookinfo-reviews created
    serviceaccount/bookinfo-productpage created
    service/ratings created
    deployment.apps/ratings-v1 created
    {{< /text >}}

1.  Check the deployed pods. Note that since you did not label the namespaces for Istio injection, Istio sidecars were
    not injected.

    {{< text bash >}}
    $ kubectl get pod -l app=httpbin -n httptools
    NAME                       READY   STATUS    RESTARTS   AGE
    httpbin-58d975cf88-fjt6h   1/1     Running   0          3m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pod -l app=ratings -n bookinfo
    NAME                          READY   STATUS    RESTARTS   AGE
    ratings-v1-5684b58ddd-26xmc   1/1     Running   0          9s
    {{< /text >}}

## Configure ALB ingress for your services

1.  Store the name of your cluster in the `CLUSTER_NAME` environment variable:

    {{< text bash >}}
    $ export CLUSTER_NAME=<your cluster name>
    {{< /text >}}

    You can print your clusters by the following command:

    {{< text bash >}}
    $ kubectl config get-clusters
    {{< /text >}}

1.  Store the domain name of your cluster in the `ALB_INGRESS_DOMAIN` environment variable:

    {{< text bash >}}
    $ ibmcloud ks cluster get --cluster $CLUSTER_NAME | grep Ingress
    Ingress Subdomain:              <your ALB ingress domain>   
    Ingress Secret:                 <your ALB secret>
    {{< /text >}}

    {{< text bash >}}
    $ export ALB_INGRESS_DOMAIN=<your ALB ingress domain>
    $ export ALB_SECRET=<your ALB secret>
    {{< /text >}}

1.  Configure an Ingress resource for the `httptools` namespace:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: alb-ingress
      namespace: httptools
      annotations:
        ingress.bluemix.net/redirect-to-https: "True"
    spec:
      tls:
      - hosts:
        - httptools.$ALB_INGRESS_DOMAIN
        secretName: $ALB_SECRET
      rules:
      - host: httptools.$ALB_INGRESS_DOMAIN
        http:
          paths:
          - path: /status
            backend:
              serviceName: httpbin
              servicePort: 8000
    EOF
    {{< /text >}}

1.  Test the ALB ingress for `httpbin`:

    {{< text bash >}}
    $ curl https://httptools.$ALB_INGRESS_DOMAIN/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Configure an Ingress resource for the `bookinfo` namespace:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: alb-ingress
      namespace: bookinfo
      annotations:
        ingress.bluemix.net/redirect-to-https: "True"
    spec:
      tls:
      - hosts:
        - bookinfo.$ALB_INGRESS_DOMAIN
        secretName: $ALB_SECRET
      rules:
      - host: bookinfo.$ALB_INGRESS_DOMAIN
        http:
          paths:
          - path: /ratings
            backend:
              serviceName: ratings
              servicePort: 9080
    EOF
    {{< /text >}}

1.  Test the ALB ingress for `ratings`:

    {{< text bash >}}
    $ curl https://bookinfo.$ALB_INGRESS_DOMAIN/ratings/0
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

## Apply sidecar injection to the `httptools` namespace

1.  Label the `httptools` namespace for injection:

    {{< text bash >}}
    $ kubectl label --context=$CTX_CLUSTER2 namespace httptools istio-injection=enabled
    namespace/httptools labeled
    {{< /text >}}

1.  Restart the `httpbin` pod:

    {{< text bash >}}
    $ kubectl delete pod -l app=httpbin -n httptools
    {{< /text >}}

1.  Verify that the pod of `httpbin` has two containers now:

    {{< text bash >}}
    $ kubectl get pod -l app=httpbin -n httptools
    NAME                       READY   STATUS    RESTARTS   AGE
    httpbin-58d975cf88-tg27w   2/2     Running   0          13s
    {{< /text >}}

1.  Require {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} for the traffic to the services in
    `httptools`:

    {{< text bash >}}
    $ kubectl apply -n httptools -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: default
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

    Add a corresponding destination rule:

    {{< text bash >}}
    $ kubectl apply -n httptools -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: default
    spec:
      host: "*.httptools.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

1.  Disable TLS for the traffic to the services in the `bookinfo` namespace:

    {{< text bash >}}
    $ kubectl apply -n bookinfo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: default
    spec:
      host: "*.bookinfo.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Check the ALB ingress for `httpbin`:

    {{< text bash >}}
    $ curl https://httptools.$ALB_INGRESS_DOMAIN/status/418
    <html>
    <head><title>502 Bad Gateway</title></head>
    <body>
    <center><h1>502 Bad Gateway</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    {{< /text >}}

    You get the error since the `httpbin` service requires
    {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} with an Istio indentity, which the ALB lacks.
    At this point you have two options:
    1. Allow [permissive mode](/docs/tasks/security/authz-permissive/) for the traffic to `httpbin` service,
    so ALB will communicate with the service by sending non-encrypted traffic.
    1. Direct the traffic to the `httpbin` service through an Istio ingress gateway. An Istio ingress gateway has an
    Istio identity and is able to communicate with the service using
    {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}}. You configure ALB and the Istio
    ingress gateway to setup {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between them, so all
    the traffic is encrypted.

    If the first option is not valid for you since you want all the traffic to be encrypted end-to-end, you must direct
    the traffic from ALB through an Istio ingress gateway, with
    {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between them.

## Expose your services with NLB and Istio ingress gateway, for HTTP (non-encrypted) traffic

1.  Create a DNS host name to register the IP of the Istio Ingress Gateway service

    {{< text bash >}}
    $ ibmcloud ks nlb-dns-create --cluster $CLUSTER_NAME --ip $INGRESS_HOST
    Host name subdomain is created as <some NLB domain>
    {{< /text >}}

1.  Store the domain name from the previous command in an environment variable:

    {{< text bash >}}
    $ export NLB_INGRESS_DOMAIN=<the domain from the previous command>
    {{< /text >}}

    You can list the NLB domain names matching your Ingress Gateway's IP, any time by the following command:

    {{< text bash >}}
    $ ibmcloud ks nlb-dnss --cluster $CLUSTER_NAME | grep enabled | grep $INGRESS_HOST
    {{< /text >}}

1.  Create an Istio `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: default-ingress-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "*"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: default-ingress
    spec:
      hosts:
      - "*"
      gateways:
      - default-ingress-gateway
      http:
      - match:
        - uri:
            prefix: /status
        route:
        - destination:
            port:
              number: 8000
            host: httpbin.httptools.svc.cluster.local
      - match:
        - uri:
            prefix: /ratings
        route:
        - destination:
            port:
              number: 9080
            host: ratings.bookinfo.svc.cluster.local
    EOF
    {{< /text >}}

1.  Test the Istio ingress gateway with NLB for `httpbin`, HTTP traffic:

    {{< text bash >}}
    $ curl http://$NLB_INGRESS_DOMAIN/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Test the Istio ingress gateway with NLB for `ratings`, HTTP traffic:

    {{< text bash >}}
    $ curl http://$NLB_INGRESS_DOMAIN/ratings/0
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

## Create secrets for {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between ALB and Istio ingress gateway

In this section you create secrets to mount certificates and private keys into ALB and Istio ingress gateway pods. You
extract the certificates and private keys from the secrets that are provided by IBM Cloud Kubernetes Service.

1.  Learn the name of the secret provided for the NLB. Check the secret name that matches your $INGRESS_HOST IP address:

    {{< text bash >}}
    $ ibmcloud ks nlb-dnss --cluster $CLUSTER_NAME | grep enabled | grep $INGRESS_HOST
    {{< /text >}}

    The value in the last column is the name of the secret.

1.  Store the name of the secret in an environment variable:

    {{< text bash >}}
    $ export NLB_SECRET=<your NLB secret's name which appears as the last value in the output of the previous command>
    {{< /text >}}

1.  Extract the certificate and the key from the secret provided for NLB:

    {{< text bash >}}
    $ mkdir nlb_certs
    $ kubectl get secret $NLB_SECRET --namespace=default -o yaml | grep 'tls.key:' | cut -f2 -d: | base64 --decode > nlb_certs/tls.key
    $ kubectl get secret $NLB_SECRET --namespace=default -o yaml | grep 'tls.crt:' | cut -f2 -d: | base64 --decode > nlb_certs/tls.crt
    $ ls -al nlb_certs
    -rw-r--r--   1 user  staff  1679 Sep 11 07:55 tls.key
    -rw-r--r--   1 user  staff  3921 Sep 11 07:55 trusted.crt
    {{< /text >}}

1.  Extract the certificate and the key from the secret provided for ALB:

    {{< text bash >}}
    $ mkdir alb_certs
    $ kubectl get secret $ALB_SECRET --namespace=default -o yaml | grep 'tls.key:' | cut -f2 -d: | base64 --decode > alb_certs/client.key
    $ kubectl get secret $ALB_SECRET --namespace=default -o yaml | grep 'tls.crt:' | cut -f2 -d: | base64 --decode > alb_certs/client.crt
    $ ls -al alb_certs
    -rw-r--r--   1 user  staff  3738 Sep 11 07:57 client.crt
    -rw-r--r--   1 user  staff  1675 Sep 11 07:57 client.key
    {{< /text >}}

1.  Download the issuer certificate of the [Let's Encrypt](https://letsencrypt.org) certificate, which is the
    issuer of the certificates provided by IBM Cloud Kubernetes Service.

    {{< text bash >}}
    $ curl https://letsencrypt.org/certs/trustid-x3-root.pem --output trustid-x3-root.pem
    {{< /text >}}

1.  Append the issuer certificate of [Let's Encrypt](https://letsencrypt.org) to the certificate of NLB
    (currently required for ALB):

    {{< text bash >}}
    $ cat nlb_certs/tls.crt trustid-x3-root.pem > trusted.crt
    {{< /text >}}

1.  Create Kubernetes secrets to be used by Istio ingress gateway and ALB to establish
    {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between them. Note
    that the name of the secrets for the Istio ingress gateway must be exactly as in the commands.

    {{< warning >}}
    The certificates provided by IBM Cloud Kubernetes Service expire every 90 days and are automatically renewed by
    IBM Cloud Kubernetes Service 37 days before they expire.
    You will have to recreate the secrets by rerunning the instructions of this section every time the secrets provided
    by IBM Cloud Kubernetes Service are updated. You may want to use scripts or operators to automate this and keep the
    secrets in sync.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key nlb_certs/tls.key --cert trusted.crt
    $ kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=trustid-x3-root.pem
    $ kubectl create secret generic alb-certs -n istio-system --from-file=trusted.crt --from-file=alb_certs/client.crt --from-file=alb_certs/client.key
    secret "istio-ingressgateway-certs" created
    secret "istio-ingressgateway-ca-certs" created
    secret "alb-certs" created
    {{< /text >}}

## Configure a {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} ingress gateway

In this section you configure the Istio ingress gateway to perform
{{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}} between external clients and the gateway.
You use the certificates and the keys provided to you for the NLB and ALB.

1.  Redefine your previous `Gateway` to allow access on port 443 only, with
    {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}}:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: default-ingress-gateway
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
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          caCertificates: /etc/istio/ingressgateway-ca-certs/trustid-x3-root.pem
        hosts:
        - "*"
    EOF
    {{< /text >}}

1.  Delete the Istio Ingress Gateway's pod to reload the certificates:

    {{< text bash >}}
    $ kubectl delete pod -l istio=ingressgateway -n istio-system
    {{< /text >}}

1.  Send a request to `httpbin` by _curl_, this time passing as parameters the client certificate (additional `--cert` option)
 and the private key (the `--key` option):

    {{< text bash >}}
    $ curl https://$NLB_INGRESS_DOMAIN/status/418 --cert alb_certs/client.crt  --key alb_certs/client.key

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Remove the directories with the ALB and NLB certificates and keys. You do not want the keys to be on your disk for a
    long time.

    {{< text bash >}}
    $ rm -r nlb_certs alb_certs trustid-x3-root.pem trusted.crt
    {{< /text >}}

## Configure the ALB ingress to direct traffic through the Istio ingress gateway, over {{< gloss "mutual TLS authentication" >}}mutual TLS{{< /gloss >}}

1.  Delete the previous version of the Ingress resource for `httpbin`:

    {{< text bash >}}
    $ kubectl delete ingress alb-ingress -n httptools
    {{< /text >}}

1.  Configure the Ingress resource for ALB. This time you create the Ingress resource in the `istio-system` namespace,
    since it will forward the traffic to the Istio ingress gateway in the `istio-system` namespace.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: alb-ingress
      namespace: istio-system
      annotations:
        ingress.bluemix.net/ssl-services: "ssl-service=istio-ingressgateway ssl-secret=alb-certs"
    spec:
      tls:
      - hosts:
        - httpbin.$ALB_INGRESS_DOMAIN
        secretName: $ALB_SECRET
      rules:
      - host: httpbin.$ALB_INGRESS_DOMAIN
        http:
          paths:
          - path: /status
            backend:
              serviceName: istio-ingressgateway
              servicePort: 443
    EOF
    {{< /text >}}

1.  Test the ALB ingress:

    {{< text bash >}}
    $ curl https://httpbin.$ALB_INGRESS_DOMAIN/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Verify that `ratings` is still accessible:

    {{< text bash >}}
    $ curl https://bookinfo.$ALB_INGRESS_DOMAIN/ratings/0
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

## Troubleshooting

Following the instructions in this section if some of the instructions above do not work for you.

*   Inspect the values of the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment
    variables. Make sure they have valid values, according to the output of the
    following commands:

    {{< text bash >}}
    $ kubectl get svc istio-ingressgateway -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

*   Verify that the key and the certificate are successfully loaded in the
    `istio-ingressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
    {{< /text >}}

    `tls.crt` and `tls.key` should exist in the directory contents.

*   If the key and the certificate are not loaded, delete the ingress gateway pod and force the
    ingress gateway pod to restart and reload key and certificate.

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio=ingressgateway
    {{< /text >}}

*   Verify that the DNS values of the Alternative Subject Name are correct in the certificate of the ingress gateway:

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-certs/tls.crt | openssl x509 -text -noout | grep 'Subject:'
    DNS: <DNS names>
    {{< /text >}}

    Verify that the value of `NLB_INGRESS_DOMAIN` environment variable is contained in the list of DNS names in the
    output of the previous command:

    {{< text bash >}}
    $ echo $NLB_INGRESS_DOMAIN
    {{< /text >}}

*   Verify that the CA certificate is loaded in the `istio-ingressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-ca-certs
    {{< /text >}}

    `trustid-x3-root.pem` should exist in the directory contents.

*   Verify that the `Subject` is correct in the CA certificate of the ingress gateway:

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-ca-certs/trustid-x3-root.pem | openssl x509 -text -noout | grep 'Subject:'
    Subject: O=Digital Signature Trust Co., CN=DST Root CA X3
    {{< /text >}}

*   Verify that the proxy of the ingress gateway is aware of the certificates:

    {{< text bash >}}
    $ kubectl exec -ti $(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -n istio-system -- curl  127.0.0.1:15000/certs | grep path | sort | uniq
     "path": "/etc/certs/cert-chain.pem",
     "path": "/etc/certs/root-cert.pem",
     "path": "/etc/istio/ingressgateway-ca-certs/trustid-x3-root.pem",
     "path": "/etc/istio/ingressgateway-certs/tls.crt",
    {{< /text >}}

*   Check the log of `istio-ingressgateway` for error messages:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=ingressgateway
    {{< /text >}}

*   For macOS users, verify that you use `curl` compiled with the [LibreSSL](http://www.libressl.org)
    library, as described in the [Before you begin](#before-you-begin) section.

*  The generated Nginx configuration for the ALB is in  /etc/nginx/conf.d/istio-system-alb-ingress.conf.

*  Check the ALB pods:

    {{< text bash >}}
    $ kubectl get pods -n kube-system | grep alb
    {{< /text >}}

*  Check the logs of Nginx:

    {{< text bash >}}
    $ kubectl logs <alb pod from the command above> -c nginx-ingress -n kube-system
    {{< /text >}}

## Cleanup

1.  Delete the `Gateway` configuration, the `VirtualService`, and the secrets:

    {{< text bash >}}
    $ kubectl delete ingress alb-ingress -n istio-system
    $ kubectl delete virtualservice default-ingress
    $ kubectl delete gateway default-ingress-gateway
    $ kubectl delete ingress alb-ingress -n bookinfo
    $ kubectl delete ingress alb-ingress -n httptools --ignore-not-found=true
    $ kubectl delete policy default -n httptools --ignore-not-found=true
    $ kubectl delete destinationrule default -n httptools
    $ kubectl delete destinationrule default -n bookinfo
    $ kubectl delete secrets istio-ingressgateway-certs istio-ingressgateway-ca-certs alb-certs -n istio-system
    $ rm -rf nlb_certs alb_certs trustid-x3-root.pem trusted.crt
    $ unset CLUSTER_NAME ALB_INGRESS_DOMAIN ALB_SECRET NLB_INGRESS_DOMAIN NLB_SECRET
    {{< /text >}}

1.  Shutdown the `httpbin` service:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@ -n httptools
    {{< /text >}}

1.  Shutdown the `ratings` service:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@ --ignore-not-found=true -n bookinfo
    {{< /text >}}

1.  Delete the namespaces:

    {{< text bash >}}
    $ kubectl delete namespace httptools
    $ kubectl delete namespace bookinfo
    {{< /text >}}
