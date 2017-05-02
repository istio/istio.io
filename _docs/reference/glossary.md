---
title: Glossary
overview: A glossary of common Istio terms.

order: 40

layout: docs
type: markdown
---

<!-- Ideas for words to add to the glossary

Service instance

RouteRule - destination, MatchCondition, 0..N DestinationWeights, precedence

ProxyMeshConfig -- nothing

Load balancing policy -- ROUND_ROBIN|LEAST_CONN|RANDOM|Any

Circuit breaker policy -- Currently a bunch of threshold parameters, with a work item to support all Envoy capabilities

Timeout policy -- seconds (a double), plus a feature to let downstream service specify via a header (!?!), plus "custom"

Retry policy -- # of attempts, plus a feature to let downstream service specify via a header (!?!), plus "custom"

L7 fault injection policy -- Delay fault, Abort fault, plus some tags to trigger them on specific header patterns

L4 fault injection policy -- bandwidth Throttle, TCP terminate connection

MatchCondition -- source, (source) tags, TCP L4MatchAttributes, UDP L4MatchAttributes, "Set of HTTP match conditions"

DestinationWeight -- fully-qualified destination, tags, and weight (the sum of weights "across destination" should add up to 100). (Or do we mean RFC 2119 style "SHOULD" for "should)?

L4MatchAttributes just 0..N source and destination subnet strings, of the forms a.b.c.d and a.b.c.d/xx

HTTP match conditions -- This seems to be HTTP and gRPC headers ... the examples given are "uri", "scheme", "authority", and we
match them case-insensitive, and using exact|prefix|regexp format

Delay fault -- fixed or exponential delay. Fixed has a duration plus a % of requests to delay. Exponential has a "mean" (that I don't understand)

Abort fault -- A type plus % of requests to abort. The types are only HTTP, HTTP/2, gRPC. No TCP resets or TLS (?!?)

Upstream

CDS Cluster Discovery Service -- See https://lyft.github.io/envoy/docs/configuration/cluster_manager/cds.html?highlight=cds#cluster-discovery-service

SDS Service Discovery Service -- See https://lyft.github.io/envoy/docs/intro/arch_overview/service_discovery.html#arch-overview-service-discovery-sds

RDS Route Discovery Service -- See https://lyft.github.io/envoy/docs/configuration/http_conn_man/rds.html#route-discovery-service

-->

# Glossary

- **Destination**.
The remote upstream service to which the proxy/sidecar is
talking to, on behalf of the source service. There can be one or more
service versions for a given service and
the proxy would choose the version based on routing rules.

- **Envoy**.
Envoy is the high-performance proxy that Istio uses to mediate all inbound and outbound traffic for all services in the service mesh. 
Learn more about Envoy [here](https://lyft.github.io/envoy/).

- **Istio-Auth**.
Istio-Auth provides strong service-to-service and end-user authentication using mutual TLS, with built-in identity and
credential management. Learn more about Istio-Auth *TBD*.
                    
- **Istio-Manager**.
Istio-Manager serves as an interface between the user and Istio, collecting and validating configuration and propagating it to the
various Istio components. It abstracts environment-specific implementation details from Mixer and Envoy, providing them with an
abstract representation of the user’s services 
that is independent of the underlying platform.
                    
- **Mixer**.
Mixer is an Istio component responsible for enforcing access control and usage policies across the service mesh and collecting telemetry data
from the Envoy proxy and other services. Learn more about Mixer [here](/docs/concepts/policy-and-control/mixer.html).

- **Service**.
A unit of an application with a unique name that other services
use to refer to the functionality being called. Service instances are
pods/VMs/containers that implement the service.

- **Service Consumer**.
The agent that is using a service.

- **Service Mesh**.
A collection of services interconnected through Istio's fleet of proxies.

- **Service Operator**.
The agent that deploys and manages a service by manipulating configuration state and
monitoring health via a variety of dashboards.

- **Service Producer**.
The agent that creates a service by writing source code.

- **Service Versions**.
In a continuous deployment scenario, for a given service,
there can be multiple sets of instances running potentially different
variants of the application binary or config. These variants are not necessarily
different API versions. They could be iterative changes to the same service,
deployed in different environments (prod, staging, dev, etc.). Common
scenarios where this occurs include A/B testing, canary rollouts, etc. The
choice of a particular version can be decided based on various criterion
(headers, url, etc.) and/or by weights assigned to each version.  Each
service has a default version consisting of all its instances.

- **Source**.
Downstream client (browser or another service) calling the
proxy/sidecar (typically to reach another service).
