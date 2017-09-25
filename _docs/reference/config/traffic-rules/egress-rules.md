---
title: Egress Rules
overview: Routing configuration for traffic exiting the service mesh

order: 40

layout: docs
type: markdown
---


<a name="istio.proxy.v1.config.EgressRule"></a>
### EgressRule
Egress rules describe the properties of a service outside Istio. When transparent proxying
is used, egress rules signify a white listed set of domains that microserves in the mesh
are allowed to access. A subset of routing rules and all destination policies can be applied
on the service targeted by an egress rule. The destination of an egress rule is allowed to
contain wildcards (e.g., *.foo.com). Currently, only HTTP-based services can be expressed
through the egress rule. If TLS origination from the sidecar is desired, the protocol
associated with the service port must be marked as HTTPS, and the service is expected to
be accessed over HTTP (e.g., http://gmail.com:443). The sidecar will automatically upgrade
the connection to TLS when initiating a connection with the external service.

For example, the following egress rule describes the set of services hosted under the *.foo.com domain


    kind: EgressRule
    metadata:
      name: foo-egress-rule
    spec:
      destination:
        service: *.foo.com
      ports:
        - port: 80
          protocol: http
        - port: 443
          protocol: https

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.EgressRule.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td><a href="/docs/reference/config/traffic-rules/routing-rules.html#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>REQUIRED: Hostname or a wildcard domain name associated with the external service. ONLY the "service" field of destination will be taken into consideration. Name, namespace, domain and labels are ignored. Routing rules and destination policies that refer to these external services must have identical specification for the destination as the corresponding egress rule. Wildcard domain specifications must conform to format allowed by Envoy's Virtual Host specification, such as “*.foo.com” or “*-bar.foo.com”. The character '*' in a domain specification indicates a non-empty string. Hence, a wildcard domain of form “*-bar.foo.com” will match “baz-bar.foo.com” but not “-bar.foo.com”.</td>
 </tr>
<a name="istio.proxy.v1.config.EgressRule.ports"></a>
 <tr>
  <td><code>ports[]</code></td>
  <td>repeated <a href="#istio.proxy.v1.config.EgressRule.Port">Port</a></td>
  <td>REQUIRED: list of ports on which the external service is available.</td>
 </tr>
<a name="istio.proxy.v1.config.EgressRule.useEgressProxy"></a>
 <tr>
  <td><code>useEgressProxy</code></td>
  <td>bool</td>
  <td><p>Forward all the external traffic through a dedicated egress proxy. It is used in some scenarios where there is a requirement that all the external traffic goes through special dedicated nodes/pods. These dedicated egress nodes could then be more closely monitored for security vulnerabilities.</p><p>The default is false, i.e. the sidecar forwards external traffic directly to the external service.</p></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.EgressRule.Port"></a>
#### Port
Port describes the properties of a specific TCP port of an external service.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.EgressRule.Port.port"></a>
 <tr>
  <td><code>port</code></td>
  <td>int32</td>
  <td>A valid non-negative integer port number.</td>
 </tr>
<a name="istio.proxy.v1.config.EgressRule.Port.protocol"></a>
 <tr>
  <td><code>protocol</code></td>
  <td>string</td>
  <td>The protocol to communicate with the external services. MUST BE one of HTTP|HTTPS|GRPC|HTTP2.</td>
 </tr>
</table>
