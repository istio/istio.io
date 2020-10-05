---
title: New Frontiers - Smart DNS Proxying in Istio
subtitle: Workload Local DNS resolution to simplify VM integration, multicluster, and more
description: Workload Local DNS resolution to simplify VM integration, multicluster, and more.
publishdate: 2020-10-06
attribution: "Shriram Rajagopalan (Tetrate.io)"
keywords: [dns,sidecar,multicluster,vm,external services]
---

Service discovery within Istio, or any service mesh for that matter,
has predominantly hinged on DNS till date. By service discovery, I
mean the ability of a user application to map a human readable service
name to some IP address, to which traffic can be sent to from the
application. On the other hand, when the sidecar forwards the
application traffic, DNS is hardly used when it comes to services on
Kubernetes or Virtual Machines (VMs), as it knows the endpoint IPs of
pods or VMs that it wants to send the traffic to. The sidecars use DNS
for endpoint discovery only when the endpoints of the service are not
known beforehand. The following diagram depicts the role of DNS today,
in Istio.

{{< image width="75%"
    link="./role-of-dns-today.png"
    alt="Role of DNS in Istio, today"
    caption="Role of DNS in Istio, toda"
>}}

## Problems posed by DNS or lack of thereof

While the role of DNS within the service mesh may seem insignificant,
it has consistently stood in the way of expanding the mesh to VMs, and
enabling seamless multicluster access.

### VM to Kubernetes integration

Consider the case of a VM with a sidecar. As shown in the illustration
below, applications on the VM cannot communicate with services inside
the Kubernetes cluster as VM do not have a straightforward access to
the kube-dns.

{{< image width="75%"
    link="./vm-dns-resolution-issues.png"
    alt="DNS resolution issues on VMs accessing Kubernetes services"
    caption="DNS resolution issues on VMs accessing Kubernetes services"
>}}

