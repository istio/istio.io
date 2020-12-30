---
title: Expanding into New Frontiers - Smart DNS Proxying in Istio
subtitle: Use workload-local DNS resolution to simplify VM integration, multicluster, and more
description: Workload Local DNS resolution to simplify VM integration, multicluster, and more.
publishdate: 2020-11-12
attribution: "Shriram Rajagopalan (Tetrate.io) on behalf of Istio Networking WG"
keywords: [dns,sidecar,multicluster,vm,external services]
---

DNS resolution is a vital component of any application infrastructure
on Kubernetes. When your application code attempts to access another
service in the Kubernetes cluster or even a service on the internet,
it has to first lookup the IP address corresponding to the hostname of
the service, before initiating a connection to the service. This name
lookup process is often referred to as **service discovery**. In
Kubernetes, the cluster DNS server, be it `kube-dns` or CoreDNS,
resolves the service's hostname to a unique non-routable virtual IP (VIP),
if it is a service of type `clusterIP`. The `kube-proxy` on each node
maps this VIP to a set of pods of the service, and forwards the traffic
to one of them selected at random. When using a service mesh, the
sidecar works similarly to the `kube-proxy` as far as traffic forwarding
is concerned.

The following diagram depicts the role of DNS today:

{{< image width="75%"
    link="./role-of-dns-today.png"
    alt="Role of DNS in Istio, today"
    caption="Role of DNS in Istio, today"
>}}

## Problems posed by DNS

While the role of DNS within the service mesh may seem insignificant,
it has consistently stood in the way of expanding the mesh to VMs and
enabling seamless multicluster access.

### VM access to Kubernetes services

Consider the case of a VM with a sidecar. As shown in the illustration
below, applications on the VM look up the IP addresses of services
inside the Kubernetes cluster as they typically have no access to the
cluster's DNS server.

{{< image width="75%"
    link="./vm-dns-resolution-issues.png"
    alt="DNS resolution issues on VMs accessing Kubernetes services"
    caption="DNS resolution issues on VMs accessing Kubernetes services"
>}}

