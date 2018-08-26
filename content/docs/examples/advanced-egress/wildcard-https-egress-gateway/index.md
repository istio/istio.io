---
title: Configure Egress Gateway for HTTPS traffic to wildcarded domains
description: Use an SNI proxy in addition to the Envoy instance in the istio-egressgateway for wildcarded domains
keywords: [traffic-management,egress]
weight: 44
---

The [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway/) example, the
[Direct HTTPS traffic through an egress gateway](/docs/examples/advanced-egress/egress-gateway/#direct-https-traffic-through-an-egress-gateway)
section described how to configure an Istio egress gateway for HTTPS traffic for specific hostnames, like
`edition.cnn.com`. This example explains how to enable an egress gateway for HTTPS traffic to a set of domains, for
example to `*.wikipedia.org`, without the need to specify each and every host.

## Background

Suppose you want to enable secure egress traffic control in Istio for the `wikipedia.org` sites in all the languages.
Each version of `wikipedia.org` in a particular language has its own hostname, e.g. `en.wikipedia.org` and
`de.wikipedia.org` in the English and the German languages, respectively. You want to enable the egress traffic by common
configuration items for all the _wikipedia_ sites, without the need to specify the sites in all the languages.

## Before you begin

This examples assumes you deployed Istio with [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/examples/advanced-egress/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

## Configure HTTPS traffic to _*.wikipedia.org_

1.  Define a `ServiceEntry` for `*.wikipedia.org`:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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

1.  Create an egress `Gateway` for _*.wikipedia.org_, port 443, protocol TLS; and a destination rule to set the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) for the gateway; and also a virtual service to direct the
    traffic destined for _*.wikipedia.org_ to the gateway.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
                mode: ISTIO_MUTUAL
                sni: www.wikipedia.org # an SNI to match egress gateway's expectation for an SNI
    EOF
    {{< /text >}}

1.  Route the traffic destined for _*.wikipedia.org_ to the egress gateway and from the egress gateway to
  _www.wikipedia.org_.
   You can use this trick since all the _*.wikipedia.org_ sites are apparently served by each of the
   _wikipedia.org_ servers. It means that you can route the traffic to an IP of any _*.wikipedia.org_ sites, in
   particular to _www.wikipedia.org_, and the server at that IP will
   [manage to serve](https://en.wikipedia.org/wiki/Virtual_hosting) any of the Wikipedia sites.
   For a general case, in which all the domain names of a `ServiceEntry` are not served by all the hosting
   servers, a more complex configuration is required. Note that you must create a `ServiceEntry` for _www.wikipedia.org_
   with resolution `DNS` so the gateway will be able to perform the routing.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      - istio-egressgateway
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
$ kubectl delete serviceentry wikipedia www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule set-sni-for-egress-gateway
{{< /text >}}

## Enable HTTPS traffic to arbitrary wildcarded domains

The configuration in the previous section works thanks to the fact that all the _*.wikipedia.org_ sites are apparently
served by each of the _wikipedia.org_ servers. However, this may not always be the case. In many cases you may want to
configure egress control for HTTPS access to `*.com` or `*.org` domains, or even to `*` (all the domains).

Configuring traffic to arbitrary wildcarded domains introduces a challenge for Istio gateways. In the previous section
you directed the traffic to _www.wikipedia.org_, and this host was known to your gateway during the configuration.
The gateway, however, cannot know an IP address of an arbitrary host it receives a request for. Would you want to
control access to `*.com`, and send requests to _www.cnn.com_ and _www.abc.com_, the Istio gateway would not know which
IP address to forward the requests.
This limitation is due to the limitation of [Envoy](https://www.envoyproxy.io), the proxy Istio is based on. Envoy
routes traffic either to predefined hosts, or to predefined IP addresses, or to the original destination IP address of
the request. In the case of the gateway the original destination IP of the request is lost (since the request was routed
to the egress gateway and its destination IP address is the IP address of the gateway).

In short, the Istio gateway based on Envoy cannot route traffic to an arbitrary, not preconfigured host, and AS-IS is
unable to perform traffic control to arbitrary wildcarded domains. To enable such traffic control for HTTPS (and for any
TLS), you need to deploy an SNI forward proxy in addition to Envoy. Envoy will route the requests destined for a
wildcarded domain to the SNI forward proxy, which, in turn, will forward the requests to the destination by the value of
SNI.

In this section you will configure Istio to route HTTPS traffic to arbitrary wildcarded domains, through an egress
gateway.

### Prepare a new egress gateway with an SNI proxy

In this subsection you deploy an egress gateway with an SNI proxy, in addition to the standard Istio Envoy proxy. You
can use any SNI proxy that is capable to route traffic according to arbitrary, not-preconfigured SNI values; we used
[Nginx](http://nginx.org) to achieve this functionality. The SNI proxy will listen on the port `8443`, you can use any
port other than the ports specified for the egress `Gateway` and for the `VirtualServices` defined on it. The SNI proxy
will forward the traffic to the port `443`.

1.  Create a configuration file for the Nginx SNI proxy. You may want to edit the file to specify additional Nginx
    settings, if required. Note that the `server`'s `listen` directive specifies the port `8443`, its `proxy_pass`
    directive uses `ssl_preread_server_name` with port `443` and `ssl_preread` directive enables `SNI` reading.

    {{< text bash >}}
    $ cat <<EOF > $HOME/sni-proxy.conf
    user www-data;

    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # tcp forward proxy by SNI
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:8443;
        proxy_pass   \$ssl_preread_server_name:443;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the Nginx SNI proxy:

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=$HOME/sni-proxy.conf
    {{< /text >}}


1.  The following command will generate `istio-egressgateway-with-sni-proxy.yaml` to edit and deploy.

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/clusterrole.yaml -x charts/gateways/templates/clusterrolebindings.yaml --set  global.mtls.enabled=true --set global.istioNamespace=istio-system -f - > $HOME/istio-egressgateway-with-sni-proxy.yaml
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
        cpu:
          targetAverageUtilization: 80
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
        configVolumes:
          - name: sni-proxy-config
            configMapName: egress-sni-proxy-configmap
        additionalContainers:
        - name: sni-proxy
          image: nginx
          volumeMounts:
          - name: sni-proxy-config
            mountPath: /etc/nginx
            readOnly: true
    EOF
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

1.  Verify that the new egress gateway is running. Note that the pod has two containers (one is the Envoy proxy and the
    second one is the SNI proxy).

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1.  Create a service entry with a static address equal to 127.0.0.1 (`localhost`), and disable mutual TLS on the traffic directed to the new
    service entry:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: sni-proxy
    spec:
      hosts:
      - sni-proxy.local
      location: MESH_EXTERNAL
      ports:
      - number: 8443
        name: tcp
        protocol: TCP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: disable-mtls-for-sni-proxy
    spec:
      host: sni-proxy.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

### Configure access to _*.wikipedia.org_ using the egress gateway with SNI proxy

1.  Define a `ServiceEntry` for `*.wikipedia.org`:

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
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
    traffic destined for _*.wikipedia.org_ to the gateway.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
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
                mode: ISTIO_MUTUAL
                sni: placeholder.wikipedia.org # an SNI to match egress gateway's expectation for an SNI
    EOF
    {{< /text >}}

1.  Route the traffic destined for _*.wikipedia.org_ to the egress gateway and from the egress gateway to the SNI proxy.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      - istio-egressgateway-with-sni-proxy
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
      tcp:
      - match:
        - gateways:
          - istio-egressgateway-with-sni-proxy
          port: 443
        route:
        - destination:
            host: sni-proxy.local
            port:
              number: 8443
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

1.  Check the statistics of the egress gateway's Envoy proxy and see a counter that corresponds to our requests to
    _*.wikipedia.org_ (the counter for traffic to the SNI proxy). If Istio is deployed in the `istio-system` namespace, the command
    to print the counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep sni-proxy.local.upstream_cx_total
    cluster.outbound|8443||sni-proxy.local.upstream_cx_total: 2
    {{< /text >}}

1.  Check the logs of the SNI proxy. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

1.  Check the mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep '"connectionEvent":"open"' | grep '"sourceName":"istio-egressgateway' | grep 'wikipedia.org'
    {"level":"info","time":"2018-08-26T16:16:34.784571Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"127.0.0.1","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":298,"reporter":"source","requestedServerName":"placeholder.wikipedia.org","sentBytes":0,"sourceApp":"istio-egressgateway-with-sni-proxy","sourceIp":"172.30.146.88","sourceName":"istio-egressgateway-with-sni-proxy-7c4f7868fb-rc8pr","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-egressgateway-with-sni-proxy","sourcePrincipal":"cluster.local/ns/default/sa/default","sourceWorkload":"istio-egressgateway-with-sni-proxy","totalReceivedBytes":298,"totalSentBytes":0}
    {{< /text >}}

    Note the `requestedServerName` attribute.

### Cleanup of HTTPS traffic configuration to arbitrary wildcarded domains

1.  Delete the configuration items for _*.wikipedia.org_:

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule set-sni-for-egress-gateway
    {{< /text >}}

1.  Delete the configuration items for the `egressgateway-with-sni-proxy` `Deployment`:

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f $HOME/istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1.  Remove the configuration files you created:

    {{< text bash >}}
    $ rm $HOME/istio-egressgateway-with-sni-proxy.yaml
    $ rm $HOME/nginx-sni-proxy.conf
    {{< /text >}}

## Cleanup

Perform the instructions in the [Cleanup](/docs/examples/advanced-egress/egress-gateway/#cleanup)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.
