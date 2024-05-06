---
title: Debug connectivity issues with ztunnel
description: How to validate the node proxies have the correct configuration.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

This section describes some options for monitoring the ztunnel proxy configuration and datapath. This information can also help with some high level troubleshooting and in identifying information that would be useful to collect and provide in a bug report if there are any problems. Additional advanced monitoring of ztunnel internals and advanced troubleshooting is out of scope for this guide.

## Viewing ztunnel proxy state

The ztunnel proxy gets configuration and discovery information from the istiod {{< gloss >}}control plane{{< /gloss >}} via xDS APIs.

The `istioctl x ztunnel-config` command allows you to view discovered workloads as seen by a ztunnel proxy.

In the first example, you see all the workloads and control plane components that ztunnel is currently tracking, including information about the IP address and protocol to use when connecting to that component and whether there is a waypoint proxy associated with that workload.

{{< text bash >}}
$ istioctl x ztunnel-config workloads
NAMESPACE          POD NAME                                IP          NODE                  WAYPOINT PROTOCOL
default            bookinfo-gateway-istio-59dd7c96db-q9k6v 10.244.1.11 ambient-worker        None     TCP
default            details-v1-cf74bb974-5sqkp              10.244.1.5  ambient-worker        None     HBONE
default            notsleep-5c785bc478-zpg7j               10.244.2.7  ambient-worker2       None     HBONE
default            productpage-v1-87d54dd59-fn6vw          10.244.1.10 ambient-worker        None     HBONE
default            ratings-v1-7c4bbf97db-zvkdw             10.244.1.6  ambient-worker        None     HBONE
default            reviews-v1-5fd6d4f8f8-knbht             10.244.1.16 ambient-worker        None     HBONE
default            reviews-v2-6f9b55c5db-c94m2             10.244.1.17 ambient-worker        None     HBONE
default            reviews-v3-7d99fd7978-7rgtd             10.244.1.18 ambient-worker        None     HBONE
default            sleep-7656cf8794-r7zb9                  10.244.1.12 ambient-worker        None     HBONE
istio-system       istiod-7ff4959459-qcpvp                 10.244.2.5  ambient-worker2       None     TCP
istio-system       ztunnel-6hvcw                           10.244.1.4  ambient-worker        None     TCP
istio-system       ztunnel-mf476                           10.244.2.6  ambient-worker2       None     TCP
istio-system       ztunnel-vqzf9                           10.244.0.6  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-2sms2                10.244.0.3  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-5bf9c                10.244.0.2  ambient-control-plane None     TCP
local-path-storage local-path-provisioner-7577fdbbfb-pslg6 10.244.0.4  ambient-control-plane None     TCP

{{< /text >}}

The `ztunnel-config` command can be used to view the secrets holding the TLS certificates that the ztunnel proxy has received from the istiod control plane to use for mTLS.

{{< text bash >}}
$ istioctl x ztunnel-config certificates "$ZTUNNEL".istio-system
CERTIFICATE NAME                                              TYPE     STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/default/sa/bookinfo-details         Leaf     Available     true           c198d859ee51556d0eae13b331b0c259     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-details         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Leaf     Available     true           64c3828993c7df6f85a601a1615532cc     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Leaf     Available     true           720479815bf6d81a05df8a64f384ebb0     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Leaf     Available     true           285697fb2cf806852d3293298e300c86     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/sleep                    Leaf     Available     true           fa33bbb783553a1704866842586e4c0b     2024-05-05T09:25:49Z     2024-05-04T09:23:49Z
spiffe://cluster.local/ns/default/sa/sleep                    Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
{{< /text >}}

Using these commands, you can check that ztunnel proxies are  configured with all the expected workloads and TLS certificate. Additionally, missing information can be used for troubleshooting any networking errors.

You may use the `all` option to view all parts of the ztunnel-config with a single CLI command:

{{< text bash >}}
$ istioctl x ztunnel-config all -o json
{{< /text >}}

You can also view the raw configuration dump of a ztunnel proxy via a `curl` to an endpoint inside its pod:

{{< text bash >}}
$ kubectl debug -it $ZTUNNEL -n istio-system --image=curlimages/curl -- curl localhost:15000/config_dump
{{< /text >}}

## Viewing Istiod state for ztunnel xDS resources

