---
title: Aeraki — Manage Any Layer-7 Protocol in Istio Service Mesh
subtitle: 
description: Aeraki provides a framework to allow Istio to support more layer-7 protocols other than HTTP. 
publishdate: 2021-09-28
attribution: Huabing Zhao (Tencent)
keywords: [istio,envoy,aeraki]
---

Aeraki [Air-rah-ki] is the Greek word for 'breeze'. While Istio connects microservices in a service mesh, Aeraki provides a framework to allow Istio to support more layer-7 protocols other than just HTTP and gRPC. We hope this breeze can help Istio sail a little further.

## Lack of Protocols Support in Service Mesh

We are now facing some challenges with service meshes:

* Istio and other popular service mesh implementations have very limited support for layer 7 protocols other than HTTP and gRPC.
* Envoy RDS(Route Discovery Service) is solely designed for HTTP. Other protocols such as Dubbo and Thrift can only use listener in-line routes for traffic management, which breaks existing connections when routes change.
* It takes a lot of effort to introduce a proprietary protocol into a service mesh. You’ll need to write an Envoy filter to handle the traffic in the data plane, and a control plane to manage those Envoys.

Those obstacles make it very hard, if not impossible, for users to manage the traffic of other widely-used layer-7 protocols in microservices. For example, in a microservices application, we may have the below protocols:

* RPC: HTTP, gRPC, Thrift, Dubbo, Proprietary RPC Protocol …
* Messaging: Kafka, RabbitMQ …
* Cache: Redis, Memcached …
* Database: MySQL, PostgreSQL, MongoDB …

{{< image link="./protocols.png" caption="Common Layer-7 Protocols Used in Microservices" >}}

If you have already invested a lot of effort in migrating to a service mesh, of course, you want to get the most out of it — managing the traffic of all the protocols in your microservices.

## Aeraki's approach

