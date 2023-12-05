---
title: "Routing egress traffic to wildcard destinations"
description: "A generic approach to set up egress gateways that can route traffic to a restricted set of target remote hosts dynamically, including wildcard domains."
publishdate: 2023-12-01
attribution: "Gergő Huszty (IBM)"
keywords: [traffic-management,gateway,mesh,mtls,egress,remote]
---

If you are using Istio to handle application-originated traffic to destinations outside of the mesh, you're probably familiar with the concept of egress gateways.
Egress gateways can be used to monitor and forward traffic from mesh-internal applications to locations outside of the mesh.
This is a useful feature if your system is operating in a restricted
environment and you want to control what can be reached on the public internet from your mesh.

The use-case of configuring an egress gateway to handle arbitrary wildcard domains had been included in the [official Istio docs](https://archive.istio.io/v1.13/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains) up until version 1.13, but was subsequently removed because the documented solution was not officially supported or recommended and was subject to breakage in future versions of Istio.
Nevertheless, the old solution was still usable with Istio versions before 1.20. Istio 1.20, however, dropped some Envoy functionality that was required for the approach to work.

This post attempts to describe how we resolved the issue and filled the gap with a similar approach using Istio version-independent components and Envoy features, but without the need for a separate Nginx SNI proxy.
Our approach allows users of the old solution to seamlessly migrate configurations before their systems face the breaking changes in Istio 1.20.

## Problem to solve

The currently documented egress gateway use-cases rely on the fact that the target of the traffic
(the hostname) is statically configured in a `VirtualService`, telling Envoy in the egress gateway pod where to TCP proxy
the matching outbound connections. You can use multiple, and even wildcard, DNS names to match the routing criteria, but you
are not able to route the traffic to the exact location specified in the application request. For example you can match traffic for targets
`*.wikipedia.org`, but you then need to forward the traffic to a single final target, e.g., `en.wikipedia.org`. If there is another
service, e.g., `anyservice.wikipedia.org`, that is not hosted by the same server(s) as `en.wikipedia.org`, the traffic to that host will fail. This is because, even though the target hostname in the
TLS handshake of the HTTP payload contains `anyservice.wikipedia.org`, the `en.wikipedia.org` servers will not be able to serve the request.

The solution to this problem at a high level is to inspect the original server name (SNI extension) in the application TLS handshake (which is sent
in plain-text, so no TLS termination or other man-in-the-middle operation is needed) in every new gateway connection and use it as
the target to dynamically TCP proxy the traffic leaving the gateway.

When restricting egress traffic via egress gateways, we need to lock down the egress gateways so that they can only be used
by clients within the mesh. This is achieved by enforcing `ISTIO_MUTUAL` (mTLS peer authentication) between the application
sidecar and the gateway. That means that there will be two layers of TLS on the application L7 payload. One that is the application
originated end-to-end TLS session terminated by the final remote target, and another one that is the Istio mTLS session.

Another thing to keep in mind is that in order to mitigate any potential application pod corruption, the application sidecar and the gateway should both perform hostname list checks.
This way, any compromised application pod will still only be able to access the allowed targets and nothing more.

## Low-level Envoy programming to the rescue

Recent Envoy releases include a dynamic TCP forward proxy solution that uses the SNI header on a per-
connection basis to determine the target of an application request. While an Istio `VirtualService` cannot configure a target like this, we are able to use
`EnvoyFilter`s to alter the Istio generated routing instructions so that the SNI header is used to determine the target.

To make it all work, we start by configuring a custom egress gateway to listen for the outbound traffic. Using
a `DestinationRule` and a `VirtualService` we instruct the application sidecars to route the traffic (for a selected
list of hostnames) to that gateway, using Istio mTLS. On the gateway pod side we build the SNI forwarder with the
`EnvoyFilter`s, mentioned above, introducing internal Envoy listeners and clusters to make it all work. Finally, we patch the
internal destination of the gateway-implemented TCP proxy to the internal SNI forwarder.

The end-to-end request flow is shown in the following diagram:

{{< image width="90%" link="./egress-sni-flow.svg" alt="Egress SNI routing with arbitrary domain names" title="Egress SNI routing with arbitrary domain names" caption="Egress SNI routing with arbitrary domain names" >}}

This diagram shows an egress HTTPS request to `en.wikipedia.org` using SNI as a routing key.

* Application container

    Application originates HTTP/TLS connection towards the final destination.
    Puts destination’s hostname into the SNI header. This TLS session is not
    decrypted inside the mesh. Only SNI header is inspected (as it is in cleartext).

* Sidecar proxy

    Sidecar intercepts traffic to matching hostnames in the SNI header from the application originated TLS sessions.
    Based on the VirtualService, the traffic is routed to the egress gateway while wrapping original traffic into
    Istio mTLS as well. Outer TLS session has the gateway Service address in the SNI header.

* Mesh listener

    A dedicated listener is created in the Gateway that mutually authenticates the Istio mTLS traffic.
    After the outer Istio mTLS termination, it unconditionally sends the inner TLS traffic with a TCP proxy
    to the other (internal) listener in the same Gateway.

* SNI forwarder

    Another listener with SNI forwarder performs a new TLS header inspection for the original TLS session.
    If the inner SNI hostname matches the allowed domain names (including wildcards), it TCP proxies the
    traffic to the destination, read from the header per connection. This listener is internal to Envoy
    (allowing it to restart traffic processing to see the inner SNI value), so that no pods (inside or outside the mesh)
    can connect to it directly. This listener is 100% manually configured through EnvoyFilter.

## Deploy the sample

In order to deploy the sample configuration, start by creating the `istio-egress` namespace and then use the following YAML to deploy an egress gateway, along with some RBAC
and its `Service`. We use the gateway injection method to create the gateway in this example. Depending on your install method, you may want to
deploy it differently (for example, using an `IstioOperator` CR or using Helm).

{{< text yaml >}}
# New k8s cluster service to put egressgateway into the Service Registry,
# so application sidecars can route traffic towards it within the mesh.
apiVersion: v1
kind: Service
metadata:
  name: egressgateway
  namespace: istio-egress
spec:
  type: ClusterIP
  selector:
    istio: egressgateway
  ports:
  - port: 443
    name: tls-egress
    targetPort: 8443

---
# Gateway deployment with injection method
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-egressgateway
  namespace: istio-egress
spec:
  selector:
    matchLabels:
      istio: egressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: egressgateway
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337

---
# Set up roles to allow reading credentials for TLS
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups:
  - security.openshift.io
  resourceNames:
  - anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-egressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

Verify the gateway pod is up and running in the `istio-egress` namespace and then apply the following YAML to configure the gateway routing:

{{< text yaml >}}
# Define a new listener that enforces Istio mTLS on inbound connections.
# This is where sidecar will route the application traffic, wrapped into
# Istio mTLS.
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 8443
      name: tls-egress
      protocol: TLS
    hosts:
      - "*"
    tls:
      mode: ISTIO_MUTUAL

---
# VirtualService that will instruct sidecars in the mesh to route the outgoing
# traffic to the egress gateway Service if the SNI target hostname matches
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-wildcard-through-egress-gateway
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  gateways:
  - mesh
  - egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
        - "*.wikipedia.org"
    route:
    - destination:
        host: egressgateway.istio-egress.svc.cluster.local
        subset: wildcard
# Dummy routing instruction. If omitted, no reference will point to the Gateway
# definition, and istiod will optimise the whole new listener out.
  tcp:
  - match:
    - gateways:
      - egressgateway
      port: 8443
    route:
    - destination:
        host: "dummy.local"
      weight: 100

---
# Instruct sidecars to use Istio mTLS when sending traffic to the egress gateway
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  host: egressgateway.istio-egress.svc.cluster.local
  subsets:
  - name: wildcard
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL

---
# Put the remote targets into the Service Registry
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wildcard
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  ports:
  - number: 443
    name: tls
    protocol: TLS

---
# Access logging for the gateway
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy

---
# And finally, the configuration of the SNI forwarder,
# it's internal listener, and the patch to the original Gateway
# listener to route everything into the SNI forwarder.
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: sni-magic
  namespace: istio-system
spec:
  configPatches:
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_cluster
        load_assignment:
          cluster_name: sni_cluster
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  envoy_internal_address:
                    server_listener_name: sni_listener
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: dynamic_forward_proxy_cluster
        lb_policy: CLUSTER_PROVIDED
        cluster_type:
          name: envoy.clusters.dynamic_forward_proxy
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.clusters.dynamic_forward_proxy.v3.ClusterConfig
            dns_cache_config:
              name: dynamic_forward_proxy_cache_config
              dns_lookup_family: V4_ONLY

  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_listener
        internal_listener: {}
        listener_filters:
        - name: envoy.filters.listener.tls_inspector
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector

        filter_chains:
        - filter_chain_match:
            server_names:
            - "*.wikipedia.org"
          filters:
            - name: envoy.filters.network.sni_dynamic_forward_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.sni_dynamic_forward_proxy.v3.FilterConfig
                port_value: 443
                dns_cache_config:
                  name: dynamic_forward_proxy_cache_config
                  dns_lookup_family: V4_ONLY
            - name: envoy.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                stat_prefix: tcp
                cluster: dynamic_forward_proxy_cluster
                access_log:
                - name: envoy.access_loggers.file
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                    path: "/dev/stdout"
                    log_format:
                      text_format_source:
                        inline_string: '[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%
                          %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
                          "%UPSTREAM_TRANSPORT_FAILURE_REASON%" %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
                          %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
                          "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%" %UPSTREAM_CLUSTER%
                          %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS%
                          %REQUESTED_SERVER_NAME% %ROUTE_NAME%

                          '
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.tcp_proxy"
    patch:
      operation: MERGE
      value:
        name: envoy.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: tcp
          cluster: sni_cluster
{{< /text >}}

Check the `istiod` and gateway logs for any errors or warnings. If all went well, your mesh sidecars are now routing
`*.wikipedia.org` requests to your gateway pod while the gateway pod is then forwarding them to the exact remote host specified in the application
request.

## Try it out

Following other Istio egress examples, we will use the
[sleep]({{< github_tree >}}/samples/sleep) pod as a test source for sending requests.
Assuming automatic sidecar injection is enabled in your default namespace, deploy
the test app using the following command:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

Get your sleep and gateway pods:

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ export GATEWAY_POD=$(kubectl get pod -n istio-egress -l istio=egressgateway -o jsonpath={.items..metadata.name})
{{< /text >}}

Run the following command to confirm that you are able to connect to the `wikipedia.org` site:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
{{< /text >}}

We could reach both English and German `wikipedia.org` subdomains, great!

Normally, in a production environment, we would [block external requests](/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy) that are not configured to redirect through the egress gateway, but since we didn't do that in our test environment, let's access another external site for comparison:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://cloud.ibm.com/login | grep -o "<title>.*</title>"'
<title>IBM Cloud</title>
{{< /text >}}

Since we have access logging turned on globally (with the `Telemetry` CR in the manifest), we can now inspect the logs to see how the above requests were handled by the proxies.

First, check the gateway logs:

{{< text bash >}}
$ kubectl logs -n istio-egress $GATEWAY_POD
[...]
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 813 111152 55 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48262 envoy://sni_listener/ envoy://internal_client_address/ en.wikipedia.org -
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 1531 111950 55 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55102 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 821 92848 49 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48278 envoy://sni_listener/ envoy://internal_client_address/ de.wikipedia.org -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 1539 93646 50 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55108 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
{{< /text >}}

There are four log entries, representing two of our three curl requests. Each pair shows how a single request flows through the envoy traffic processing pipeline.
They are printed in reverse order, but we can see the 2nd and the 4th line show that the requests arrived at the gateway service and were passed through the internal `sni_cluster` target.
The 1st and 3rd line show that the final target is determined from the inner SNI header, i.e., the target host set by the application.
The request is forwarded to `dynamic_forward_proxy_cluster` which finally sends on the request from Envoy to the remote target.

Great, but where is the third request to IBM Cloud? Let's check the sidecar logs:

{{< text bash >}}
$ kubectl logs $SOURCE_POD -c istio-proxy
[...]
[2023-11-24T13:21:52.793Z] "- - -" 0 - - - "-" 813 111152 61 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55102 208.80.153.224:443 172.17.34.35:37020 en.wikipedia.org -
[2023-11-24T13:21:52.994Z] "- - -" 0 - - - "-" 821 92848 55 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55108 208.80.153.224:443 172.17.34.35:37030 de.wikipedia.org -
[2023-11-24T13:21:55.197Z] "- - -" 0 - - - "-" 805 15199 158 - "-" "-" "-" "-" "104.102.54.251:443" PassthroughCluster 172.17.34.35:45584 104.102.54.251:443 172.17.34.35:45582 cloud.ibm.com -
{{< /text >}}

As you can see, Wikipedia requests were sent through the gateway while the request to IBM Cloud went straight out from the application pod to the internet, as indicated by the `PassthroughCluster` log.

## Conclusion

We implemented controlled routing for egress HTTPS/TLS traffic using egress gateways, supporting arbitrary and wildcard domain names. In a production environment, the example shown in this post
would be extended to support HA requirements (e.g., adding zone aware gateway `Deployment`s, etc.) and to restrict the direct external
network access of your application so that the application can only access the public network through the gateway, which is limited to a predefined set of remote hostnames.

The solution scales easily. You can include multiple domain names in the configuration, and they will be allow-listed as soon as you roll it out!
No need to configure per domain `VirtualService`s or other routing details. Be careful, however, as the domain names are listed in multiple places in the config. If you use
tooling for CI/CD (e.g., Kustomize), it's best to extract the domain name list into a single place from which you can render into the required configuration resources.

That's all! I hope this was helpful.
If you're an existing user of the previous Nginx-based solution,
you can now migrate to this approach before upgrading to Istio 1.20, which will otherwise disrupt your current setup.

Happy SNI routing!

## References

* [Envoy docs for the SNI forwarder](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [Previous solution with Nginx as an SNI proxy container in the gateway](https://archive.istio.io/v1.13/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)
