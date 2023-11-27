---
title: "[WIP] Routing HTTPS/TLS traffic to arbitrary remote destinations"
description: "A generic approach to set up egress gateways and use them to route traffic to a restricted set of target remote hosts dynamically, supporting wildcard domains."
publishdate: 2023-12-10
attribution: "Gergő Huszty (IBM)"
keywords: [traffic-management,gateway,mesh,mtls,egress,remote]
---

If you are using Istio to handle application originated outbound traffic, you are probably familiar with the concept of
egress gateways. Those are specific in a way that they are forwarding and routing mesh application originated traffic
and not exposing their services to the external world. This is a useful feature if your system is operating in a restricted
environment and you want to control what can be reached on the public internet from your mesh.

## Background

The use-case is documented in the official Istio docs until 1.13, but parts related to arbitrary target domains got removed
as it caused unfortunate confusions.
However, the old solution was still usable until now, when Istio 1.20 dropped some code from Envoy which made the approach work.
This post attempts to describe how we resolved the issue and fill the gap with an as-similar-as-possible approach. We will use
generic and Istio version independent components and Envoy features. That should allow users of the old solution to seamlessly
migrate before their systems are facing the breaking changes in Istio 1.20.

## Problem to solve

The currently documented egress traffic routing use-cases are all building on the assumption that the target of the traffic
(the hostname) is statically determined by a `VirtualService`, that tells Envoy in the egress gateway pod where to TCP proxy
the matching outbound connections. You can use multiple and even wildcard DNS names to match the routing criteria, but you
are not able to route the traffic exactly where the application wanted to. For example you can match traffic that targets
`*.wikipedia.org`, but you can direct everything into a single final target, i.e. `en.wikipedia.org`. If there would be a
service on `anyservice.wikipedia.org` that is not hosted by the same server(s) as `en.wikipedia.org`, your traffic to that
arbitrary host will fail. In fact the connection would go to `en.wikipedia.org` servers, while the target hostname in the
TLS handshake and the HTTP payload would contain `anyservice.wikipedia.org`, which may not be served by the same servers.
The solution on high level is to inspect the original server name (SNI extension) in the application TLS handshake (that is sent
in plain-text, so no TLS termination or other man-in-the-middle operation is needed) in every new connection and use it as
a target dynamically to TCP proxy the traffic when leaves the gateway.

## Further security measures

Now that we are restricting the traffic, we should be able to lock down the egress gateways in a way, that they can be used
only from within the mesh. This is achieved by enforcing the `ISTIO_MUTUAL` or mTLS peer authentication between the application
sidecar and the gateway. That means, there will be two layers of TLS on the application L7 payload. One that is the application
originated end-to-end TLS session terminated by the final remote target, and another one that is the Istio mTLS session.

Also, in order to mitigate application pod corruption, not only the application sidecar performs hostname list checks, but
the gateway as well. So that any compromised application pod can only still access the allowed targets, nothing more.

## Low-level Envoy programming to the rescue

Recent Envoy releases implements a specific, dynamic TCP forward proxy solution that is using the SNI header on a per
connection basis to determine the target. While `VirtualService` cannot express the target like this, we are able to use
`EnvoyFilter`s to alter the Istio generated routing instructions to match the needs.

The idea is to create a custom `Gateway` instance in the egress gateway pod(s) to listen for the outbound traffic. With
a `DestinationRule` and a `VirtualService` we can instruct the application sidecars to route the traffic (to a selected
list of hostnames) to that `Gateway`, using Istio mTLS. On the gateway pod side we build the SNI forwarder with the mentioned
`EnvoyFilter`s by introducing internal Envoy listeners and clusters that will make it happen. The last thing is to patch the
internal destination of the gateway implemented TCP proxy to the internal SNI forwarder.

## Solution

{{< image width="90%" link="./egress-sni-flow.png" alt="Egress SNI routing with arbitrary domain names" title="Egress SNI routing with arbitrary domain names" caption="Egress SNI routing with arbitrary domain names" >}}

In order to deploy the sample configuration, create the `istio-egress` namespace and deploy the gateway along with some RBAC
and it's `Service`. We use the gateway injection method in the example. Depending on your install method, you may want to
deploy it differently (for example through an `IstioOperator` CR, or through Helm).

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