To address these problems, we create an open-source project, [Aeraki Mesh](https://aeraki.net), to provide a non-intrusive, extendable way to manage any layer-7 traffic in an Istio service mesh.

{{< image link="./aeraki-architecture.png" caption="Aeraki Architecture" >}}

As this diagram shows, Aeraki Framework consists of the following components:

* Aeraki: [Aeraki](https://github.com/aeraki-mesh/aeraki) provides high-level, user-friendly traffic management rules to operations, translates the rules to envoy filter configurations, and leverages Istio’s `EnvoyFilter` API to push the configurations to the sidecar proxies. Aeraki also serves as the RDS server for MetaProtocol proxies in the data plane. Contrary to Envoy RDS, which focuses on HTTP, Aeraki RDS is aimed to provide a general dynamic route capability for all layer-7 protocols.
* MetaProtocol Proxy: [MetaProtocol Proxy](https://github.com/aeraki-mesh/meta-protocol-proxy) provides common capabilities for Layer-7 protocols, such as load balancing, circuit breaker, load balancing, routing, rate limiting, fault injection, and auth. Layer-7 protocols can be built on top of MetaProtocol. To add a new protocol into the service mesh, the only thing you need to do is implementing the [codec interface](https://github.com/aeraki-mesh/meta-protocol-proxy/blob/ac788327239bd794e745ce18b382da858ddf3355/src/meta_protocol_proxy/codec/codec.h#L118) and a couple of lines of configuration. If you have special requirements which can’t be accommodated by the built-in capabilities, MetaProtocol Proxy also has an application-level filter chain mechanism, allowing users to write their own layer-7 filters to add custom logic into MetaProtocol Proxy.

[Dubbo](https://github.com/aeraki-mesh/meta-protocol-proxy/tree/master/src/application_protocols/dubbo) and [Thrift](https://github.com/aeraki-mesh/meta-protocol-proxy/tree/master/src/application_protocols/thrift) have already been implemented based on MetaProtocol. More protocols are on the way. If you're using a close-source, proprietary protocol, you can also manage it in your service mesh simply by writing a MetaProtocol codec for it.

Most request/response style, stateless protocols can be built on top of the MetaProtocol Proxy. However, some protocols' routing policies are too "special" to be normalized in MetaProtocol. For example, Redis proxy uses a slot number to map a client query to a specific Redis server node, and the slot number is computed by the key in the request. Aeraki can still manage those protocols as long as there's an available Envoy Filter in the Envoy proxy side. Currently, for protocols in this category, [Redis](https://github.com/aeraki-mesh/aeraki/blob/master/docs/zh/redis.md) and Kafka are supported in Aeraki.

## Deep Dive Into MetaProtocol

Let’s look into how MetaProtocol works. Before MetaProtocol is introduced, if we want to proxy traffic for a specific protocol, we need to write an Envoy filter that understands that protocol and add the code to manipulate the traffic, including routing, header modification, fault injection, traffic mirroring, etc.

For most request/response style protocols, the code for traffic manipulation is very similar. Therefore, to avoid duplicating these functionalities in different Envoy filters, Aeraki Framework implements most of the common functions of a layer-7 protocol proxy in a single place — the MetaProtocol Proxy filter.

{{< image link="./metaprotocol-proxy.png" caption="MetaProtocol Proxy" >}}

This approach significantly lowers the barrier to write a new Envoy filter: instead of writing a fully functional filter, now you only need to implement the codec interface. In addition to that, the control plane is already in place — Aeraki works at the control plane to provides MetaProtocol configuration and dynamic routes for all protocols built on top of MetaProtocol.

{{< image link="./metaprotocol-proxy-codec.png" caption="Writing an Envoy Filter Before and After MetProtocol" >}}

There are two important data structures in MetaProtocol Proxy: Metadata and Mutation. Metadata is used for routing, and Mutation is used for header manipulation.

At the request path, the decoder(the decode method of the codec implementation) populates the Metadata data structure with key-value pairs parsed from the request, then the Metadata will be passed to the MetaProtocol Router. The Router selects an appropriate upstream cluster after matching the route configuration it receives from Aeraki via RDS and the Metadata.

A custom filter can populate the Mutation data structure with arbitrary key-value pairs if the request needs to be modified: adding a header or changing the value of a header. Then the Mutation data structure will be passed to the encoder(the encode method of the codec implementation). The encoder is responsible for writing the key-value pairs into the wire protocol.

{{< image link="./request-path.png" caption="The Request Path" >}}

The response path is similar to the request path, only in a different direction.

{{< image link="./response-path.png" caption="The Response Path" >}}

## An Example

If you need to implement an application protocol based on MetaProtocol, you can follow the below steps(use Thrift as an example):

### Data Plane

* Implement the [codec interface](https://github.com/aeraki-mesh/meta-protocol-proxy/blob/ac788327239bd794e745ce18b382da858ddf3355/src/meta_protocol_proxy/codec/codec.h#L118) to encode and decode the protocol package. You can refer to [Dubbo codec](https://github.com/aeraki-mesh/meta-protocol-proxy/tree/master/src/application_protocols/dubbo) and [Thrift codec](https://github.com/aeraki-mesh/meta-protocol-proxy/tree/master/src/application_protocols/thrift) as writing your own implementation.

* Define the protocol with Aeraki `ApplicationProtocol` CRD, as this YAML snippet shows:

{{< text yaml >}}
apiVersion: metaprotocol.aeraki.io/v1alpha1
kind: ApplicationProtocol
metadata:
  name: thrift
  namespace: istio-system
spec:
  protocol: thrift
  codec: aeraki.meta_protocol.codec.thrift
{{< /text >}}

### Control Plane

You don’t need to implement the control plane. Aeraki watches services and traffic rules, generates the configurations for the sidecar proxies, and sends the configurations to the data plane via `EnvoyFilter` and MetaProtocol RDS.

### Protocol selection

Similar to Istio, protocols are identified by service port prefix. Please name service ports with this pattern: tcp-metaprotocol-{application protocol}-xxx. For example, a Thrift service port should be named tcp-metaprotocol-thrift.

### Traffic management

You can change the route via `MetaRouter` CRD. For example: send 20% of the requests to v1 and 80% to v2:

{{< text yaml >}}
apiVersion: metaprotocol.aeraki.io/v1alpha1
kind: MetaRouter
metadata:
  name: test-metaprotocol-route
spec:
  hosts:
    - thrift-sample-server.thrift.svc.cluster.local
  routes:
    - name: traffic-spilt
      route:
        - destination:
            host: thrift-sample-server.thrift.svc.cluster.local
            subset: v1
          weight: 20
        - destination:
            host: thrift-sample-server.thrift.svc.cluster.local
            subset: v2
          weight: 80
{{< /text >}}

Hope this helps if you need to manage protocols other than HTTP in a service mesh. Reach out to [zhaohuabing](https://zhaohuabing.com/) if you have any questions.

## Reference

* [Aeraki Mesh website](https://aeraki.net)
* [Aeraki Mesh on GitHub](https://github.com/aeraki-mesh)
* [Live Demo: Kiali Dashboard](http://aeraki.zhaohuabing.com:20001/)
* [Live Demo: Service Metrics: Grafana](http://aeraki.zhaohuabing.com:3000/d/pgz7wp-Gz/aeraki-demo?orgId=1&refresh=10s&kiosk)
* [Live Demo: Service Metrics: Prometheus](http://aeraki.zhaohuabing.com:9090/new/graph?g0.expr=envoy_dubbo_inbound_20880___response_success&g0.tab=0&g0.stacked=1&g0.range_input=1h&g1.expr=envoy_dubbo_outbound_20880__org_apache_dubbo_samples_basic_api_demoservice_request&g1.tab=0&g1.stacked=1&g1.range_input=1h&g2.expr=envoy_thrift_inbound_9090___response&g2.tab=0&g2.stacked=1&g2.range_input=1h&g3.expr=envoy_thrift_outbound_9090__thrift_sample_server_thrift_svc_cluster_local_response_success&g3.tab=0&g3.stacked=1&g3.range_input=1h&g4.expr=envoy_thrift_outbound_9090__thrift_sample_server_thrift_svc_cluster_local_request&g4.tab=0&g4.stacked=1&g4.range_input=1h)
* Istio meetup China(Chinese): [Full Stack Service Mesh - Manage Any Layer-7 Traffic in an Istio Service Mesh with Aeraki](https://www.youtube.com/watch?v=Bq5T3OR3iTM)
* IstioCon 2021: [How to Manage Any Layer-7 Traffic in an Istio Service Mesh?](https://www.youtube.com/watch?v=sBS4utF68d8)
