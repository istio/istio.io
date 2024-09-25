---
title: "The Istio Service Mesh for People Who Have Stuff to Do"
description: I recently made a contribution to Istio, an open-source service mesh that simplifies managing microservices. In this post, I explain how Istio handles traffic routing, security with mTLS, and observability, making complex systems more resilient and efficient.
publishdate: 2024-09-25
attribution: Luca Cavallin - GitHub
keywords: [istio]
target_release: 1.23
---

*Originally published at [lucavall.in](https://www.lucavall.in/blog/the-istio-service-mesh-for-people-who-have-stuff-to-do)*

I recently made a small contribution to **Istio**, an open-source service mesh
project. My contribution involved adding a few tests for one of the Istio CLI
commands. If you want to check out the details, you can find the pull request
[here](https://github.com/istio/istio/pull/51635). It wasn't a huge change, but it was a great learning experience. Working on
Istio helped me understand service meshes at a deeper level. I'm excited to
contribute more. In this post, I'll explain what Istio is, why it's useful, and
how it works.

## What is Istio?

At its core, Istio is a **service mesh**. A service mesh manages communication
between microservices, taking care of things like routing traffic, securing
communication, and providing observability. As your microservices grow in
number, managing these interactions can get complicated. Istio automates many of
these tasks, so you can focus on building your application instead of managing
service-to-service communication.

## Why Use Istio?

As your architecture becomes more complex, you'll face new challenges. Services
need to communicate in a reliable, secure, and efficient way. Istio helps you do
this in three key areas:

1. **Managing Traffic**: Istio gives you control over how traffic flows between
   services. You can split traffic between different versions of a service,
   reroute requests during deployments, or set up retry and timeout policies.

1. **Securing Communication**: Istio makes it easy to enable **mutual TLS
   (mTLS)**. This ensures that all communication between services is encrypted
   and authenticated, keeping unauthorized services out.

1. **Observability**: Istio automatically collects metrics, logs, and traces,
   giving you real-time visibility into your services. This helps with
   monitoring, troubleshooting, and performance tuning.

These three areas - traffic management, security, and observability - are key to
running a healthy microservices architecture, and Istio handles them with ease.

## Managing Traffic with Istio

One of Istio's main features is managing traffic between services. In a
microservices setup, you might have multiple versions of a service running at
the same time. For example, you might be testing a new version of your payment
service and want to send most of the traffic to version 1, but route some
traffic to version 2.

Here's an example of how you can use Istio to split traffic between two versions
of a service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: payments
spec:
  hosts:
  - payments.myapp.com
  http:
  - route:
    - destination:
        host: payments
        subset: v1
      weight: 90
    - destination:
        host: payments
        subset: v2
      weight: 10
{{< /text >}}

In this example:
- **90% of traffic** is sent to version 1 of the `payments` service, and **10%**
  is sent to version 2.
- The `hosts` field specifies the domain for which the virtual service is
  applicable - in this case, `payments.myapp.com`.
- The `route` block defines how traffic is split between two subsets of the
  service: `v1` (for version 1) and `v2` (for version 2). The `weight` field
  controls the traffic distribution.

This is useful for **canary deployments**, where you test new features with a
small percentage of users before rolling them out fully.

### Envoy Proxy and Sidecar Containers

Istio's **data plane** relies on the **Envoy proxy**, a layer 7 proxy that
manages all traffic between services. Every service in your mesh has its own
**sidecar proxy**, which sits next to the service and manages all its inbound
and outbound traffic.

Envoy allows you to apply traffic policies like retries, timeouts, and circuit
breaking, all without changing your application code. It also collects detailed
metrics about traffic flow, helping with monitoring and debugging.

Because Envoy runs as a **sidecar container**, it can enforce these rules and
collect data without interfering with your application's logic. In short, Envoy
acts as the "traffic cop" for all communication in your service mesh.

## Observability: Seeing What's Happening in Your System

Running a system with many microservices can make it hard to see what's going
on. Istio's built-in **observability** features help you track metrics, logs,
and traces for all communication between services. This is vital for monitoring
the health of your system, spotting performance issues, and fixing bugs.

Istio's observability tools give you a clear picture of how your system is
working. You can detect problems early and make your services run more smoothly.

## Security: Enabling mTLS and Access Control

Security is a big concern when managing microservices. Istio makes it easy to
implement **mutual TLS (mTLS)**, which encrypts all communication between
services and ensures that services authenticate each other before exchanging
data.

Istio also lets you set up **access control policies** to specify which services
are allowed to communicate. This helps limit which services can interact,
reducing your system's attack surface.

Here's an example of an Istio policy that allows only the `billing` service to
communicate with the `payments` service:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payments-to-billing
spec:
  selector:
    matchLabels:
      app: payments
  rules:
  - from:
    - source:
        principals: ["billing.myapp.com"]
{{< /text >}}

In this policy:

- The `selector` specifies that this rule applies to the `payments` service,
  using the label `app: payments`.
- The `rules` block allows only the `billing` service, identified by the
  principal `"billing.myapp.com"`, to communicate with `payments`. No other
  service is permitted to send traffic to `payments`.

This policy restricts all services except `billing` from accessing `payments`,
tightening the security of your microservices.

### What is SPIFFE?

Istio uses **SPIFFE** (Secure Production Identity Framework for Everyone) to
manage service identities. SPIFFE provides a way to assign secure, verifiable
identities to services. Each service in the mesh gets a **SPIFFE Verifiable
Identity Document (SVID)**, which is used along with mTLS to ensure secure
communication. This identity system is the foundation of Istio's security model.

## Networking in Istio

Networking in microservices can be difficult, especially when it comes to
controlling traffic inside and outside the mesh. Istio provides several tools
for managing network traffic:

1. **Service Entry**: Allows external services to communicate with services
   inside the mesh and the other way around.
1. **Virtual Service**: Defines how traffic is routed inside the mesh.
1. **Destination Rule**: Applies traffic policies, such as load balancing or
   mTLS, to the services.
1. **Gateways**: Manages traffic coming into and going out of the mesh.

### Example Configuration: Gateway, Service Entry, Virtual Service, and Destination Rule

Let's say you have an API server inside your mesh that receives traffic from the
internet via a load balancer. Here's how you can configure a **Gateway**,
**Service Entry**, **Virtual Service**, and **Destination Rule** to handle this
traffic.

#### Gateway Configuration

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.myapp.com"
{{< /text >}}

What is happening here? The **Gateway** listens on **port 80** for HTTP traffic
coming to the domain `api.myapp.com`. The `selector` field connects this Gateway
to the **Istio ingress gateway**, which handles inbound traffic to the mesh.

#### Service Entry Configuration

Let's say your API server needs to call an external authentication service.
Here's how you would configure a **Service Entry**:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: auth-service-entry
spec:
  hosts:
  - "auth.external-service.com"
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  endpoints:
  - address: 203.0.113.1
{{< /text >}}

What is happening here? The **Service Entry** tells Istio how to route traffic
to an external service (`auth.external-service.com`), which runs on **port 443**
(HTTPS). The `location: MESH_EXTERNAL` indicates that this service exists
outside the Istio service mesh. The `endpoints` field includes the external
service's IP address, allowing the API server inside the mesh to send requests.

#### Virtual Service Configuration

Here's how you can route traffic within the mesh:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: api-virtualservice
spec:
  hosts:
  - "api.myapp.com"
  gateways:
  - api-gateway
  http:
  - match:
    - uri:
        prefix: "/v1"
    route:
    - destination:
        host: api-service
        subset: stable
{{< /text >}}

What is happening here? The **Virtual Service** defines the traffic routing
rules. In this case, traffic arriving at `api.myapp.com/v1` through the
`api-gateway` is routed to the `api-service` in the mesh. The `subset: stable`
refers to a specific version of the `api-service` (you can have multiple
versions of the same service).

#### Destination Rule Configuration

Lastly, here's a **Destination Rule** to apply load balancing and mTLS:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: api-destination-rule
spec:
  host: api-service
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    tls:
      mode: ISTIO_MUTUAL
{{< /text >}}

What is happening here? The **Destination Rule** applies policies to the traffic
routed to the `api-service`. It uses **round-robin** load balancing to
distribute requests evenly across instances. **mTLS** is enabled with `tls.mode:
ISTIO_MUTUAL`, ensuring encrypted communication between services.

### Resiliency: Handling Failures with Retries, Timeouts, and Circuit Breakers

In distributed systems, failures happen. Services might go down, networks might
get slow, or users might experience delays. Istio helps you handle these
problems with **retries**, **timeouts**, and **circuit breakers**.

- **Retries**: Automatically retries failed requests to handle temporary
  failures without disrupting the user experience.
- **Timeouts**: Defines how long a service should wait for a response before
  giving up and moving on.
- **Circuit breakers**: If a service is failing, Istio can stop sending traffic
  to it, preventing cascading failures that might bring down other parts of the
  system.

Here's an example of how to configure retries and timeouts in Istio:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
  - my-service
  http:
  - route:
    - destination:
        host: my-service
    retries:
      attempts: 3
      perTryTimeout: 2s
    timeout: 5s
{{< /text >}}

What is happening here? If a request to `my-service` fails, Istio will retry the
request up to **3 times**. Each retry attempt has a **2-second limit**. The
total time allowed for a request is **5 seconds**. After this, Istio will stop
waiting for a response.

For circuit breaking, you can use a **Destination Rule** like this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-service
spec:
  host: my-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
    outlierDetection:
      consecutive5xxErrors: 2
      interval: 10s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
{{< /text >}}

What is happening here? If `my-service` returns **two consecutive 5xx errors**
within **10 seconds**, Istio will stop sending traffic to it. The service will
be ejected from the load balancing pool for **30 seconds** before being
reconsidered.

### Summary

Istio is a powerful tool that simplifies traffic management, security, and
observability for microservices. Contributing to Istio gave me insight into how
it helps solve some of the complex challenges that come with running distributed
systems.

If you're running a microservices architecture or planning to scale, Istio can
help you make your system more resilient and easier to manage. If you have any
questions or want to learn more about Istio, feel free to reach out - I'd be happy
to share what I've learned.
