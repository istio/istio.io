---
title: Service Mesh
overview: Global Configuration Schema

order: 15

layout: docs
type: markdown
---


<a name="rpcIstio.proxy.v1.configIndex"></a>
### Index

* [MeshConfig](#istio.proxy.v1.config.MeshConfig)
(message)
* [MeshConfig.AuthPolicy](#istio.proxy.v1.config.MeshConfig.AuthPolicy)
(enum)
* [MeshConfig.IngressControllerMode](#istio.proxy.v1.config.MeshConfig.IngressControllerMode)
(enum)
* [ProxyConfig](#istio.proxy.v1.config.ProxyConfig)
(message)

<a name="istio.proxy.v1.config.MeshConfig"></a>
### MeshConfig
MeshConfig defines mesh-wide variables shared by all Envoy instances in the
Istio service mesh.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.egressProxyAddress"></a>
 <tr>
  <td><code>egressProxyAddress</code></td>
  <td>string</td>
  <td>Address of the egress Envoy service (e.g. <em>istio-egress:80</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.mixerAddress"></a>
 <tr>
  <td><code>mixerAddress</code></td>
  <td>string</td>
  <td>Address of the mixer service (e.g. <em>istio-mixer:9090</em>). Empty value disables Mixer checks and telemetry.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.disablePolicyChecks"></a>
 <tr>
  <td><code>disablePolicyChecks</code></td>
  <td>bool</td>
  <td>Disable policy checks by the mixer service. Metrics will still be reported to the mixer for HTTP requests and TCP connections. Default is false, i.e. mixer policy check is enabled by default.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.proxyListenPort"></a>
 <tr>
  <td><code>proxyListenPort</code></td>
  <td>int32</td>
  <td>Port on which Envoy should listen for incoming connections from other services.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.proxyHttpPort"></a>
 <tr>
  <td><code>proxyHttpPort</code></td>
  <td>int32</td>
  <td>Port on which Envoy should listen for HTTP PROXY requests if set.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.connectTimeout"></a>
 <tr>
  <td><code>connectTimeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Connection timeout used by Envoy. (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.ingressClass"></a>
 <tr>
  <td><code>ingressClass</code></td>
  <td>string</td>
  <td>Class of ingress resources to be processed by Istio ingress controller. This corresponds to the value of "kubernetes.io/ingress.class" annotation.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.ingressService"></a>
 <tr>
  <td><code>ingressService</code></td>
  <td>string</td>
  <td>Name of the kubernetes service used for the istio ingress controller.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.ingressControllerMode"></a>
 <tr>
  <td><code>ingressControllerMode</code></td>
  <td><a href="#istio.proxy.v1.config.MeshConfig.IngressControllerMode">IngressControllerMode</a></td>
  <td>Defines whether to use Istio ingress controller for annotated or all ingress resources.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.authPolicy"></a>
 <tr>
  <td><code>authPolicy</code></td>
  <td><a href="#istio.proxy.v1.config.MeshConfig.AuthPolicy">AuthPolicy</a></td>
  <td>Authentication policy defines the global switch to control authentication for Envoy-to-Envoy communication.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.rdsRefreshDelay"></a>
 <tr>
  <td><code>rdsRefreshDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Polling interval for RDS (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.enableTracing"></a>
 <tr>
  <td><code>enableTracing</code></td>
  <td>bool</td>
  <td>Flag to control generation of trace spans and request IDs. Requires a trace span collector defined in the proxy configuration.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.accessLogFile"></a>
 <tr>
  <td><code>accessLogFile</code></td>
  <td>string</td>
  <td>File address for the proxy access log (e.g. /dev/stdout). Empty value disables access logging.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.defaultConfig"></a>
 <tr>
  <td><code>defaultConfig</code></td>
  <td><a href="#istio.proxy.v1.config.ProxyConfig">ProxyConfig</a></td>
  <td>Default proxy config used by the proxy injection mechanism operating in the mesh (e.g. Kubernetes admission controller) In case of Kubernetes, the proxy config is applied once during the injection process, and remain constant for the duration of the pod. The rest of the mesh config can be changed at runtime and config gets distributed dynamically.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.MeshConfig.AuthPolicy"></a>
### AuthPolicy


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.AuthPolicy.NONE"></a>
 <tr>
  <td>NONE</td>
  <td>Do not encrypt Envoy to Envoy traffic.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.AuthPolicy.MUTUALTLS"></a>
 <tr>
  <td>MUTUALTLS</td>
  <td>Envoy to Envoy traffic is wrapped into mutual TLS connections.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.MeshConfig.IngressControllerMode"></a>
### IngressControllerMode


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.IngressControllerMode.OFF"></a>
 <tr>
  <td>OFF</td>
  <td>Disables Istio ingress controller.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.IngressControllerMode.DEFAULT"></a>
 <tr>
  <td>DEFAULT</td>
  <td>Istio ingress controller will act on ingress resources that do not contain any annotation or whose annotations match the value specified in the ingressClass parameter described earlier. Use this mode if Istio ingress controller will be the default ingress controller for the entire kubernetes cluster.</td>
 </tr>
<a name="istio.proxy.v1.config.MeshConfig.IngressControllerMode.STRICT"></a>
 <tr>
  <td>STRICT</td>
  <td>Istio ingress controller will only act on ingress resources whose annotations match the value specified in the ingressClass parameter described earlier. Use this mode if Istio ingress controller will be a secondary ingress controller (e.g., in addition to a cloud-provided ingress controller).</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.ProxyConfig"></a>
### ProxyConfig
ProxyConfig defines variables for individual Envoy instances.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.configPath"></a>
 <tr>
  <td><code>configPath</code></td>
  <td>string</td>
  <td>Path to the generated configuration file directory. Proxy agent generates the actual configuration and stores it in this directory.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.binaryPath"></a>
 <tr>
  <td><code>binaryPath</code></td>
  <td>string</td>
  <td>Path to the proxy binary</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.serviceCluster"></a>
 <tr>
  <td><code>serviceCluster</code></td>
  <td>string</td>
  <td><p>Service cluster defines the name for the serviceCluster that is shared by all Envoy instances. This setting corresponds to <em>--service-cluster</em> flag in Envoy. In a typical Envoy deployment, the <em>service-cluster</em> flag is used to identify the caller, for source-based routing scenarios.</p><p>Since Istio does not assign a local service/service version to each Envoy instance, the name is same for all of them. However, the source/caller's identity (e.g., IP address) is encoded in the <em>--service-node</em> flag when launching Envoy. When the RDS service receives API calls from Envoy, it uses the value of the <em>service-node</em> flag to compute routes that are relative to the service instances located at that IP address.</p></td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.drainDuration"></a>
 <tr>
  <td><code>drainDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The time in seconds that Envoy will drain connections during a hot restart. MUST be &gt;=1s (e.g., <em>1s/1m/1h</em>)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.parentShutdownDuration"></a>
 <tr>
  <td><code>parentShutdownDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The time in seconds that Envoy will wait before shutting down the parent process during a hot restart. MUST be &gt;=1s (e.g., <em>1s/1m/1h</em>). MUST BE greater than <em>drainDuration</em> parameter.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.discoveryAddress"></a>
 <tr>
  <td><code>discoveryAddress</code></td>
  <td>string</td>
  <td>Address of the discovery service exposing xDS (e.g. <em>istio-pilot:8080</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.discoveryRefreshDelay"></a>
 <tr>
  <td><code>discoveryRefreshDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Polling interval for service discovery (used by EDS, CDS, LDS, but not RDS). (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.zipkinAddress"></a>
 <tr>
  <td><code>zipkinAddress</code></td>
  <td>string</td>
  <td>Address of the Zipkin service (e.g. <em>zipkin:9411</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.connectTimeout"></a>
 <tr>
  <td><code>connectTimeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Connection timeout used by Envoy for supporting services. (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.statsdUdpAddress"></a>
 <tr>
  <td><code>statsdUdpAddress</code></td>
  <td>string</td>
  <td>IP Address and Port of a statsd UDP listener (e.g. <em>10.75.241.127:9125</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.proxyAdminPort"></a>
 <tr>
  <td><code>proxyAdminPort</code></td>
  <td>int32</td>
  <td>Port on which Envoy should listen for administrative commands.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyConfig.availabilityZone"></a>
 <tr>
  <td><code>availabilityZone</code></td>
  <td>string</td>
  <td>The availability zone where this Envoy instance is running. When running Envoy as a sidecar in Kubernetes, this flag must be one of the availability zones assigned to a node using failure-domain.beta.kubernetes.io/zone annotation.</td>
 </tr>
</table>
