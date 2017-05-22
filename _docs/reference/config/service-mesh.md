---
title: Service Mesh
overview: Global configuration schema

order: 30

layout: docs
type: markdown
---


<a name="istio.proxy.v1.config.ProxyMeshConfig"></a>
### ProxyMeshConfig
ProxyMeshConfig defines variables shared by all Envoy instances in the
Istio service mesh.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.egressProxyAddress"></a>
 <tr>
  <td><code>egressProxyAddress</code></td>
  <td>string</td>
  <td>Address of the egress envoy service (e.g. <em>istio-egress:80</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.discoveryAddress"></a>
 <tr>
  <td><code>discoveryAddress</code></td>
  <td>string</td>
  <td>Address of the discovery service exposing SDS, CDS, RDS (e.g. <em>istio-manager:8080</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.mixerAddress"></a>
 <tr>
  <td><code>mixerAddress</code></td>
  <td>string</td>
  <td>Address of the mixer service (e.g. <em>istio-mixer:9090</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.zipkinAddress"></a>
 <tr>
  <td><code>zipkinAddress</code></td>
  <td>string</td>
  <td>Address of the Zipkin service (e.g. <em>zipkin:9411</em>).</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.proxyListenPort"></a>
 <tr>
  <td><code>proxyListenPort</code></td>
  <td>int32</td>
  <td>Port on which envoy should listen for incoming connections from other services.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.proxyAdminPort"></a>
 <tr>
  <td><code>proxyAdminPort</code></td>
  <td>int32</td>
  <td>Port on which envoy should listen for administrative commands.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.drainDuration"></a>
 <tr>
  <td><code>drainDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The time in seconds that Envoy will drain connections during a hot restart. MUST be &gt;=1s (e.g., <em>1s/1m/1h</em>)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.parentShutdownDuration"></a>
 <tr>
  <td><code>parentShutdownDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The time in seconds that Envoy will wait before shutting down the parent process during a hot restart. MUST be &gt;=1s (e.g., <em>1s/1m/1h</em>). MUST BE greater than <em>drainDuration</em> parameter.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.istioServiceCluster"></a>
 <tr>
  <td><code>istioServiceCluster</code></td>
  <td>string</td>
  <td><p>istioServiceCluster defines the name for the serviceCluster that is shared by all Envoy instances. This setting corresponds to <em>--service-cluster</em> flag in Envoy. In a typical Envoy deployment, the <em>service-cluster</em> flag is used to identify the caller, for source-based routing scenarios.</p><p>Since Istio does not assign a local service/service version to each Envoy instance, the name is same for all of them. However, the source/caller's identity (e.g., IP address) is encoded in the <em>--service-node</em> flag when launching Envoy. When the RDS service receives API calls from Envoy, it uses the value of the <em>service-node</em> flag to compute routes that are relative to the service instances located at that IP address.</p></td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.discoveryRefreshDelay"></a>
 <tr>
  <td><code>discoveryRefreshDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Polling interval for service discovery. (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.connectTimeout"></a>
 <tr>
  <td><code>connectTimeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Connection timeout used by Envoy. (MUST BE &gt;=1ms)</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.ingressClass"></a>
 <tr>
  <td><code>ingressClass</code></td>
  <td>string</td>
  <td>Class of ingress resources to be processed by Istio ingress controller. This corresponds to the value of "kubernetes.io/ingress.class" annotation.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.ingressService"></a>
 <tr>
  <td><code>ingressService</code></td>
  <td>string</td>
  <td>Name of the Kubernetes service used for the istio ingress controller.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.ingressControllerMode"></a>
 <tr>
  <td><code>ingressControllerMode</code></td>
  <td><a href="#istio.proxy.v1.config.ProxyMeshConfig.IngressControllerMode">IngressControllerMode</a></td>
  <td>Defines whether to use Istio ingress controller for annotated or all ingress resources.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.authPolicy"></a>
 <tr>
  <td><code>authPolicy</code></td>
  <td><a href="#istio.proxy.v1.config.ProxyMeshConfig.AuthPolicy">AuthPolicy</a></td>
  <td>Authentication policy defines the global switch to control authentication for Envoy-to-Envoy communication.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.authCertsPath"></a>
 <tr>
  <td><code>authCertsPath</code></td>
  <td>string</td>
  <td>Path to the secrets used by the authentication policy.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.ProxyMeshConfig.AuthPolicy"></a>
### AuthPolicy


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.AuthPolicy.NONE"></a>
 <tr>
  <td>NONE</td>
  <td>Do not encrypt Envoy to Envoy traffic.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.AuthPolicy.MUTUALTLS"></a>
 <tr>
  <td>MUTUALTLS</td>
  <td>Envoy to Envoy traffic is wrapped into mutual TLS connections.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.ProxyMeshConfig.IngressControllerMode"></a>
### IngressControllerMode


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.IngressControllerMode.OFF"></a>
 <tr>
  <td>OFF</td>
  <td>Disables Istio ingress controller.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.IngressControllerMode.DEFAULT"></a>
 <tr>
  <td>DEFAULT</td>
  <td>Istio ingress controller will act on ingress resources that do not contain any annotation or whose annotations match the value specified in the ingressClass parameter described earlier. Use this mode if Istio ingress controller will be the default ingress controller for the entire kubernetes cluster.</td>
 </tr>
<a name="istio.proxy.v1.config.ProxyMeshConfig.IngressControllerMode.STRICT"></a>
 <tr>
  <td>STRICT</td>
  <td>Istio ingress controller will only act on ingress resources whose annotations match the value specified in the ingressClass parameter described earlier. Use this mode if Istio ingress controller will be a secondary ingress controller (e.g., in addition to a cloud-provided ingress controller).</td>
 </tr>
</table>
