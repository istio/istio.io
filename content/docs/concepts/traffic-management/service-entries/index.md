---
title: Service Entries
description: Describes the architecture and behavior of service entries.
weight: 5
keywords: [external service, service registry, external traffic, egress, dependencies]
aliases:
---

A [service entry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry)
adds an entry to the service registry that Istio maintains internally. Most
commonly, you use a service entry to configure the [traffic routing](../traffic-routing)
rules for external dependencies of the mesh. For example, you can configure
[routing rules](../routing-rules) for APIs consumed from the web or traffic to
services in legacy infrastructure.

Adding a service to the internal registry is required to configure routing
rules to external services. You can enhance the configuration options of
service entries with [virtual services](../virtual-services) and
[destination rules](../destination-rules). Service entries are not limited to
external service configuration. A service entry can have one of two types:
mesh-internal or mesh-external:

-  **Mesh-internal service entries** explicitly add internal services to the
   Istio mesh. You can use mesh-internal service entries to add services as
   your service mesh expands to include unmanaged infrastructure. The unmanaged
   infrastructure can include components such as VMs added to a
   Kubernetes-based service mesh.

-  **Mesh-external service entries** explicitly add external services to the
   mesh. Mutual TLS authentication is disabled for mesh-external service
   entries. Istio performs policy enforcement on the client-side, instead of on
   the usual server-side used by internal service requests.

Mesh-external service entries provide the following configuration options:

-  You can configure multiple external dependencies with a single service
   entry.
-  You can configure the resolution mode for the external dependencies to
   `NONE`, `STATIC`, or `DNS`.
-  You can access secure external services over plain text ports to directly
   access external dependencies from your application.

The following example configuration shows a mesh-external service entry for the
`ext-resource` external dependency:

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
{{< /text >}}

You specify the destination of the service entry using the `hosts:` key. You
can qualify it fully or use a wildcard domain name. The value represents a
white listed set of one or more services outside the mesh that services in the
mesh are allowed to access. Depending on the situation, you don't need
anything other than a service entry to call an external service. Typically, you
use either a virtual service or destination rules to complete the
configuration. You configure a service entry similarly to how you configure a
service in the mesh. The following destination rule configures the traffic
route to use mutual TLS to connect to the `ext-resource` external service that
the service entry added to the mesh:

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
configure a route for the  HTTPS traffic to and from the `ext-resource`
external dependency through the `svc-entry` service entry on port 80 and using
mutual TLS. The following diagram shows the configured traffic routing rules:

{{< image width="50%"
    link="./service-entries.svg"
    caption="Configurable traffic routes using service entries and destination rules"
    >}}

Using this configuration model, you can specify routing rules to:

- Redirect and forward traffic for external destinations.

- Define [retry](../failures/#retries), [timeout](../failures/#timeouts), and
  [fault injection](../failures/#fault-injection) policies for external
  destinations.

Weighted version-based routing is not possible since there is no notion
of multiple versions of an external service.

Visit the [egress task](/docs/tasks/traffic-management/egress/) for more
details about accessing external services.

Visit our [service entries reference documentation](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry)
to review all the enabled keys and values.