Sometimes you may wish to view the state of ztunnel proxy config resources as maintained in the istiod control plane, in the format of the xDS API resources defined specially for ztunnel proxies. This can be done by exec-ing into the istiod pod and obtaining this information from port 15014 for a given ztunnel proxy as shown in the example below. This output can then also be saved and viewed with a JSON pretty print formatter utility for easier browsing (not shown in the example).

{{< text bash >}}
$ export ISTIOD=$(kubectl get pods -n istio-system -l app=istiod -o=jsonpath='{.items[0].metadata.name}')
$ kubectl debug -it $ISTIOD -n istio-system --image=curlimages/curl -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system
{{< /text >}}

## Verifying ztunnel traffic through logs

ztunnel's traffic logs can be queried using the standard Kubernetes log facilities.

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://productpage:9080/; done'
HTTP/1.1 200 OK
Server: Werkzeug/3.0.1 Python/3.12.1
--snip--
{{< /text >}}

The response displayed confirms the client pod receives responses from the service. You can now check logs of the ztunnel pods to confirm the traffic was sent over the HBONE tunnel.

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2024-05-04T09:59:05.028709Z info    access  connection complete src.addr=10.244.1.12:60059 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:9080 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="inbound" bytes_sent=175 bytes_recv=80 duration="1ms"
2024-05-04T09:59:05.028771Z info    access  connection complete src.addr=10.244.1.12:58508 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:15008 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="outbound" bytes_sent=80 bytes_recv=175 duration="1ms"
--snip--
{{< /text >}}

These log messages confirm the traffic was sent via the ztunnel proxy. Additional fine-grained monitoring can be done by checking logs on the specific ztunnel proxy instances that are on the same nodes as the source and destination pods of the traffic. If these logs are not seen, then a possibility is that [traffic redirection](/docs/ambient/architecture/traffic-redirection) may not be working correctly.

{{< tip >}}
Traffic always traverses the ztunnel pod, even when the source and destination of the traffic are on the same compute node.
{{< /tip >}}

### Verifying ztunnel load balancing

The ztunnel proxy automatically performs client-side load balancing if the destination is a service with multiple endpoints. No additional configuration is needed. The load balancing algorithm is an internally fixed L4 Round Robin algorithm that distributes traffic based on L4 connection state, and is not user configurable.

{{< tip >}}
If the destination is a service with multiple instances or pods and there is no waypoint associated with the destination service, then the source ztunnel performs L4 load balancing directly across these instances or service backends and then sends traffic via the remote ztunnel proxies associated with those backends. If the destination service is configured to use one or more waypoint proxies, then the source ztunnel proxy performs load balancing by distributing traffic across these waypoint proxies and sends traffic via the remote ztunnel proxies on the node hosting the waypoint proxy instances.
{{< /tip >}}

By calling a service with multiple backends, we can validate that client traffic is  balanced across the service replicas.

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://reviews:9080/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "outbound"
--snip--
2024-05-04T10:11:04.964851Z info    access  connection complete src.addr=10.244.1.12:35520 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.969578Z info    access  connection complete src.addr=10.244.1.12:35526 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.974720Z info    access  connection complete src.addr=10.244.1.12:35536 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.7:15008 dst.hbone_addr="10.244.1.7:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v1-5fd6d4f8f8-26j92" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.979462Z info    access  connection complete src.addr=10.244.1.12:35552 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.8:15008 dst.hbone_addr="10.244.1.8:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v2-6f9b55c5db-c2dtw" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
{{< /text >}}

This is a round robin load balancing algorithm and is separate from and independent of any load balancing algorithm that may be configured within a `VirtualService`'s `TrafficPolicy` field, since as discussed previously, all aspects of `VirtualService` API objects are instantiated on the Waypoint proxies and not the ztunnel proxies.

### Observability of ambient mode traffic

In addition to checking ztunnel logs and other monitoring options noted above, you can also use normal Istio monitoring and telemetry functions to monitor application traffic using the ambient data plane mode.

* [Prometheus installation](/docs/ops/integrations/prometheus/#installation)
* [Kiali installation](/docs/ops/integrations/kiali/#installation)
* [Istio metrics](/docs/reference/config/metrics/)
* [Querying Metrics from Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

If a service is only using the secure overlay provided by ztunnel, the Istio metrics reported will only be the L4 TCP metrics (namely `istio_tcp_sent_bytes_total`, `istio_tcp_received_bytes_total`, `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`). The full set of Istio and Envoy metrics will be reported if a waypoint proxy is used.
