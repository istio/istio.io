---
title: Configure Egress Gateway for HTTPS traffic to wildcarded domains
description: Use an SNI proxy in addition to the Envoy instance in the istio-egressgateway for wildcarded domains
keywords: [traffic-management,egress]
weight: 44
---

The [Configure Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task, the
[Direct HTTPS traffic through an egress gateway](/docs/tasks/traffic-management/egress-gateway/#direct-https-traffic-through-an-egress-gateway)
section described how to configure an Istio egress gateway for HTTPS traffic for specific hostnames, like
`edition.cnn.com`. This task explains how to enable an egress gateway for HTTPS traffic to a set of domains, for
example to `*.wikipedia.org`, without the need to specify each and every host.

## Background

Suppose we want to enable secure egress traffic control in Istio for the `wikipedia.org` sites in all the languages.
Each version of `wikipedia.org` in a particular language has its own hostname, e.g. `en.wikipedia.org` and
`de.wikipedia.org` in the English and the German languages, respectively. We want to enable the egress traffic by common
configuration items for all the _wikipedia_ sites, without the need to specify the sites in all the languages.

## Before you begin

This task assumes you deployed Istio with mutual [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/tasks/traffic-management/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway) task.

## Configure HTTPS traffic to _*.wikipedia.org_

1.  Define a `ServiceEntry` for `*.wikipedia.org`:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: tls
        protocol: TLS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Create an egress `Gateway` for _*.wikipedia.org_, port 443, protocol TLS, a destination rule to set the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) for the gateway, and a virtual service to direct the
    traffic destined to _*.wikipedia.org_ to the gateway.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: MUTUAL
                clientCertificate: /etc/certs/cert-chain.pem
                privateKey: /etc/certs/key.pem
                caCertificates: /etc/certs/root-cert.pem
                subjectAltNames:
                - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
                sni: www.wikipedia.org # an SNI to match egress gateway's expectation for an SNI
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: wikipedia
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Route the traffic destined to _*.wikipedia.org_ from the egress gateway to _www.wikipedia.org_. We can use this
 trick since all the _*.wikipedia.org_ sites are apparently served by each of the _wikipedia.org_ servers. It means that
 we can route the traffic to an IP of any _*.wikipedia.org_ sites, in particular to _www.wikipedia.org_,
 and the server at that IP will [manage to serve](https://en.wikipedia.org/wiki/Virtual_hosting) any of the Wikipedia
 sites. For a general case, in which the all the domain names of a `ServiceEntry` are not served by all the hosting
 servers, a more complex configuration is required. Note that we must create a `ServiceEntry` for _www.wikipedia.org_
 with resolution `DNS` so the gateway will be able to perform the routing.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: www-wikipedia
    spec:
      hosts:
      - www.wikipedia.org
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
        [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy and see a counter that corresponds to our
    requests to _*.wikipedia.org_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c egressgateway -n istio-system -- curl -s localhost:15000/stats | grep www.wikipedia.org.upstream_cx_total
    cluster.outbound|443||www.wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

### Cleanup of HTTPS traffic configuration to _*.wikipedia.org_

{{< text bash >}}
$ istioctl delete serviceentry wikipedia www-wikipedia
$ istioctl delete gateway istio-egressgateway
$ istioctl delete virtualservice direct-wikipedia-through-egress-gateway wikipedia
$ istioctl delete destinationrule set-sni-for-egress-gateway
{{< /text >}}

## Enable HTTPS traffic to arbitrary wildcarded domains

The configuration in the previous section works thanks to the fact that all the _*.wikipedia.org_ sites are apparently
served by each of the _wikipedia.org_ servers. This could not always be the case. In many cases we may want to configure
egress control for HTTPS access to _*.com_ or _*.org_ domains, or even to _*_ (all the domains). Configuring traffic to
arbitrary wildcarded domains introduces a challenge for Istio gateways. In the previous section you directed the traffic
to _www.wikipedia.org_, and this host was known to your gateway during the configuration. The gateway, however, cannot
know an IP of an arbitrary host it receives a request for. Would we want to control access to _*.com_, and send
requests to _www.cnn.com_ and _www.abc.com_, the Istio gateway would not know which IP to forward the requests.
This limitation is due to the limitation of Envoy, the proxy Istio is based on. Envoy route traffic either to a
predefined host, or a predefined IP, or to the original destination IP of the request. In the case of the gateway the
original destination IP of the request is lost (since the request was routed to the egress gateway and its destination
IP is the IP of the gateway).
In short, the Istio gateway based on Envoy, cannot route traffic to an arbitrary host, and AS-IS, is unable to perform
traffic control to arbitrary wildcarded domains. To enable such traffic control for HTTPS (and for any TLS), we need to
deploy an SNI forward proxy in addition to Envoy. Envoy will route the requests to a wildcarded domain to the SNI
forward proxy, which, in turn, will forward the request to the destination by the value of SNI. Let's reconfigure our
access to _*.wikipedia.org_ to support HTTPS traffic to arbitrary wildcarded domains.

1.  Create a new egress gateway, call it, for example, `istio-egressgateway-with-sni-proxy`. The following command will
    generate `istio-egressgateway-with-sni-proxy.yaml`.

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgtateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/clusterrole.yaml -x charts/gateways/templates/clusterrolebindings.yaml --set  global.mtls.enabled=true -f - > $HOME/istio-egressgateway-with-sni-proxy.yaml
    gateways:
      enabled: true
      istio-ingressgateway:
        enabled: false
      istio-egressgateway:
        enabled: false
      istio-egressgateway-with-sni-proxy:
        enabled: true
        labels:
          app: istio-egressgateway-with-sni-proxy
          istio: egressgateway-with-sni-proxy
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        serviceAnnotations: {}
        type: ClusterIP
        ports:
          - port: 443
            name: https
        secretVolumes:
          - name: egressgateway-certs
            secretName: istio-egressgateway-certs
            mountPath: /etc/istio/egressgateway-certs
          - name: egressgateway-ca-certs
            secretName: istio-egressgateway-ca-certs
            mountPath: /etc/istio/egressgateway-ca-certs
    EOF
    {{< /text >}}

1.  Create a configuration file for the Nginx SNI proxy. You may want to edit the file to specify additional Nginx
    settings, if required.

    {{< text bash >}}
    $ cat <<EOF > $HOME/nginx-sni-proxy.conf
    user www-data;

    stream {
      log_format log_stream '$remote_addr [$time_local] $protocol [$ssl_preread_server_name]'
      '$status $bytes_sent $bytes_received $session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # tcp forward proxy by SNI
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:443;
        proxy_pass   $ssl_preread_server_name:443;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the Nginx SNI proxy:

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap --from-file=$HOME/nginx-sni-proxy.conf
    {{< /text >}}

1.  Deploy the new egress gateway:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-egressgateway-with-sni-proxy.yaml
    serviceaccount "istio-egressgateway-with-sni-proxy-service-account" created
    clusterrole "istio-egressgateway-with-sni-proxy-istio-system" created
    clusterrolebinding "istio-egressgateway-with-sni-proxy-istio-system" created
    service "istio-egressgateway-with-sni-proxy" created
    deployment "istio-egressgateway-with-sni-proxy" created
    horizontalpodautoscaler "istio-egressgateway-with-sni-proxy" created
    {{< /text >}}

1.  Define a `ServiceEntry` for `*.wikipedia.org`:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: tls
        protocol: TLS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Create an egress `Gateway` for _*.wikipedia.org_, port 443, protocol TLS, a destination rule to set the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) for the gateway, and a virtual service to direct the
    traffic destined to _*.wikipedia.org_ to the gateway.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    kind: Gateway
    metadata:
      name: istio-egressgateway-with-sni-proxy
    spec:
      selector:
        istio: egressgateway-with-sni-proxy
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: MUTUAL
                clientCertificate: /etc/certs/cert-chain.pem
                privateKey: /etc/certs/key.pem
                caCertificates: /etc/certs/root-cert.pem
                subjectAltNames:
                - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account
                sni: www.wikipedia.org # an SNI to match egress gateway's expectation for an SNI
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
            subset: wikipedia
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Route the traffic destined to _*.wikipedia.org_ from the egress gateway to _www.wikipedia.org_. We can use this
 trick since all the _*.wikipedia.org_ sites are apparently served by each of the _wikipedia.org_ servers. It means that
 we can route the traffic to an IP of any _*.wikipedia.org_ sites, in particular to _www.wikipedia.org_,
 and the server at that IP will [manage to serve](https://en.wikipedia.org/wiki/Virtual_hosting) any of the Wikipedia
 sites. For a general case, in which the all the domain names of a `ServiceEntry` are not served by all the hosting
 servers, a more complex configuration is required. Note that we must create a `ServiceEntry` for _www.wikipedia.org_
 with resolution `DNS` so the gateway will be able to perform the routing.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: www-wikipedia
    spec:
      hosts:
      - www.wikipedia.org
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - istio-egressgateway-with-sni-proxy
      tcp:
      - match:
        - gateways:
          - istio-egressgateway-with-sni-proxy
          port: 443
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
        [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy and see a counter that corresponds to our
    requests to _*.wikipedia.org_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -c egressgateway-with-sni-proxy -n istio-system -- curl -s localhost:15000/stats | grep www.wikipedia.org.upstream_cx_total
    cluster.outbound|443||www.wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

### Cleanup of HTTPS traffic configuration to arbitrary wildcarded domains

1.  Delete the configuration items you created:

    {{< text bash >}}
    $ istioctl delete serviceentry wikipedia www-wikipedia
    $ istioctl delete gateway istio-egressgateway-with-sni-proxy
    $ istioctl delete virtualservice direct-wikipedia-through-egress-gateway wikipedia
    $ istioctl delete destinationrule set-sni-for-egress-gateway
    $ kubectl delete -f $HOME/istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap
    {{< /text >}}

1. Remove the configuration files you created

    {{< text bash >}}
    $ rm $HOME/istio-egressgateway-with-sni-proxy.yaml
    $ rm $HOME/nginx-sni-proxy.conf
    {{< /text >}}

## Cleanup

Shutdown the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) service:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