Verify if your gateway `Pod` is started up fine. If so, deploy the main part of the egress routing configuration:

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

Check the logs of `istiod` and the gateway pod for any errors of warnings. If all goes well, your mesh sidecars are now routing
`*.wikipedia.org` towards your gateway pod, while the gateway pod is routing to the exact remote host based on the application
request.

## Testing

Following other examples, we will use the sleep pod. Assuming there is automatic sidecar injection in your default namespace, deploy
the test app:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

Get your pod and gateway name:

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ export GATEWAY_POD=$(kubectl get pod -n istio-egress -l istio=egressgateway -o jsonpath={.items..metadata.name})
{{< /text >}}

Test that you are able to connect to a `wikipedia.org` site:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
{{< /text >}}

We could reach both English and German Wikipedia, great! To have something to compare, let's check another site:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://cloud.ibm.com/login | grep -o "<title>.*</title>"'
<title>IBM Cloud</title>
{{< /text >}}

Now that we turned on access logging globally (with the `Telemetry` CR in the manifest), we can double-check what happened in the proxies.

First, check the gateway:

{{< text bash >}}
$ kubectl logs -n istio-egress $GATEWAY_POD
[...]
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 813 111152 55 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48262 envoy://sni_listener/ envoy://internal_client_address/ en.wikipedia.org -
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 1531 111950 55 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55102 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 821 92848 49 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48278 envoy://sni_listener/ envoy://internal_client_address/ de.wikipedia.org -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 1539 93646 50 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55108 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
{{< /text >}}

There are four log entries, representing two of the three curl requests. Each pair shows how a single request is flowing through the envoy traffic processing pipeline twice.
They are printed in reverse order, but we can see the 2nd and the 4th line saying connection arrived to the gateway service and passed through the internal `sni_cluster` target.
The 1st and 3rd line shows the final target is determined from the inner SNI header. This is the one set by the original application.
Then it is forwarded to `dynamic_forward_proxy_cluster` which is the final entity in envoy that is talking to the final remote target.

Great, but where is the third request to IBM Cloud? Let's check the sidecar logs:

{{< text bash >}}
$ kubectl logs $SOURCE_POD -c istio-proxy
[...]
[2023-11-24T13:21:52.793Z] "- - -" 0 - - - "-" 813 111152 61 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55102 208.80.153.224:443 172.17.34.35:37020 en.wikipedia.org -
[2023-11-24T13:21:52.994Z] "- - -" 0 - - - "-" 821 92848 55 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55108 208.80.153.224:443 172.17.34.35:37030 de.wikipedia.org -
[2023-11-24T13:21:55.197Z] "- - -" 0 - - - "-" 805 15199 158 - "-" "-" "-" "-" "104.102.54.251:443" PassthroughCluster 172.17.34.35:45584 104.102.54.251:443 172.17.34.35:45582 cloud.ibm.com -
{{< /text >}}

As you can see, Wikipedia requests were sent through the gateway, while the request towards IBM Cloud went straight out from the application pod to the internet. This is indicated with the `PassthroughCluster` log.

## Conclusion

We implemented a selective routing for egress HTTPS/TLS traffic with egress gateways, supporting arbitrary and wildcard domain names. Of course the example
can be extended with HA requirements (i.e. with adding zone aware gateway `Deployment`s, etc.). From here you are free to restrict the direct external
network access of your application, for example with network policies that denies traffic to tcp port 443 in the application namespace.
Once that is in place, the application cannot directly talk to the public network, only through the gateway, which is limited to a predefined set of remote hostnames.

The solution scales easily. You can pick up multiple domain names to the list, and they are allow-listed as soon as you roll it out!
No need to set up per domain `VirtualService`s or other routing details. Beware the list appears at multiple places, so if you use
some tooling for CI/CD (i.e. Kustomize), the domain name list is better to be extracted to a single place, from where you render into the final
places.

That was all! I hope it was helpful.
If you are an existing user of the previous nginx based solution,
you are now free to migrate to this approach before upgrading to Istio 1.20, which would disrupt your current setup.

Happy SNI routing!

## References

* [Envoy docs for the SNI forwarder](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [Previous solution with nginx as an SNI proxy container in the gateway](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)