It is technically possible to use `kube-dns` as a nameserver on the VM if one is
willing to engage in some convoluted workarounds involving dnsmasq and
external exposure of `kube-dns` using NodePort services, assuming you
manage to convince your cluster administrator to do so. Even so, you are
opening the door to a host of [security
issues](https://blog.aquasec.com/dns-spoofing-kubernetes-clusters). At
the end of the day, these are point solutions that are typically out
of scope for those with limited organizational capability and domain
expertise.

### External TCP Services without VIPs

It's not just the VMs in the mesh that suffer from the DNS issue. When
it comes to routing traffic for two TCP services on the same port, the
only way an external process like the proxy can distinguish the two
services is through the IP address. But what if the IP addresses
associated with these services are not known to the user beforehand,
as is usually the case with cloud hosted services like hosted
databases? For example, consider the two service entries below,
pointing to two different AWS RDS services:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: db1
  namespace: ns1
spec:
  hosts:
  - mysql–instance1.us-east-1.rds.amazonaws.com 
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
  - mysql–instance2.us-east-1.rds.amazonaws.com 
  ports:
  - name: mysql
    number: 3306
    protocol: TCP
  resolution: DNS
{{< /text >}}

When an application accesses the `db1` service, it resolves the DNS
address of `mysql–instance1.us-east-1.rds.amazonaws.com`
to some IP address that is dynamically decided by AWS. The sidecar has
no way to distinguish whether the intercepted traffic is bound for
`db1` or `db2`, as this is binary TCP traffic, unlike text-based HTTP
traffic. Without going into the technical implementation details, I
can guarantee you that in this scenario, unless the service entry's
resolution is `NONE`, the traffic for `db2` ends up being forwarded to
`db1`, the wrong database! In contrast, if these two databases were
Kubernetes services, the sidecar can uniquely identify the destination
service by matching the IP on the TCP connection with the cluster IP
or pod IPs of one of these services.

### Multicluster

The DNS limitations of a multicluster mesh are well known. Services in
one cluster cannot resolve the DNS names of services in other
clusters, without clunky workarounds such as creating stub services in
the caller namespace.

## Taking control of DNS

All in all, DNS has been a thorny issue in Istio for a while. It was
time to slay the beast. We decided to tackle the problem once and for
all in a way that is completely transparent to you, the end user. Our
first attempt involved utilizing Envoy's DNS proxy. It turned out to
be very unreliable, and disappointing overall due to the general lack
of sophistication in c-ares library, the DNS library used by
Envoy. Determined to solve the problem, we decided to implement the
DNS proxy in the Istio sidecar agent, written in Go. We built the DNS
functionality using Miek Gieben's [DNS
library](https://github.com/miekg/dns), the same package that is being
used by scalable DNS implementations such as CoreDNS, Consul, Mesos,
among others.

Starting with Istio 1.8, the Istio agent on the sidecar will ship with
a caching DNS proxy, programmed dynamically by Istiod. Istiod pushes
the hostname to IP address mappings for all the services that the
application may access based on the Kubernetes services and Service
Entries in the cluster. DNS traffic from the application is
transparently intercepted by the Istio agent. If the query is for a
service within the mesh, _irrespective of the cluster that service is
in_, the agent responds directly. If not, it forwards the query to the
upstream name servers defined in `/etc/resolv.conf`. The following
diagram depicts the interactions that occur when an application tries
to access a service using its hostname.

{{< image width="75%"
    link="./dns-interception-in-istio.png"
    alt="Smart DNS proxying in Istio sidecar agent"
    caption="Smart DNS proxying in Istio sidecar agent"
>}}

_The impact of this change has been enormous._

### Reduced load on your DNS servers w/ faster resolution

The load on your cluster’s Kubernetes DNS server drops drastically as
almost all DNS queries are resolved within the pod by Istio. The
bigger your mesh on a cluster, the lesser the load on your DNS
servers. Implementing our own DNS proxy in the Istio agent has allowed
us to implement cool optimizations such as CoreDNS’ autopath
(https://coredns.io/plugins/autopath/) without any of the limitations
that CoreDNS currently faces. 

For example, when your application attempts to resolve a query like
`productpage.ns1.svc.cluster.local`, it searches for this hostname
under the DNS search namespaces in /etc/resolv.conf (e.g.,
`ns1.svc.cluster.local`) before resolving the host as is. As a result,
the first DNS query that is actually sent out will look like
`productpage.ns1.svc.cluster.local.ns1.svc.cluster.local`, which will
inevitably fail DNS resolution. With Istio's implementation of the
CoreDNS style autopath technique, the sidecar agent would detect the
real hostname being queried and return a `cname` record to
`productpage.ns1.svc.cluster.local` as part of this DNS response, as
well as the `A/AAAA` record for
`productpage.ns1.svc.cluster.local`. The application receiving this
response can now extract the IP address immediately and proceed to
establishing a TCP connection to that IP. Compare this with the
existing behavior where the application futilely searches through all
the DNS search namespaces before sending the correct DNS query to the
DNS server. This powerful optimization dramatically cuts down the time
required to resolve a DNS query for a Kubernetes service within a pod,
and improves overall connection establishment latency.

### VMs to Kubernetes Integration

Applications on VMs with sidecars can directly address internal
services of any namespace in the Kubernetes cluster, giving them the
same comforts as applications on running Kubernetes pods.

### Automatic VIP allocation

You may ask, how does this DNS in the agent solve the problem of
distinguishing between multiple external TCP services on the same
port, described earlier? 

_The key observation here is that the IP address resolved by the
application for a given hostname does not have to be the same as the
IP address resolved by the sidecar for the same hostname._

The application needs to resolve the hostname to some IP
address, which then allows it to proceed to the next stage: create a
TCP connection to that IP. The Envoy process in the sidecar container
that intercepts this TCP connection needs to be able to map the
destination IP in the connection to some TCP proxy listener (where
each TCP proxy listener is associated with a specific VIP). Once it
has identified the listener, the traffic will be forwarded independent
of the destination IP - i.e. Envoy will resolve the DNS again and use
the resulting endpoint as the target. _The IP used by the application
does not need to be the same as the IP used by the Envoy. It just
needs to be something that Envoy can map to a listener._ It does not
even have to be a real IP! For example, consider the two AWS RDS service entries
described earlier, with a small modification:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: db1
  namespace: ns1
spec:
  hosts:
  - mysql–instance1.us-east-1.rds.amazonaws.com 
  addresses:
  - 1.1.1.1 # or any randomly allocated unreachable IP!
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
  - mysql–instance2.us-east-1.rds.amazonaws.com 
  addresses:
  - 2.2.2.2 # or any randomly allocated unreachable IP!
  ports:
  - name: mysql
    number: 3306
    protocol: TCP
  resolution: DNS
{{< /text >}}

The `db1` service entry is logically equivalent to a Kubernetes
service that has a cluster IP of `1.1.1.1`, whose endpoints need to be
resolved using DNS again. When the agent sees a DNS query from the
application for the hostname
`mysql-instance1.us-east-1.rds.amazonaws.com`, it will resolve the
query to the IP address `1.1.1.1`. Istio programs Envoy appropriately
so that when it sees traffic for `1.1.1.1:3306`, it will know that
this traffic is bound for the `db1` service. When forwarding the
traffic, Envoy will do a DNS resolution again for
`mysql–instance1.us-east-1.rds.amazonaws.com`, using the name servers
configured in `/etc/resolv.conf` to determine the real IP address on
AWS and then forward the SQL queries to it.

We have implemented mechanisms to auto allocate such dummy IP
addresses from the reserved _Class E_ subnet, so that you don't have
to come up with these values, when creating service entries with
`resolution: DNS`. Thus, the problematic service entry example with
two RDS instances will now work out of the box, with the traffic being
sent to the right service, while still getting you rich telemetry data
for each service.

### Multicluster

For the adventurous lot, attempting to weave a multicluster mesh where
applications directly call internal services of a namespace in a
remote cluster, the DNS proxy functionality comes in quite handy. Your
applications can _resolve Kubernetes services on any cluster in any
namespace_, without the need to create stub Kubernetes services all
over the system.

The benefits of the DNS proxy extend beyond the multicluster models
that are currently described in Istio today.  At Tetrate, we use this
mechanism extensively in our customer deployments to enable sidecars
to resolve DNS for hosts exposed at ingress gateways of all the
clusters in a mesh.

## Concluding thoughts

The problems caused by lack of control over DNS have often been
overlooked and ignored in its entirety when it comes to weaving a mesh
across many clusters, different environments, and integrating external
services. With the introduction of a caching DNS proxy in the Istio
sidecar agent, we hope to remediate. Exercising control over the
application’s DNS resolution allows us to accurately identify the
target service for which traffic is bound to, and enhance the overall
routing and telemetry posture in Istio, within and across clusters.