It is technically possible to use `kube-dns` as a name server on the VM if one is
willing to engage in some convoluted workarounds involving `dnsmasq` and
external exposure of `kube-dns` using `NodePort` services: assuming you
manage to convince your cluster administrator to do so. Even so, you are
opening the door to a host of [security
issues](https://blog.aquasec.com/dns-spoofing-kubernetes-clusters). At
the end of the day, these are point solutions that are typically out
of scope for those with limited organizational capability and domain
expertise.

### External TCP services without VIPs

It is not just the VMs in the mesh that suffer from the DNS issue. For
the sidecar to accurately distinguish traffic between two different
TCP services that are outside the mesh, the services must be on
different ports or they need to have a globally unique VIP, much like
the `clusterIP` assigned to Kubernetes services. But what if there is
no VIP? Cloud hosted services like hosted databases, typically do not
have a VIP. Instead, the provider's DNS server returns one of the
instance IPs that can then be directly accessed by the
application. For example, consider the two service entries below,
pointing to two different AWS RDS services:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: db1
  namespace: ns1
spec:
  hosts:
  - mysql-instance1.us-east-1.rds.amazonaws.com
  ports:
  - name: mysql
    number: 3306
    protocol: TCP
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: db2
  namespace: ns1
spec:
  hosts:
  - mysql-instance2.us-east-1.rds.amazonaws.com
  ports:
  - name: mysql
    number: 3306
    protocol: TCP
  resolution: DNS
{{< /text >}}

The sidecar has a single listener on `0.0.0.0:3306` that looks up the
IP address of `mysql-instance1.us-east1.rds.amazonaws.com` from public
DNS servers and forwards traffic to it. It cannot route traffic to
`db2` as it has no way of distinguishing whether traffic arriving at
`0.0.0.0:3306` is bound for `db1` or `db2`. The only way to accomplish
this is to set the resolution to `NONE` causing the sidecar to
_blindly forward any traffic_ on port `3306` to the original IP
requested by the application. This is akin to punching a hole in the
firewall allowing all traffic to port `3306` irrespective of the
destination IP. To get traffic flowing, you are now forced to
compromise on the security posture of your system.

### Resolving DNS for services in remote clusters

The DNS limitations of a multicluster mesh are well known. Services in
one cluster cannot lookup the IP addresses of services in other
clusters, without clunky workarounds such as creating stub services in
the caller namespace.

## Taking control of DNS

All in all, DNS has been a thorny issue in Istio for a while. It was
time to slay the beast. We (the Istio networking team) decided to
tackle the problem once and for all in a way that is completely
transparent to you, the end user. Our first attempt involved utilizing
Envoy's DNS proxy. It turned out to be very unreliable, and
disappointing overall due to the general lack of sophistication in
the c-ares DNS library used by Envoy. Determined to solve the
problem, we decided to implement the DNS proxy in the Istio sidecar
agent, written in Go. We were able to optimize the implementation to
handle all the scenarios that we wanted to tackle without compromising
on scale and stability. The Go DNS library we use is the same one
used by scalable DNS implementations such as CoreDNS, Consul,
Mesos, etc. It has been battle tested in production for scale and stability.

Starting with Istio 1.8, the Istio agent on the sidecar will ship with
a caching DNS proxy, programmed dynamically by Istiod. Istiod pushes
the hostname-to-IP-address mappings for all the services that the
application may access based on the Kubernetes services and service
entries in the cluster. DNS lookup queries from the application are
transparently intercepted and served by the Istio agent in the pod or
VM. If the query is for a service within the mesh, _irrespective of
the cluster that the service is in_, the agent responds directly to the
application. If not, it forwards the query to the upstream name
servers defined in `/etc/resolv.conf`. The following diagram depicts
the interactions that occur when an application tries to access a
service using its hostname.

{{< image width="75%"
    link="./dns-interception-in-istio.png"
    alt="Smart DNS proxying in Istio sidecar agent"
    caption="Smart DNS proxying in Istio sidecar agent"
>}}

As you will see in the following sections, _the DNS proxying feature
has had an enormous impact across many aspects of Istio._

### Reduced load on your DNS servers w/ faster resolution

The load on your cluster’s Kubernetes DNS server drops drastically as
almost all DNS queries are resolved within the pod by Istio. The
bigger the footprint of mesh on a cluster, the lesser the load on your
DNS servers. Implementing our own DNS proxy in the Istio agent has
allowed us to implement cool optimizations such as [CoreDNS
auto-path](https://coredns.io/plugins/autopath/) without the
correctness issues that CoreDNS currently faces.

To understand the impact of this optimization, lets take a simple DNS
lookup scenario, in a standard Kubernetes cluster without any custom
DNS setup for pods - i.e., with the default setting of `ndots:5` in `/etc/resolv.conf`.
When your application starts a DNS lookup for
`productpage.ns1.svc.cluster.local`, it appends the DNS search
namespaces in `/etc/resolv.conf` (e.g., `ns1.svc.cluster.local`) as part
of the DNS query, before querying the host as-is. As a result, the
first DNS query that is actually sent out will look like
`productpage.ns1.svc.cluster.local.ns1.svc.cluster.local`, which will
inevitably fail DNS resolution when Istio is not involved. If your
`/etc/resolv.conf` has 5 search namespaces, the application will send
two DNS queries for each search namespace, one for the IPv4 `A` record
and another for the IPv6 `AAAA` record, and then a final pair of
queries with the exact hostname used in the code. _Before establishing the
connection, the application performs 12 DNS lookup queries for each host!_

With Istio's implementation of the CoreDNS style auto-path technique,
the sidecar agent will detect the real hostname being queried within
the first query and return a `cname` record to
`productpage.ns1.svc.cluster.local` as part of this DNS response, as
well as the `A/AAAA` record for
`productpage.ns1.svc.cluster.local`. The application receiving this
response can now extract the IP address immediately and proceed to
establishing a TCP connection to that IP. _The smart DNS proxy in the
Istio agent dramatically cuts down the number of DNS queries from 12
to just 2!_

### VMs to Kubernetes integration

Since the Istio agent performs local DNS resolution for services
within the mesh, DNS lookup queries for Kubernetes services from VMs will now
succeed without requiring clunky workarounds for exposing `kube-dns`
outside the cluster. The ability to seamlessly resolve internal
services in a cluster will now simplify your monolith to microservice
journey, as the monolith on VMs can now access microservices on
Kubernetes without additional levels of indirection via API gateways.

### Automatic VIP allocation where possible

You may ask, how does this DNS functionality in the agent solve the
problem of distinguishing between multiple external TCP services
without VIPs on the same port?

Taking inspiration from Kubernetes, Istio will now automatically
allocate non-routable VIPs (from the Class E subnet) to such services
as long as they do not use a wildcard host. The Istio agent on the
sidecar will use the VIPs as responses to the DNS lookup queries from
the application. Envoy can now clearly distinguish traffic bound for
each external TCP service and forward it to the right target. With the
introduction of the DNS proxying, you will no longer need to use
`resolution: NONE` for non-wildcard TCP services, improving your
overall security posture. Istio cannot help much with wildcard
external services (e.g., `*.us-east1.rds.amazonaws.com`). You will
have to resort to NONE resolution mode to handle such services.

### Multicluster DNS lookup

For the adventurous lot, attempting to weave a multicluster mesh where
applications directly call internal services of a namespace in a
remote cluster, the DNS proxy functionality comes in quite handy. Your
applications can _resolve Kubernetes services on any cluster in any
namespace_, without the need to create stub Kubernetes services in
every cluster.

The benefits of the DNS proxy extend beyond the multicluster models
that are currently described in Istio today.  At Tetrate, we use this
mechanism extensively in our customers' multicluster deployments to
enable sidecars to resolve DNS for hosts exposed at ingress gateways
of all the clusters in a mesh, and access them over mutual TLS.

## Concluding thoughts

The problems caused by lack of control over DNS have often been
overlooked and ignored in its entirety when it comes to weaving a mesh
across many clusters, different environments, and integrating external
services. The introduction of a caching DNS proxy in the Istio sidecar
agent solves these issues. Exercising control over the
application’s DNS resolution allows Istio to accurately identify the
target service to which traffic is bound, and enhance the overall
security, routing, and telemetry posture in Istio within and across
clusters.

Smart DNS proxying is enabled in the `preview`
profile in Istio 1.8. Please try it out!
