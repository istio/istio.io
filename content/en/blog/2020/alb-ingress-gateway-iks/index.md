---
title: Direct encrypted traffic from IBM Cloud Kubernetes Service Ingress to Istio Ingress Gateway
description: Configure the IBM Cloud Kubernetes Service Application Load Balancer to direct traffic to the Istio Ingress gateway with mutual TLS.
subtitle: Configure the IBM Cloud Kubernetes Service Application Load Balancer to direct traffic to the Istio Ingress gateway with mutual TLS
publishdate: 2020-05-15
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,ingress,file-mount-credentials,iks]
---

In this blog post I show how to configure the [Ingress Application Load Balancer (ALB)](https://cloud.ibm.com/docs/containers?topic=containers-ingress-about)
on [IBM Cloud Kubernetes Service (IKS)](https://www.ibm.com/cloud/kubernetes-service/) to direct traffic to the Istio
ingress gateway, while securing the traffic between them using {{< gloss  >}}mutual TLS authentication{{< /gloss >}}.

When you use IKS without Istio, you may control your ingress traffic using the provided ALB. This ingress-traffic
routing is configured using a Kubernetes
[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource with
[ALB-specific annotations](https://cloud.ibm.com/docs/containers?topic=containers-ingress_annotation). IKS provides a
DNS domain name, a TLS certificate that matches the domain, and a private key for the certificate. IKS stores the
certificates and the private key in a [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/).

When you start using Istio in your IKS cluster, the recommended method to send traffic to your Istio enabled workloads
is by using the [Istio Ingress Gateway](/docs/tasks/traffic-management/ingress/ingress-control/) instead of using the
[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). One of the main reasons to use
the Istio ingress gateway is the fact the ALB provided by IKS will not be able to communicate directly with the services
inside the mesh when you enable STRICT mutual TLS. During your transition to having only Istio ingress gateway as your
main entry point, you can continue to use the traditional Ingress for non-Istio services while using the Istio ingress
gateway for services that are part of the mesh.

IKS provides a convenient way for clients to access Istio ingress gateway by letting you
[register a new DNS subdomain](https://cloud.ibm.com/docs/containers?topic=containers-loadbalancer_hostname) for the
Istio gateway's IP with an IKS command. The domain is in the following
[format](https://cloud.ibm.com/docs/containers?topic=containers-loadbalancer_hostname#loadbalancer_hostname_format):
`<cluster_name>-<globally_unique_account_HASH>-0001.<region>.containers.appdomain.cloud`, for example `mycluster-a1b2cdef345678g9hi012j3kl4567890-0001.us-south.containers.appdomain.cloud`. In the same way as for the ALB domain,
IKS provides a certificate and a private key, storing them in another Kubernetes secret.

This blog describes how you can chain together the IKS Ingress ALB and the Istio ingress gateway to send traffic to your
Istio enabled workloads while being able to continue using the ALB specific features and the ALB subdomain name. You
configure the IKS Ingress ALB to direct traffic to the services inside an Istio service mesh through the Istio ingress
gateway, while using mutual TLS authentication between the ALB and the gateway. For the mutual TLS authentication, you
will configure the ALB and the Istio ingress gateway to use the certificates and keys provided by IKS for the ALB and
NLB subdomains. Using certificates provided by IKS saves you the overhead of managing your own certificates for the
connection between the ALB and the Istio ingress gateway.

You will use the NLB subdomain certificate as the server certificate for the Istio ingress gateway as intended.
The NLB subdomain certificate represents the identity of the server that serves a particular NLB subdomain, in this
case, the ingress gateway.

You will use the ALB subdomain certificate as the client certificate in mutual TLS authentication between the ALB and
the Istio Ingress. When ALB acts as a server it presents the ALB certificate to the clients so the clients can
authenticate the ALB. When ALB acts as a client of the Istio ingress gateway, it presents the same certificate to the
Istio ingress gateway, so the Istio ingress gateway could authenticate the ALB.

{{< warning >}}
Note that the instructions in this blog post only configure the ALB and the Istio ingress gateway to encrypt the traffic
between them and to verify that they receive valid certificates issued by [Let's Encrypt](https://letsencrypt.org). In
order to specify that only the ALB is allowed to talk to the Istio ingress gateway, an additional Istio security policy
must be defined. In order to verify that the ALB indeed talks to the Istio ingress gateway, additional configuration
must be added to the ALB. The additional configuration of the Istio ingress gateway and the ALB is out of scope for this
blog.
{{< /warning >}}

Traffic to the services without an Istio sidecar can continue to flow as before directly from the ALB.

The diagram below exemplifies the described setting. It shows two services in the cluster, `service A` and `service B`.
`service A` has an Istio sidecar injected and requires mutual TLS. `service B` has no Istio sidecar. `service B` can
be accessed by clients through the ALB, which directly communicates with `service B`. `service A` can be also
accessed by clients through the ALB, but in this case the traffic must pass through the Istio ingress gateway. Mutual
TLS authentication between the ALB and the gateway is based on the certificates provided by IKS.
The clients can also access the Istio ingress gateway directly. IKS registers different DNS domains for the ALB and for
the ingress gateway.

{{< image width="100%" link="./alb-ingress-gateway.svg" caption="A cluster with the ALB and the Istio ingress gateway" >}}

## Initial setting

1.  Create the `httptools` namespace and enable Istio sidecar injection:

    {{< text bash >}}
    $ kubectl create namespace httptools
    $ kubectl label namespace httptools istio-injection=enabled
    namespace/httptools created
    namespace/httptools labeled
    {{< /text >}}

1.  Deploy the `httpbin` sample to `httptools`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n httptools
    service/httpbin created
    deployment.apps/httpbin created
    {{< /text >}}

## Create secrets for the ALB and the Istio ingress gateway

IKS generates a TLS certificate and a private key and stores them as a secret in the default namespace when you register
a DNS domain for an external IP by using the `ibmcloud ks nlb-dns-create` command. IKS stores the ALB's
certificate and private key also as a secret in the default namespace. You need these credentials to establish the
identities that the ALB and the Istio ingress gateway will present during the mutual TLS authentication between
them. You will configure the ALB and the Istio ingress gateway to exchange these certificates, to trust the certificates
of one another, and to use their private keys to encrypt and sign the traffic.

1.  Store the name of your cluster in the `CLUSTER_NAME` environment variable:

    {{< text bash >}}
    $ export CLUSTER_NAME=<your cluster name>
    {{< /text >}}

1.  Store the domain name of your ALB in the `ALB_INGRESS_DOMAIN` environment variable:

    {{< text bash >}}
    $ ibmcloud ks cluster get --cluster $CLUSTER_NAME | grep Ingress
    Ingress Subdomain:              <your ALB ingress domain>
    Ingress Secret:                 <your ALB secret>
    {{< /text >}}

    {{< text bash >}}
    $ export ALB_INGRESS_DOMAIN=<your ALB ingress domain>
    $ export ALB_SECRET=<your ALB secret>
    {{< /text >}}

1.  Store the external IP of your `istio-ingressgateway` service in an environment variable.

    {{< text bash >}}
    $ export INGRESS_GATEWAY_IP=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo INGRESS_GATEWAY_IP = $INGRESS_GATEWAY_IP
    {{< /text >}}

1.  Create a DNS domain for the IP of the Istio Ingress Gateway service:

    {{< text bash >}}
    $ ibmcloud ks nlb-dns create classic --cluster $CLUSTER_NAME --ip $INGRESS_GATEWAY_IP
    Host name subdomain is created as <some domain>
    {{< /text >}}

1.  Store the domain name from the previous command in an environment variable:

    {{< text bash >}}
    $ export INGRESS_GATEWAY_DOMAIN=<the domain from the previous command>
    {{< /text >}}

1.  List the registered domain names:

    {{< text bash >}}
    $ ibmcloud ks nlb-dnss --cluster $CLUSTER_NAME
    Retrieving host names, certificates, IPs, and health check monitors for network load balancer (NLB) pods in cluster <your cluster>...
    OK
    Hostname                          IP(s)                       Health Monitor   SSL Cert Status   SSL Cert Secret Name
    <your ingress gateway hostname>   <your ingress gateway IP>   None             created           <the matching secret name>
    ...
    {{< /text >}}

    Wait until the status of the certificate (the fourth field) in the line that matches the IP of the Istio ingress
    gateway service becomes `enabled` (initially it is `pending`).

1.  Store the name of the secret that matches the IP of the Istio ingress gateway service:

    {{< text bash >}}
    $ export INGRESS_GATEWAY_SECRET=<the secret's name that appears as the last value in the line that matches the IP of the gateway>
    {{< /text >}}

1.  Extract the certificate and the key from the secret provided for the ingress gateway:

    {{< text bash >}}
    $ mkdir ingress_gateway_certs
    $ kubectl get secret $INGRESS_GATEWAY_SECRET --namespace=default -o yaml | grep 'tls.key:' | cut -f2 -d: | base64 --decode > ingress_gateway_certs/tls.key
    $ kubectl get secret $INGRESS_GATEWAY_SECRET --namespace=default -o yaml | grep 'tls.crt:' | cut -f2 -d: | base64 --decode > ingress_gateway_certs/tls.crt
    $ ls -al ingress_gateway_certs
    -rw-r--r--   1 user  staff  1679 Sep 11 07:55 tls.key
    -rw-r--r--   1 user  staff  3921 Sep 11 07:55 trusted.crt
    {{< /text >}}

1.  Extract the certificate and the key from the secret provided for the ALB:

    {{< text bash >}}
    $ mkdir alb_certs
    $ kubectl get secret $ALB_SECRET --namespace=default -o yaml | grep 'tls.key:' | cut -f2 -d: | base64 --decode > alb_certs/client.key
    $ kubectl get secret $ALB_SECRET --namespace=default -o yaml | grep 'tls.crt:' | cut -f2 -d: | base64 --decode > alb_certs/client.crt
    $ ls -al alb_certs
    -rw-r--r--   1 user  staff  3738 Sep 11 07:57 client.crt
    -rw-r--r--   1 user  staff  1675 Sep 11 07:57 client.key
    {{< /text >}}

1.  Download the issuer certificate of the [Let's Encrypt](https://letsencrypt.org) certificate, which is the
    issuer of the certificates provided by IKS. You specify this certificate as the certificate of a certificate
    authority to trust, for both the ALB and the Istio ingress gateway.

    {{< text bash >}}
    $ curl https://letsencrypt.org/certs/trustid-x3-root.pem --output trustid-x3-root.pem
    {{< /text >}}

1.  Append the issuer certificate of [Let's Encrypt](https://letsencrypt.org) to the certificate of ingress gateway
    (currently required for the ALB):

    {{< text bash >}}
    $ cat ingress_gateway_certs/tls.crt trustid-x3-root.pem > trusted.crt
    {{< /text >}}

1.  Create Kubernetes secrets to be used by Istio ingress gateway and the ALB to establish mutual TLS between them. Note
    that the name of the secrets for the Istio ingress gateway must be exactly as in the commands.

    {{< warning >}}
    The certificates provided by IKS expire every 90 days and are automatically renewed by
    IKS 37 days before they expire.
    You will have to recreate the secrets by rerunning the instructions of this section every time the secrets provided
    by IKS are updated. You may want to use scripts or operators to automate this and keep the
    secrets in sync.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key ingress_gateway_certs/tls.key --cert trusted.crt
    $ kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=trustid-x3-root.pem
    $ kubectl create secret generic alb-certs -n istio-system --from-file=trusted.crt --from-file=alb_certs/client.crt --from-file=alb_certs/client.key
    secret "istio-ingressgateway-certs" created
    secret "istio-ingressgateway-ca-certs" created
    secret "alb-certs" created
    {{< /text >}}

## Configure a mutual TLS ingress gateway

In this section you configure the Istio ingress gateway to perform mutual TLS between external clients and the gateway.
You use the certificates and the keys provided to you for the ingress gateway and the ALB.

1.  Define a `Gateway` to allow access on port 443 only, with mutual TLS:

    {{< text bash >}}
    $ kubectl apply -n httptools -f - <<EOF
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

1. Configure routes for traffic entering via the `Gateway`:

    {{< text bash >}}
    $ kubectl apply -n httptools -f - <<EOF
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
    EOF
    {{< /text >}}

1.  Delete the Istio Ingress Gateway's pod to reload the certificates:

    {{< text bash >}}
    $ kubectl delete pod -l istio=ingressgateway -n istio-system
    {{< /text >}}

1.  Send a request to `httpbin` by _curl_, passing as parameters the client certificate
    (the `--cert` option) and the private key (the `--key` option):

    {{< text bash >}}
    $ curl https://$INGRESS_GATEWAY_DOMAIN/status/418 --cert alb_certs/client.crt  --key alb_certs/client.key

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  Remove the directories with the ALB and ingress gateway certificates and keys.

    {{< text bash >}}
    $ rm -r ingress_gateway_certs alb_certs trustid-x3-root.pem trusted.crt
    {{< /text >}}

## Configure the ALB

You need to configure your Ingress resource to direct traffic to the Istio ingress gateway while using the certificate
stored in the `alb-certs` secret. Normally, the ALB decrypts HTTPS requests before forwarding traffic to your apps.
You can configure the ALB to re-encrypt the traffic before it is forwarded to the Istio ingress gateway by using the
`ssl-services` annotation on the Ingress resource. This annotation also allows you to specify the certificate stored in
the `alb-certs` secret, required for mutual TLS.

1.  Configure the `Ingress` resource for the ALB. You must create the `Ingress` resource in the `istio-system` namespace
    in order to forward the traffic to the Istio ingress gateway.

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

Congratulations! You configured the IKS Ingress ALB to send encrypted traffic to the Istio ingress gateway. You
allocated a host name and certificate for your Istio ingress gateway and used that certificate as the server certificate
for Istio ingress gateway. As the client certificate of the ALB you used the certificate provided by IKS for the ALB.
Once you had the certificates deployed as Kubernetes secrets, you directed the ingress traffic from the ALB to the Istio
ingress gateway for some specific paths and used the certificates for mutual TLS authentication between the ALB and the
Istio ingress gateway.

## Cleanup

1.  Delete the `Gateway` configuration, the `VirtualService`, and the secrets:

    {{< text bash >}}
    $ kubectl delete ingress alb-ingress -n istio-system
    $ kubectl delete virtualservice default-ingress -n httptools
    $ kubectl delete gateway default-ingress-gateway -n httptools
    $ kubectl delete policy default -n httptools --ignore-not-found=true
    $ kubectl delete destinationrule default -n httptools
    $ kubectl delete secrets istio-ingressgateway-certs istio-ingressgateway-ca-certs alb-certs -n istio-system
    $ rm -rf ingress_gateway_certs alb_certs trustid-x3-root.pem trusted.crt
    $ unset CLUSTER_NAME ALB_INGRESS_DOMAIN ALB_SECRET INGRESS_GATEWAY_DOMAIN INGRESS_GATEWAY_SECRET
    {{< /text >}}

1.  Shutdown the `httpbin` service:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@ -n httptools
    {{< /text >}}

1.  Delete the `httptools` namespace:

    {{< text bash >}}
    $ kubectl delete namespace httptools
    {{< /text >}}
