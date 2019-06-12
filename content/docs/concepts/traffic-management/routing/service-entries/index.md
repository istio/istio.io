---
title: Service Entries
description: Learn about using a service entry to add an entry to Istio's abstract model that configures routing rules for external dependencies of the mesh.
weight: 4
keywords: [traffic-management, http, tcp, grpc, ingress, egress]
---

A [service entry](/docs/reference/config/networking/v1alpha3/service-entry)
is a network resource used to add an entry to Istio's abstract model, or
service registry, that Istio maintains internally. Once added, the Envoy
proxies can send traffic to the external service as if it was a service in your
mesh. You can configure service entries to configure routing rules to:

-  Redirect and forward traffic for external destinations, such as APIs
   consumed from the web, or traffic to services in legacy infrastructure.

-  Define
   [retry](/docs/concepts/traffic-management/network/#timeouts-and-retries),
   [timeout](/docs/concepts/traffic-management/network/#timeouts-and-retries),
   and [fault injection](/docs/concepts/traffic-management/network/#fault-injection)
   policies for external destinations.

- Add a service running in a Virtual Machine to the mesh to [expand your mesh](/docs/setup/kubernetes/additional-setup/mesh-expansion/#running-services-on-a-mesh-expansion-machine).

- Logically add services from a different cluster to the mesh to configure a
  [multicluster Istio mesh](/docs/tasks/multicluster/gateways/#configure-the-example-services)
  on Kubernetes.

You don’t need to add a service entry for every mesh-external service that you
want your mesh services to use. By default, Istio configures the Envoy proxies
to passthrough requests from unknown services. You can also use service entries
to configure internal infrastructure:

-  A **mesh-internal** service entry adds a service running in unmanaged
   infrastructure, which does not have an Envoy proxy, but still is within the
   same network, to the mesh. You configure mesh-internal service entries as
   you expand the mesh to include unmanaged infrastructure.

    For example, you create mesh-internal service entries for the services
    running on VMs outside the Kubernetes cluster but within the network.
    Mutual TLS authentication (mTLS) is enabled by default for mesh-internal
    service entries, but to change the authentication method, you can configure
    a destination rule for the service entry.

-  A **mesh-external** service entry adds a service running on infrastructure
   outside the network of the mesh. You configure a mesh-external service entry
   so that a service inside the mesh can make API calls to an external server.
   When you add a mesh external service entry, you don't need to configure an
   egress gateway.

    mTLS is disabled by default for mesh-external service entries, but you can
    change the authentication method by configuring a destination rule for the
    service entry. Because the destination is external to the mesh, the Envoy
    proxies of the services inside the mesh enforce the configured policies for
    services added through mesh-external service entries.

You can use mesh-external service entries to perform the following
configurations:

-  Configure multiple external dependencies with a single service entry.

-  Configure the resolution mode for the external dependencies to `NONE`,
   `STATIC`, or `DNS`.

-  Access secure external services over plain text ports to directly access
   external dependencies from your application.

## Add an external dependency securely

The following example mesh-external service entry adds the ext-resource
external dependency to Istio's service registry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-resource.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

You must specify the external resource using the `hosts:` key. You can qualify
it fully or use a wildcard domain name. The value represents the set of one or
more services outside the mesh that services in the mesh can access.

Configuring a service entry can be enough to call an external service, but
typically you configure either, or both, a virtual service or destination rules to control
traffic more granularly. You can configure traffic for a service entry in the
same way you configure traffic for a service in the mesh.

### Secure the connection with mTLS

The following destination rule configures the traffic route to use mutual TLS
(mTLS) to secure the connection to the `ext-resource` external service we
configured using the service entry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-resource.com
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

Together, the `svc-entry` service entry and the `ext-res-dr` destination rule
configure a route for the HTTPS traffic to and from the `ext-resource` external
dependency through the `svc-entry` service entry on port 80 using mTLS. The
following diagram shows the configured traffic routing rules:

{{< image width="40%"
    link="./service-entries-1.svg"
    caption="Configurable traffic routes using service entries and destination rules"
    >}}

Visit the [service entries reference documentation](/docs/reference/config/networking/v1alpha3/service-entry)
to review all the enabled keys and values.
