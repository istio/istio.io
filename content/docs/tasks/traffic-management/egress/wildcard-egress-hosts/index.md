---
title: Egress using Wildcard Hosts
description: Describes how to enable egress traffic for a set of hosts in a common domain, instead of configuring each and every host separately.
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /docs/examples/advanced-gateways/wildcard-egress-hosts/
---

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task and
the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/) example
describe how to configure egress traffic for specific hostnames, like `edition.cnn.com`.
This example shows how to enable egress traffic for a set of hosts in a common domain, for
example `*.wikipedia.org`, instead of configuring each and every host separately.

## Background

Suppose you want to enable egress traffic in Istio for the `wikipedia.org` sites in all languages.
Each version of `wikipedia.org` in a particular language has its own hostname, e.g., `en.wikipedia.org` and
`de.wikipedia.org` in the English and the German languages, respectively.
You want to enable egress traffic by common configuration items for all the _wikipedia_ sites,
without the need to specify every language's site separately.

{{< boilerplate before-you-begin-egress >}}

*   [Deploy Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

## Configure direct traffic to a wildcard host

The first, and simplest, way to access a set of hosts within a common domain is by configuring
a simple `ServiceEntry` with a wildcard host and calling the services directly from the sidecar.
When calling services directly (i.e., not via an egress gateway), the configuration for
a wildcard host is no different than that of any other (e.g., fully qualified) host,
only much more convenient when there are many hosts within the common domain.

1.  Define a `ServiceEntry` and corresponding `VirtualSevice` for `*.wikipedia.org`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      tls:
      - match:
        - port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: "*.wikipedia.org"
            port:
              number: 443
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### Cleanup direct traffic to a wildcard host

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
$ kubectl delete virtualservice wikipedia
{{< /text >}}

## Configure egress gateway traffic to a wildcard host

The configuration for accessing a wildcard host via an egress gateway depends on whether or not
the set of wildcard domains are served by a single common host.
This is the case for _*.wikipedia.org_. All of the language-specific sites are served by every
one of the _wikipedia.org_ servers. You can route the traffic to an IP of any _*.wikipedia.org_ site,
including _www.wikipedia.org_, and it will [manage to serve](https://en.wikipedia.org/wiki/Virtual_hosting)
any specific site.

In the general case, where all the domain names of a wildcard are not served by a single hosting server,
a more complex configuration is required.

### Wildcard configuration for a single hosting server

When all wildcard hosts are served by a single server, the configuration for
egress gateway-based access to a wildcard host is very similar to that of any host, with one exception:
the configured route destination will not be the same as the configured host,
i.e., the wildcard. It will instead be configured with the host of the single server for
the set of domains.

1.  Create an egress `Gateway` for _*.wikipedia.org_, a destination rule and a virtual service
    to direct the traffic through the egress gateway and from the egress gateway to the external service.

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
          name: tls
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-wikipedia
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
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
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Create a `ServiceEntry` for the destination server, _www.wikipedia.org_.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy for the counter that corresponds to your
    requests to _*.wikipedia.org_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep www.wikipedia.org.upstream_cx_total
    cluster.outbound|443||www.wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

#### Cleanup wildcard configuration for a single hosting server

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

### Wildcard configuration for arbitrary domains

The configuration in the previous section worked because all the _*.wikipedia.org_ sites can
be served by any one of the _wikipedia.org_ servers. However, this is not always the case.
For example, you may want to configure egress control for access to more general
wildcard domains like `*.com` or `*.org`.

Configuring traffic to arbitrary wildcard domains introduces a challenge for Istio gateways. In the previous section
you directed the traffic to _www.wikipedia.org_, which was made known to your gateway during configuration.
The gateway, however, would not know the IP address of any arbitrary host it receives in a request.
This is due to a limitation of [Envoy](https://www.envoyproxy.io), the proxy used by the default Istio egress gateway.
Envoy routes traffic either to predefined hosts, predefined IP addresses, or to the original destination IP address of
the request. In the gateway case, the original destination IP of the request is lost since the request is first routed
to the egress gateway and its destination IP address is the IP address of the gateway.

Consequently, the Istio gateway based on Envoy cannot route traffic to an arbitrary host that is not preconfigured,
and therefore is unable to perform traffic control for arbitrary wildcard domains.
To enable such traffic control for HTTPS, and for any TLS, you need to deploy an SNI forward proxy in addition to Envoy.
Envoy will route the requests destined for a wildcard domain to the SNI forward proxy, which, in turn, will forward the
requests to the destination specified by the SNI value.

The egress gateway with SNI proxy and the related parts of the Istio architecture are shown in the following diagram:

{{< image width="80%" link="./EgressGatewayWithSNIProxy.svg" caption="Egress Gateway with SNI proxy" >}}

The following sections show you how to redeploy the egress gateway with an SNI proxy and then configure Istio to route
HTTPS traffic through the gateway to arbitrary wildcard domains.

#### Setup egress gateway with SNI proxy

In this section you deploy an egress gateway with an SNI proxy in addition to the standard Istio Envoy proxy.
This example uses [Nginx](http://nginx.org) for the SNI proxy, although any SNI proxy that is capable of routing traffic
according to arbitrary, not-preconfigured, SNI values would do.
The SNI proxy will listen on port `8443`, although you can use any port other than the ports specified for
the egress `Gateway` and for the `VirtualServices` bound to it.
The SNI proxy will forward the traffic to port `443`.

1.  Create a configuration file for the Nginx SNI proxy. You may want to edit the file to specify additional Nginx
    settings, if required. Note that the `listen` directive of the `server` specifies port `8443`, its `proxy_pass`
    directive uses `ssl_preread_server_name` with port `443` and `ssl_preread` is `on` to enable `SNI` reading.

    {{< text bash >}}
    $ cat <<EOF > ./sni-proxy.conf
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
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1.  The following command will generate `istio-egressgateway-with-sni-proxy.yaml` which you can optionally edit and then deploy.

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/clusterrole.yaml -x charts/gateways/templates/clusterrolebindings.yaml --set global.istioNamespace=istio-system -f - > ./istio-egressgateway-with-sni-proxy.yaml
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
    $ kubectl apply -f ./istio-egressgateway-with-sni-proxy.yaml
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

1.  Create a service entry with a static address equal to 127.0.0.1 (`localhost`), and disable mutual TLS for traffic directed to the new
    service entry:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

#### Configure traffic through egress gateway with SNI proxy

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

1.  Create an egress `Gateway` for _*.wikipedia.org_, port 443, protocol TLS, and a virtual service to direct the
    traffic destined for _*.wikipedia.org_ through the gateway.

    Choose the instructions corresponding to whether or not you want to enable
    [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) between the source pod and the egress gateway.

    {{< idea >}}
    You may want to enable mutual TLS to let the egress gateway monitor the identity of the source pods and to enable Mixer policy enforcement based on that identity.
    {{< /idea >}}

    {{< tabset cookie-name="mtls" >}}

    {{< tab name="mutual TLS enabled" cookie-value="enabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
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
          name: tls-egress
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
      name: egressgateway-for-wikipedia
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
    ---
    # The following filter is used to forward the original SNI (sent by the application) as the SNI of the mutual TLS
    # connection.
    # The forwarded SNI will be reported to Mixer so that policies will be enforced based on the original SNI value.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: forward-downstream-sni
    spec:
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: SIDECAR_OUTBOUND
        filterName: forward_downstream_sni
        filterType: NETWORK
        filterConfig: {}
    ---
    # The following filter verifies that the SNI of the mutual TLS connection (the SNI reported to Mixer) is
    # identical to the original SNI issued by the application (the SNI used for routing by the SNI proxy).
    # The filter prevents Mixer from being deceived by a malicious application: routing to one SNI while
    # reporting some other value of SNI. If the original SNI does not match the SNI of the mutual TLS connection, the
    # filter will block the connection to the external service.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: egress-gateway-sni-verifier
    spec:
      workloadLabels:
        app: istio-egressgateway-with-sni-proxy
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: GATEWAY
        filterName: sni_verifier
        filterType: NETWORK
        filterConfig: {}
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" cookie-value="disabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
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
         mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
     name: egressgateway-for-wikipedia
    spec:
     host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
     subsets:
       - name: wikipedia
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
     - match:
       - gateways:
         - istio-egressgateway-with-sni-proxy
         port: 443
         sni_hosts:
         - "*.wikipedia.org"
       route:
       - destination:
           host: sni-proxy.local
           port:
             number: 8443
         weight: 100
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the log of the egress gateway's Envoy proxy. If Istio is deployed in the `istio-system` namespace, the command to
    print the log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
    {{< /text >}}

    You should see lines similar to the following:

    {{< text plain >}}
    [2019-01-02T16:34:23.312Z] "- - -" 0 - 578 79141 624 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55018 172.30.109.84:443 172.30.109.112:45346 en.wikipedia.org
    [2019-01-02T16:34:24.079Z] "- - -" 0 - 586 65770 638 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55034 172.30.109.84:443 172.30.109.112:45362 de.wikipedia.org
    {{< /text >}}

1.  Check the logs of the SNI proxy. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

1.  Check the mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep '"connectionEvent":"open"' | grep '"sourceName":"istio-egressgateway' | grep 'wikipedia.org'
    {"level":"info","time":"2018-08-26T16:16:34.784571Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"127.0.0.1","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":298,"reporter":"source","requestedServerName":"en.wikipedia.org","sentBytes":0,"sourceApp":"istio-egressgateway-with-sni-proxy","sourceIp":"172.30.146.88","sourceName":"istio-egressgateway-with-sni-proxy-7c4f7868fb-rc8pr","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-egressgateway-with-sni-proxy","sourcePrincipal":"cluster.local/ns/sleep/sa/default","sourceWorkload":"istio-egressgateway-with-sni-proxy","totalReceivedBytes":298,"totalSentBytes":0}
    {{< /text >}}

    Note the `requestedServerName` attribute.

#### Cleanup wildcard configuration for arbitrary domains

1.  Delete the configuration items for _*.wikipedia.org_:

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-wikipedia
    $ kubectl delete --ignore-not-found=true envoyfilter forward-downstream-sni egress-gateway-sni-verifier
    {{< /text >}}

1.  Delete the configuration items for the `egressgateway-with-sni-proxy` `Deployment`:

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f ./istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1.  Remove the configuration files you created:

    {{< text bash >}}
    $ rm ./istio-egressgateway-with-sni-proxy.yaml
    $ rm ./sni-proxy.conf
    {{< /text >}}

## Cleanup

Shutdown the [sleep]({{<github_tree>}}/samples/sleep) service:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
