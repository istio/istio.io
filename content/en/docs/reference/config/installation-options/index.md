---
title: Installation Options	
description: Describes the options available when installing Istio using the included Helm chart.	
weight: 30	
keywords: [kubernetes,helm]	
force_inline_toc: true	
---

{{< warning >}}
Installing Istio with Helm is in the process of deprecation, however, you can use these Helm
configuration options when [installing Istio with {{< istioctl >}}](/docs/setup/install/istioctl/)
by prepending the string "`values.`" to the option name. For example, instead of this `helm` command:

{{< text bash >}}	
$ helm template ... --set global.mtls.enabled=true	
{{< /text >}}	

You can use this `istioctl` command:	

{{< text bash >}}	
$ istioctl manifest generate ... --set values.global.mtls.enabled=true	
{{< /text >}}	

Refer to [customizing the configuration](/docs/setup/install/istioctl/#customizing-the-configuration) for details.	
{{< /warning >}}	

{{< tip >}}	
Refer to [Installation Options Changes](/news/2019/announcing-1.3/helm-changes/)	
for a detailed summary of the option changes between release 1.2 and release 1.3.	
{{< /tip >}}	

<!-- Run `make update_helm_table` to generate this table -->	

<!-- AUTO-GENERATED-START -->
## `certmanager` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>certmanager.enabled</td>
                <td>false</td>
                <td> Certmanager uses ACME to sign certificates. Since Istio gateways are
 mounting the TLS secrets the Certificate CRDs must be created in the
 istio-system namespace. Once the certificate has been created, the
 gateway must be updated by adding 'secretVolumes'. After the gateway
 restart, DestinationRules can be created using the ACME-signed certificates.
</td>
            </tr>

            <tr>
                <td>certmanager.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>certmanager.hub</td>
                <td>quay.io/jetstack</td>
                <td></td>
            </tr>

            <tr>
                <td>certmanager.image</td>
                <td>cert-manager-controller</td>
                <td></td>
            </tr>

            <tr>
                <td>certmanager.tag</td>
                <td>v0.8.1</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `galley` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>galley.enabled</td>
                <td>true</td>
                <td>
 galley configuration

</td>
            </tr>

            <tr>
                <td>galley.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.image</td>
                <td>galley</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.enableServiceDiscovery</td>
                <td>false</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>galley.enableAnalysis</td>
                <td>false</td>
                <td>
 Enable service discovery processing in Galley
</td>
            </tr>

    </tbody>
</table>

## `gateways` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>gateways.enabled</td>
                <td>true</td>
                <td>
 Gateways Configuration
 By default (if enabled) a pair of Ingress and Egress Gateways will be created for the mesh.
 You can add more gateways in addition to the defaults but make sure those are uniquely named
 and that NodePorts are not conflicting.
 Disable specifc gateway by setting the `enabled` to false.

</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.enabled</td>
                <td>true</td>
                <td>

</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.enabled</td>
                <td>false</td>
                <td>
  #
  # Secret Discovery Service (SDS) configuration for ingress gateway.
  #
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.image</td>
                <td>node-agent-k8s</td>
                <td> If true, ingress gateway fetches credentials from SDS server to handle TLS connections.
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.resources.requests.cpu</td>
                <td>100m</td>
                <td>
    # SDS server that watches kubernetes secrets and provisions credentials to ingress gateway.
    # This server runs in the same pod as ingress gateway.
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.resources.requests.memory</td>
                <td>128Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.resources.limits.cpu</td>
                <td>2000m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.resources.limits.memory</td>
                <td>1024Mi</td>
                <td>

</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.labels.app</td>
                <td>istio-ingressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.labels.istio</td>
                <td>ingressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.autoscaleEnabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.autoscaleMax</td>
                <td>5</td>
                <td>
  # specify replicaCount when autoscaleEnabled: false
  # replicaCount: 1
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.resources.requests.cpu</td>
                <td>100m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.resources.requests.memory</td>
                <td>128Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.resources.limits.cpu</td>
                <td>2000m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.resources.limits.memory</td>
                <td>1024Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.loadBalancerIP</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.type</td>
                <td>LoadBalancer</td>
                <td>change to NodePort, ClusterIP or LoadBalancer if need be
  #externalTrafficPolicy: Local #change to Local to preserve source IP or Cluster for default behaviour or leave commented out
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports.port</td>
                <td>15020</td>
                <td> You can add custom gateway ports
 Note that AWS ELB will by default perform health checks on the first port
 on this list. Setting this to the health check port will ensure that health
 checks always work. https://github.com/istio/istio/issues/12503
</td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports.targetPort</td>
                <td>15020</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports.name</td>
                <td>status-port</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.port</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.targetPort</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.name</td>
                <td>http2</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.nodePort</td>
                <td>31380</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.port</td>
                <td>443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.name</td>
                <td>https</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.nodePort</td>
                <td>31390</td>
                <td>
  # Example of a port to add. Remove if not needed
</td>
            </tr>

            <tr>
                <td>port</td>
                <td>31400</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp</td>
                <td></td>
            </tr>

            <tr>
                <td>nodePort</td>
                <td>31400</td>
                <td>
  ### PORTS FOR UI/metrics #####
  ## Disable if not needed
</td>
            </tr>

            <tr>
                <td>port</td>
                <td>15029</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15029</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>https-kiali</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>15030</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15030</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>https-prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>15031</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15031</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>https-grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>15032</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15032</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>https-tracing</td>
                <td>
    # This is the port where sni routing happens
</td>
            </tr>

            <tr>
                <td>port</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tls</td>
                <td>
  #### MESH EXPANSION PORTS  ########
  # Pilot and Citadel MTLS ports are enabled in gateway - but will only redirect
  # to pilot/citadel if global.meshExpansion settings are enabled.
  # Delete these ports if mesh expansion is not enabled, to avoid
  # exposing unnecessary ports on the web.
  # You can remove these ports if you are not using mesh expansion
</td>
            </tr>

            <tr>
                <td>meshExpansionPorts.port</td>
                <td>15011</td>
                <td></td>
            </tr>

            <tr>
                <td>meshExpansionPorts.targetPort</td>
                <td>15011</td>
                <td></td>
            </tr>

            <tr>
                <td>meshExpansionPorts.name</td>
                <td>tcp-pilot-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>15004</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15004</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp-mixer-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp-citadel-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>853</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>853</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp-dns-tls</td>
                <td>
  ####### end MESH EXPANSION PORTS ######
  ##############
</td>
            </tr>

            <tr>
                <td>secretVolumes.name</td>
                <td>ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.secretName</td>
                <td>istio-ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.mountPath</td>
                <td>/etc/istio/ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>ingressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretName</td>
                <td>istio-ingressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>mountPath</td>
                <td>/etc/istio/ingressgateway-ca-certs</td>
                <td>
  ### Advanced options ############

  # Ports to explicitly check for readiness. If configured, the readiness check will expect a
  # listener on these ports. A comma separated list is expected, such as "80,443".
  #
  # Warning: If you do not have a gateway configured for the ports provided, this check will always
  # fail. This is intended for use cases where you always expect to have a listener on the port,
  # such as 80 or 443 in typical setups.
</td>
            </tr>

            <tr>
                <td>applicationPorts</td>
                <td></td>
                <td>

</td>
            </tr>

            <tr>
                <td>env.ISTIO_META_ROUTER_MODE</td>
                <td>sni-dnat</td>
                <td> A gateway with this mode ensures that pilot generates an additional
 set of clusters for internal services but without Istio mTLS, to
 enable cross cluster routing.
</td>
            </tr>

            <tr>
                <td>istio-egressgateway.enabled</td>
                <td>false</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>istio-egressgateway.labels.app</td>
                <td>istio-egressgateway</td>
                <td>
</td>
            </tr>

            <tr>
                <td>istio-egressgateway.labels.istio</td>
                <td>egressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.autoscaleEnabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.autoscaleMax</td>
                <td>5</td>
                <td>
  # specify replicaCount when autoscaleEnabled: false
  # replicaCount: 1
</td>
            </tr>

            <tr>
                <td>istio-egressgateway.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.resources.requests.cpu</td>
                <td>100m</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.resources.requests.memory</td>
                <td>128Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.resources.limits.cpu</td>
                <td>2000m</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.resources.limits.memory</td>
                <td>1024Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.type</td>
                <td>ClusterIP</td>
                <td>change to NodePort or LoadBalancer if need be
</td>
            </tr>

            <tr>
                <td>istio-egressgateway.ports.port</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.ports.name</td>
                <td>http2</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.port</td>
                <td>443</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-egressgateway.name</td>
                <td>https</td>
                <td>
    # This is the port where sni routing happens
</td>
            </tr>

            <tr>
                <td>port</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tls</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.name</td>
                <td>egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.secretName</td>
                <td>istio-egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.mountPath</td>
                <td>/etc/istio/egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>egressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretName</td>
                <td>istio-egressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>mountPath</td>
                <td>/etc/istio/egressgateway-ca-certs</td>
                <td>
  #### Advanced options ########
</td>
            </tr>

            <tr>
                <td>env.ISTIO_META_ROUTER_MODE</td>
                <td>sni-dnat</td>
                <td> Set this to "external" if and only if you want the egress gateway to
 act as a transparent SNI gateway that routes mTLS/TLS traffic to
 external services defined using service entries, where the service
 entry has resolution set to DNS, has one or more endpoints with
 network field set to "external". By default its set to "" so that
 the egress gateway sees the same set of endpoints as the sidecars
 preserving backward compatibility
 ISTIO_META_REQUESTED_NETWORK_VIEW: ""
 A gateway with this mode ensures that pilot generates an additional
 set of clusters for internal services but without Istio mTLS, to
 enable cross cluster routing.
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.enabled</td>
                <td>false</td>
                <td> Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.labels.app</td>
                <td>istio-ilbgateway</td>
                <td>
 Mesh ILB gateway creates a gateway of type InternalLoadBalancer,
 for mesh expansion. It exposes the mtls ports for Pilot,CA as well
 as non-mtls ports to support upgrades and gradual transition.
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.labels.istio</td>
                <td>ilbgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.autoscaleEnabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.autoscaleMax</td>
                <td>5</td>
                <td>
  # specify replicaCount when autoscaleEnabled: false
  # replicaCount: 1
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.resources.requests.cpu</td>
                <td>800m</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.resources.requests.memory</td>
                <td>512Mi</td>
                <td>
    #limits:
    #  cpu: 1800m
    #  memory: 256Mi
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.loadBalancerIP</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.serviceAnnotations.cloud.google.com/load-balancer-type</td>
                <td>internal</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.type</td>
                <td>LoadBalancer</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.ports.port</td>
                <td>15011</td>
                <td> You can add custom gateway ports - google ILB default quota is 5 ports,
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.ports.name</td>
                <td>grpc-pilot-mtls</td>
                <td>
  # Insecure port - only for migration from 0.8. Will be removed in 1.1
</td>
            </tr>

            <tr>
                <td>istio-ilbgateway.port</td>
                <td>15010</td>
                <td></td>
            </tr>

            <tr>
                <td>istio-ilbgateway.name</td>
                <td>grpc-pilot</td>
                <td></td>
            </tr>

            <tr>
                <td>port</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>targetPort</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp-citadel-grpc-tls</td>
                <td>
  # Port 5353 is forwarded to kube-dns
</td>
            </tr>

            <tr>
                <td>port</td>
                <td>5353</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>tcp-dns</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.name</td>
                <td>ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.secretName</td>
                <td>istio-ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretVolumes.mountPath</td>
                <td>/etc/istio/ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>name</td>
                <td>ilbgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>secretName</td>
                <td>istio-ilbgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>mountPath</td>
                <td>/etc/istio/ilbgateway-ca-certs</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `global` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>gateways.enabled</td>
                <td>true</td>
                <td> Top level istio values file has the following sections.

 global: This file is the authoritative and exhaustive source for the global section.

 chart sections: Every subdirectory inside the charts/ directory has a top level
       configuration key in this file. This file overrides the values specified
       by the charts/${chartname}/values.yaml.
       Check the chart level values file for exhaustive list of configuration options.


 Gateways Configuration, refer to the charts/gateways/values.yaml
 for detailed configuration

</td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.enabled</td>
                <td>true</td>
                <td>

#
# sidecar-injector webhook configuration, refer to the
# charts/sidecarInjectorWebhook/values.yaml for detailed configuration
#
</td>
            </tr>

            <tr>
                <td>galley.enabled</td>
                <td>true</td>
                <td>

#
# galley configuration, refer to charts/galley/values.yaml
# for detailed configuration
#
</td>
            </tr>

            <tr>
                <td>mixer.policy.enabled</td>
                <td>true</td>
                <td>

#
# mixer configuration
#
# @see charts/mixer/values.yaml for all values
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.enabled</td>
                <td>true</td>
                <td> if policy is enabled the global.disablePolicyChecks has affect.
</td>
            </tr>

            <tr>
                <td>pilot.enabled</td>
                <td>true</td>
                <td>

</td>
            </tr>

            <tr>
                <td>security.enabled</td>
                <td>true</td>
                <td>
#
# pilot configuration
#
# @see charts/pilot/values.yaml
</td>
            </tr>

            <tr>
                <td>nodeagent.enabled</td>
                <td>false</td>
                <td>

#
# security configuration
#
</td>
            </tr>

            <tr>
                <td>grafana.enabled</td>
                <td>false</td>
                <td>

#
# nodeagent configuration
#
</td>
            </tr>

            <tr>
                <td>prometheus.enabled</td>
                <td>true</td>
                <td>

#
# addon grafana configuration
#
</td>
            </tr>

            <tr>
                <td>tracing.enabled</td>
                <td>false</td>
                <td>

#
# addon prometheus configuration
#
</td>
            </tr>

            <tr>
                <td>kiali.enabled</td>
                <td>false</td>
                <td>

#
# addon jaeger tracing configuration
#
</td>
            </tr>

            <tr>
                <td>certmanager.enabled</td>
                <td>false</td>
                <td>

#
# addon kiali tracing configuration
#
</td>
            </tr>

            <tr>
                <td>istio_cni.enabled</td>
                <td>false</td>
                <td>

#
# addon certmanager configuration
#
</td>
            </tr>

            <tr>
                <td>istiocoredns.enabled</td>
                <td>false</td>
                <td>

#
# Istio CNI plugin enabled
#   This must be enabled to use the CNI plugin in Istio.  The CNI plugin is installed separately.
#   If true, the privileged initContainer istio-init is not needed to perform the traffic redirect
#   settings for the istio-proxy.
#
</td>
            </tr>

            <tr>
                <td>global.hub</td>
                <td>gcr.io/istio-testing</td>
                <td>

# addon Istio CoreDNS configuration
#
</td>
            </tr>

            <tr>
                <td>global.tag</td>
                <td>1.4-dev</td>
                <td>

# Common settings used among istio subcharts.
</td>
            </tr>

            <tr>
                <td>global.logging.level</td>
                <td>default:info</td>
                <td> Default hub for Istio images.
 Releases are published to docker hub under 'istio' project.
 Dev builds from prow are on gcr.io
</td>
            </tr>

            <tr>
                <td>global.monitoringPort</td>
                <td>15014</td>
                <td>

  # Default tag for Istio images.
</td>
            </tr>

            <tr>
                <td>global.k8sIngress.enabled</td>
                <td>false</td>
                <td>

  # Comma-separated minimum per-scope logging level of messages to output, in the form of <scope>:<level>,<scope>:<level>
  # The control plane has different scopes depending on component, but can configure default log level across all components
  # If empty, default scope and level will be used as configured in code
</td>
            </tr>

            <tr>
                <td>global.k8sIngress.gatewayName</td>
                <td>ingressgateway</td>
                <td>

  # monitoring port used by mixer, pilot, galley and sidecar injector
</td>
            </tr>

            <tr>
                <td>global.k8sIngress.enableHttps</td>
                <td>false</td>
                <td>

</td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.limits.cpu</td>
                <td>100m</td>
                <td>
    # Gateway used for k8s Ingress resources. By default it is
    # using 'istio:ingressgateway' that will be installed by setting
    # 'gateways.enabled' and 'gateways.istio-ingressgateway.enabled'
    # flags to true.
</td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.limits.memory</td>
                <td>50Mi</td>
                <td>
    # enableHttps will add port 443 on the ingress.
    # It REQUIRES that the certificates are installed  in the
    # expected secrets - enabling this option without certificates
    # will result in LDS rejection and the ingress will not work.
</td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.requests.cpu</td>
                <td>10m</td>
                <td>

</td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.requests.memory</td>
                <td>10Mi</td>
                <td> Configuration for the proxy init container
</td>
            </tr>

            <tr>
                <td>global.proxy.image</td>
                <td>proxyv2</td>
                <td>
    # use fully qualified image names for alternate path to proxy.
</td>
            </tr>

            <tr>
                <td>global.proxy.clusterDomain</td>
                <td>cluster.local</td>
                <td>

    # cluster domain. Default value is "cluster.local".
</td>
            </tr>

            <tr>
                <td>global.proxy.resources.requests.cpu</td>
                <td>100m</td>
                <td>

    # Resources for the sidecar.
</td>
            </tr>

            <tr>
                <td>global.proxy.resources.requests.memory</td>
                <td>128Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.resources.limits.cpu</td>
                <td>2000m</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.resources.limits.memory</td>
                <td>1024Mi</td>
                <td>

    # Controls number of Proxy worker threads.
    # If set to 0, then start worker thread for each CPU thread/core.
</td>
            </tr>

            <tr>
                <td>global.proxy.concurrency</td>
                <td>2</td>
                <td>

    # Configures the access log for each sidecar.
    # Options:
    #   "" - disables access log
    #   "/dev/stdout" - enables access log
</td>
            </tr>

            <tr>
                <td>global.proxy.accessLogFile</td>
                <td></td>
                <td>

    # Configure how and what fields are displayed in sidecar access log. Setting to
    # empty string will result in default log format
</td>
            </tr>

            <tr>
                <td>global.proxy.accessLogFormat</td>
                <td></td>
                <td>

    # Configure the access log for sidecar to JSON or TEXT.
</td>
            </tr>

            <tr>
                <td>global.proxy.accessLogEncoding</td>
                <td>TEXT</td>
                <td>

    # Configure envoy gRPC access log service.
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.enabled</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.host</td>
                <td></td>
                <td> example: accesslog-service.istio-system
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.port</td>
                <td></td>
                <td> example: 15000
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.mode</td>
                <td>DISABLE</td>
                <td> DISABLE, SIMPLE, MUTUAL, ISTIO_MUTUAL
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.clientCertificate</td>
                <td></td>
                <td> example: /etc/istio/als/cert-chain.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.privateKey</td>
                <td></td>
                <td> example: /etc/istio/als/key.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.caCertificates</td>
                <td></td>
                <td> example: /etc/istio/als/root-cert.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.sni</td>
                <td></td>
                <td> example: als.somedomain
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.probes</td>
                <td>3</td>
                <td> - als.somedomain
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.time</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.interval</td>
                <td>10s</td>
                <td>

    # Log level for proxy, applies to gateways and sidecars.  If left empty, "warning" is used.
    # Expected values are: trace|debug|info|warning|error|critical|off
</td>
            </tr>

            <tr>
                <td>global.proxy.logLevel</td>
                <td></td>
                <td>

    # Per Component log level for proxy, applies to gateways and sidecars. If a component level is
    # not set, then the global "logLevel" will be used. If left empty, "misc:error" is used.
</td>
            </tr>

            <tr>
                <td>global.proxy.componentLogLevel</td>
                <td></td>
                <td>

    # Configure the DNS refresh rate for Envoy cluster of type STRICT_DNS
    # This must be given it terms of seconds. For example, 300s is valid but 5m is invalid.
</td>
            </tr>

            <tr>
                <td>global.proxy.dnsRefreshRate</td>
                <td>300s</td>
                <td>

    # Automatic protocol detection uses a set of heuristics to
    # determine whether the connection is using TLS or not (on the
    # server side), as well as the application protocol being used
    # (e.g., http vs tcp). These heuristics rely on the client sending
    # the first bits of data. For server first protocols like MySQL,
    # MongoDB, etc., Envoy will timeout on the protocol detection after
    # the specified period, defaulting to non mTLS plain TCP
    # traffic. Set this field to tweak the period that Envoy will wait
    # for the client to send the first bits of data. (MUST BE >=1ms)
</td>
            </tr>

            <tr>
                <td>global.proxy.protocolDetectionTimeout</td>
                <td>100ms</td>
                <td>

    #If set to true, istio-proxy container will have privileged securityContext
</td>
            </tr>

            <tr>
                <td>global.proxy.privileged</td>
                <td>false</td>
                <td>

    # If set, newly injected sidecars will have core dumps enabled.
</td>
            </tr>

            <tr>
                <td>global.proxy.enableCoreDump</td>
                <td>false</td>
                <td>

    # Image used to enable core dumps. This is only used, when "enableCoreDump" is set to true.
</td>
            </tr>

            <tr>
                <td>global.proxy.enableCoreDumpImage</td>
                <td>ubuntu:xenial</td>
                <td>

    # Default port for Pilot agent health checks. A value of 0 will disable health checking.
</td>
            </tr>

            <tr>
                <td>global.proxy.statusPort</td>
                <td>15020</td>
                <td>

    # The initial delay for readiness probes in seconds.
</td>
            </tr>

            <tr>
                <td>global.proxy.readinessInitialDelaySeconds</td>
                <td>1</td>
                <td>

    # The period between readiness probes.
</td>
            </tr>

            <tr>
                <td>global.proxy.readinessPeriodSeconds</td>
                <td>2</td>
                <td>

    # The number of successive failed probes before indicating readiness failure.
</td>
            </tr>

            <tr>
                <td>global.proxy.readinessFailureThreshold</td>
                <td>30</td>
                <td>

    # istio egress capture whitelist
    # https://istio.io/docs/tasks/traffic-management/egress.html#calling-external-services-directly
    # example: includeIPRanges: "172.30.0.0/16,172.20.0.0/16"
    # would only capture egress traffic on those two IP Ranges, all other outbound traffic would
    # be allowed by the sidecar
</td>
            </tr>

            <tr>
                <td>global.proxy.includeIPRanges</td>
                <td>*</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.excludeIPRanges</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.excludeOutboundPorts</td>
                <td></td>
                <td>

    # pod internal interfaces
</td>
            </tr>

            <tr>
                <td>global.proxy.kubevirtInterfaces</td>
                <td></td>
                <td>

    # istio ingress capture whitelist
    # examples:
    #     Redirect no inbound traffic to Envoy:    --includeInboundPorts=""
    #     Redirect all inbound traffic to Envoy:   --includeInboundPorts="*"
    #     Redirect only selected ports:            --includeInboundPorts="80,8080"
</td>
            </tr>

            <tr>
                <td>global.proxy.includeInboundPorts</td>
                <td>*</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.excludeInboundPorts</td>
                <td></td>
                <td>

    # This controls the 'policy' in the sidecar injector.
</td>
            </tr>

            <tr>
                <td>global.proxy.autoInject</td>
                <td>enabled</td>
                <td>

    # Sets the destination Statsd in envoy (the value of the "--statsdUdpAddress" proxy argument
    # would be <host>:<port>).
    # Disabled by default.
    # The istio-statsd-prom-bridge is deprecated and should not be used moving forward.
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.enabled</td>
                <td>false</td>
                <td> If enabled is set to true, host and port must also be provided. Istio no longer provides a statsd collector.
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.host</td>
                <td></td>
                <td> example: statsd-svc.istio-system
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.port</td>
                <td></td>
                <td> example: 9125

    # Sets the Envoy Metrics Service address, used to push Envoy metrics to an external collector
    # via the Metrics Service gRPC API. This contains detailed stats information emitted directly
    # by Envoy and should not be confused with the the Istio telemetry. The Envoy stats are also
    # available to scrape via the Envoy admin port at either /stats or /stats/prometheus.
    #
    # See https://www.envoyproxy.io/docs/envoy/latest/api-v2/config/metrics/v2/metrics_service.proto
    # for details about Envoy's Metrics Service API.
    #
    # Disabled by default.
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.enabled</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.host</td>
                <td></td>
                <td> example: metrics-service.istio-system
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.port</td>
                <td></td>
                <td> example: 15000
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.mode</td>
                <td>DISABLE</td>
                <td> DISABLE, SIMPLE, MUTUAL, ISTIO_MUTUAL
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.clientCertificate</td>
                <td></td>
                <td> example: /etc/istio/ms/cert-chain.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.privateKey</td>
                <td></td>
                <td> example: /etc/istio/ms/key.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.caCertificates</td>
                <td></td>
                <td> example: /etc/istio/ms/root-cert.pem
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.sni</td>
                <td></td>
                <td> example: ms.somedomain
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.probes</td>
                <td>3</td>
                <td> - ms.somedomain
</td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.time</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.interval</td>
                <td>10s</td>
                <td>

    # Specify which tracer to use. One of: zipkin, lightstep, datadog, stackdriver.
    # If using stackdriver tracer outside GCP, set env GOOGLE_APPLICATION_CREDENTIALS to the GCP credential file.
</td>
            </tr>

            <tr>
                <td>global.proxy.tracer</td>
                <td>zipkin</td>
                <td>

</td>
            </tr>

            <tr>
                <td>global.proxy_init.image</td>
                <td>proxyv2</td>
                <td> Base name for the istio-init container, used to configure iptables.
</td>
            </tr>

            <tr>
                <td>global.imagePullPolicy</td>
                <td>IfNotPresent</td>
                <td>

  # imagePullPolicy is applied to istio control plane components.
  # local tests require IfNotPresent, to avoid uploading to dockerhub.
  # TODO: Switch to Always as default, and override in the local tests.
</td>
            </tr>

            <tr>
                <td>global.controlPlaneSecurityEnabled</td>
                <td>false</td>
                <td>

  # controlPlaneSecurityEnabled enabled. Will result in delays starting the pods while secrets are
  # propagated, not recommended for tests.
</td>
            </tr>

            <tr>
                <td>global.disablePolicyChecks</td>
                <td>true</td>
                <td>

  # disablePolicyChecks disables mixer policy checks.
  # if mixer.policy.enabled==true then disablePolicyChecks has affect.
  # Will set the value with same name in istio config map - pilot needs to be restarted to take effect.
</td>
            </tr>

            <tr>
                <td>global.policyCheckFailOpen</td>
                <td>false</td>
                <td>

  # policyCheckFailOpen allows traffic in cases when the mixer policy service cannot be reached.
  # Default is false which means the traffic is denied when the client is unable to connect to Mixer.
</td>
            </tr>

            <tr>
                <td>global.enableTracing</td>
                <td>true</td>
                <td>

  # EnableTracing sets the value with same name in istio config map, requires pilot restart to take effect.
</td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.address</td>
                <td></td>
                <td>

  # Configuration for each of the supported tracers
</td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.accessToken</td>
                <td></td>
                <td> Configuration for envoy to send trace data to LightStep.
 Disabled by default.
 address: the <host>:<port> of the satellite pool
 accessToken: required for sending data to the pool
 secure: specifies whether data should be sent with TLS
 cacertPath: the path to the file containing the cacert to use when verifying TLS. If secure is true, this is
   required. If a value is specified then a secret called "lightstep.cacert" must be created in the destination
   namespace with the key matching the base of the provided cacertPath and the value being the cacert itself.

</td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.secure</td>
                <td>true</td>
                <td> example: lightstep-satellite:443
</td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.cacertPath</td>
                <td></td>
                <td> example: abcdefg1234567
</td>
            </tr>

            <tr>
                <td>global.tracer.zipkin.address</td>
                <td></td>
                <td> example: true|false
</td>
            </tr>

            <tr>
                <td>global.tracer.datadog.address</td>
                <td>$(HOST_IP):8126</td>
                <td> example: /etc/lightstep/cacert.pem
</td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.debug</td>
                <td>false</td>
                <td> Host:Port for reporting trace data in zipkin format. If not specified, will default to
 zipkin service (port 9411) in the same namespace as the other istio components.
</td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfAttributes</td>
                <td>200</td>
                <td> Host:Port for submitting traces to the Datadog agent.
</td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfAnnotations</td>
                <td>200</td>
                <td> enables trace output to stdout.
</td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfMessageEvents</td>
                <td>200</td>
                <td>
      # The global default max number of attributes per span.
</td>
            </tr>

            <tr>
                <td>global.mtls.enabled</td>
                <td>false</td>
                <td>
      # The global default max number of annotation events per span.
</td>
            </tr>

            <tr>
                <td>global.mtls.auto</td>
                <td>false</td>
                <td>
      # The global default max number of message events per span.
</td>
            </tr>

            <tr>
                <td>global.arch.amd64</td>
                <td>2</td>
                <td>

  # Default mtls policy. If true, mtls between services will be enabled by default.
</td>
            </tr>

            <tr>
                <td>global.arch.s390x</td>
                <td>2</td>
                <td> Default setting for service-to-service mtls. Can be set explicitly using
 destination rules or service annotations.
</td>
            </tr>

            <tr>
                <td>global.arch.ppc64le</td>
                <td>2</td>
                <td>
    # If set to true, and a given service does not have a corresponding DestinationRule configured,
    # or its DestinationRule does not have TLSSettings specified, Istio configures client side
    # TLS configuration automatically, based on the server side mTLS authentication policy and the
    # availibity of sidecars.
</td>
            </tr>

            <tr>
                <td>global.oneNamespace</td>
                <td>false</td>
                <td>

  # Lists the secrets you need to use to pull Istio images from a private registry.
</td>
            </tr>

            <tr>
                <td>global.configValidation</td>
                <td>true</td>
                <td> - private-registry-key

 Specify pod scheduling arch(amd64, ppc64le, s390x) and weight as follows:
   0 - Never scheduled
   1 - Least preferred
   2 - No preference
   3 - Most preferred
</td>
            </tr>

            <tr>
                <td>global.meshExpansion.enabled</td>
                <td>false</td>
                <td>

  # Whether to restrict the applications namespace the controller manages;
  # If not set, controller watches all namespaces
</td>
            </tr>

            <tr>
                <td>global.meshExpansion.useILB</td>
                <td>false</td>
                <td>

  # Default node selector to be applied to all deployments so that all pods can be
  # constrained to run a particular nodes. Each component can overwrite these default
  # values by adding its node selector block in the relevant section below and setting
  # the desired values.
</td>
            </tr>

            <tr>
                <td>global.multiCluster.enabled</td>
                <td>false</td>
                <td>
 Default node tolerations to be applied to all deployments so that all pods can be
 scheduled to a particular nodes with matching taints. Each component can overwrite
 these default values by adding its tolerations block in the relevant section below
 and setting the desired values.
 Configure this field in case that all pods of Istio control plane are expected to
 be scheduled to particular nodes with specified taints.
</td>
            </tr>

            <tr>
                <td>global.multiCluster.clusterName</td>
                <td></td>
                <td>
 Whether to perform server-side validation of configuration.
</td>
            </tr>

            <tr>
                <td>global.defaultResources.requests.cpu</td>
                <td>10m</td>
                <td>

  # Custom DNS config for the pod to resolve names of services in other
  # clusters. Use this to add additional search domains, and other settings.
  # see
  # https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#dns-config
  # This does not apply to gateway pods as they typically need a different
  # set of DNS settings than the normal application pods (e.g., in
  # multicluster scenarios).
  # NOTE: If using templates, follow the pattern in the commented example below.
  # podDNSSearchNamespaces:
  # - global
  # - "{{ valueOrDefault .DeploymentMeta.Namespace \"default\" }}.global"

  # If set to true, the pilot and citadel mtls will be exposed on the
  # ingress gateway
</td>
            </tr>

            <tr>
                <td>global.defaultPodDisruptionBudget.enabled</td>
                <td>true</td>
                <td>
    # If set to true, the pilot and citadel mtls and the plaintext pilot ports
    # will be exposed on an internal gateway
</td>
            </tr>

            <tr>
                <td>global.priorityClassName</td>
                <td></td>
                <td>

</td>
            </tr>

            <tr>
                <td>global.useMCP</td>
                <td>true</td>
                <td> Set to true to connect two kubernetes clusters via their respective
 ingressgateway services when pods in each cluster cannot directly
 talk to one another. All clusters should be using Istio mTLS and must
 have a shared root CA for this model to work.
</td>
            </tr>

            <tr>
                <td>global.trustDomain</td>
                <td></td>
                <td>

    # Should be set to the name of the cluster this installation will run in. This is required for sidecar injection
    # to properly label proxies
</td>
            </tr>

            <tr>
                <td>global.meshID</td>
                <td></td>
                <td>

  # A minimal set of requested resources to applied to all deployments so that
  # Horizontal Pod Autoscaler will be able to function (if set).
  # Each component can overwrite these default values by adding its own resources
  # block in the relevant section below and setting the desired resources values.
</td>
            </tr>

            <tr>
                <td>global.outboundTrafficPolicy.mode</td>
                <td>ALLOW_ANY</td>
                <td>
    #   memory: 128Mi
    # limits:
    #   cpu: 100m
    #   memory: 128Mi

  # enable pod distruption budget for the control plane, which is used to
  # ensure Istio control plane components are gradually upgraded or recovered.
</td>
            </tr>

            <tr>
                <td>global.sds.enabled</td>
                <td>false</td>
                <td>
    # The values aren't mutable due to a current PodDisruptionBudget limitation
    # minAvailable: 1

  # Kubernetes >=v1.11.0 will create two PriorityClass, including system-cluster-critical and
  # system-node-critical, it is better to configure this in order to make sure your Istio pods
  # will not be killed because of low priority class.
  # Refer to https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass
  # for more detail.
</td>
            </tr>

            <tr>
                <td>global.sds.udsPath</td>
                <td></td>
                <td>

  # Use the Mesh Control Protocol (MCP) for configuring Mixer and
  # Pilot. Requires galley (`--set galley.enabled=true`).
</td>
            </tr>

            <tr>
                <td>global.sds.token.aud</td>
                <td>istio-ca</td>
                <td>

  # The trust domain corresponds to the trust root of a system
  # Refer to https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#21-trust-domain
  # Indicate the domain used in SPIFFE identity URL
  # The default depends on the environment.
  #   kubernetes: cluster.local
  #   else:  default dns domain
</td>
            </tr>

            <tr>
                <td>global.network</td>
                <td></td>
                <td>

  #  The trust domain aliases represent the aliases of trust_domain.
  #  For example, if we have
  #  trustDomain: td1
  #  trustDomainAliases: [“td2”, "td3"]
  #  Any service with the identity "td1/ns/foo/sa/a-service-account", "td2/ns/foo/sa/a-service-account",
  #  or "td3/ns/foo/sa/a-service-account" will be treated the same in the Istio mesh.
</td>
            </tr>

            <tr>
                <td>global.localityLbSetting.enabled</td>
                <td>true</td>
                <td>
 Mesh ID means Mesh Identifier. It should be unique within the scope where
 meshes will interact with each other, but it is not required to be
 globally/universally unique. For example, if any of the following are true,
 then two meshes must have different Mesh IDs:
 - Meshes will have their telemetry aggregated in one place
 - Meshes will be federated together
 - Policy will be written referencing one mesh from the other

 If an administrator expects that any of these conditions may become true in
 the future, they should ensure their meshes have different Mesh IDs
 assigned.

 Within a multicluster mesh, each cluster must be (manually or auto)
 configured to have the same Mesh ID value. If an existing cluster 'joins' a
 multicluster mesh, it will need to be migrated to the new mesh ID. Details
 of migration TBD, and it may be a disruptive operation to change the Mesh
 ID post-install.

 If the mesh admin does not specify a value, Istio will use the value of the
 mesh's Trust Domain. The best practice is to select a proper Trust Domain
 value.
</td>
            </tr>

            <tr>
                <td>global.enableHelmTest</td>
                <td>false</td>
                <td>

  # Set the default behavior of the sidecar for handling outbound traffic from the application:
  # ALLOW_ANY - outbound traffic to unknown destinations will be allowed, in case there are no
  #   services or ServiceEntries for the destination port
  # REGISTRY_ONLY - restrict outbound traffic to services defined in the service registry as well
  #   as those defined through ServiceEntries
  # ALLOW_ANY is the default in 1.1.  This means each pod will be able to make outbound requests
  # to services outside of the mesh without any ServiceEntry.
  # REGISTRY_ONLY was the default in 1.0.  If this behavior is desired, set the value below to REGISTRY_ONLY.
</td>
            </tr>

            <tr>
                <td>global.operatorManageWebhooks</td>
                <td>false</td>
                <td>

  # The namespace where globally shared configurations should be present.
  # DestinationRules that apply to the entire mesh (e.g., enabling mTLS),
  # default Sidecar configs, etc. should be added to this namespace.
  # configRootNamespace: istio-config

  # set the default set of namespaces to which services, service entries, virtual services, destination
  # rules should be exported to. Currently only one value can be provided in this list. This value
  # should be one of the following two options:
  # * implies these objects are visible to all namespaces, enabling any sidecar to talk to any other sidecar.
  # . implies these objects are visible to only to sidecars in the same namespace, or if imported as a Sidecar.egress.host
  # defaultConfigVisibilitySettings:
  #- '*'

</td>
            </tr>

    </tbody>
</table>

## `grafana` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>grafana.enabled</td>
                <td>false</td>
                <td>
 addon grafana configuration

</td>
            </tr>

            <tr>
                <td>grafana.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.image.repository</td>
                <td>grafana/grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.image.tag</td>
                <td>6.4.3</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.enabled</td>
                <td>false</td>
                <td>
  ## Used to create an Ingress record.
</td>
            </tr>

            <tr>
                <td>grafana.ingress.persist</td>
                <td>false</td>
                <td> kubernetes.io/ingress.class: nginx
 kubernetes.io/tls-acme: "true"
</td>
            </tr>

            <tr>
                <td>grafana.ingress.storageClassName</td>
                <td></td>
                <td> Secrets must be manually created in the namespace.
 - secretName: grafana-tls
   hosts:
     - grafana.local
</td>
            </tr>

            <tr>
                <td>grafana.ingress.accessMode</td>
                <td>ReadWriteMany</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.security.enabled</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.security.secretName</td>
                <td>grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.security.usernameKey</td>
                <td>username</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.security.passphraseKey</td>
                <td>passphrase</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.contextPath</td>
                <td>/grafana</td>
                <td>
</td>
            </tr>

            <tr>
                <td>grafana.ingress.service.name</td>
                <td>http</td>
                <td> Define additional environment variables for configuring grafana.
 @see https://grafana.com/docs/installation/configuration/#using-environment-variables
 Format: env_variable_name: value
 For example:
 GF_SMTP_ENABLED: true
 GF_SMTP_HOST: email-smtp.eu-west-1.amazonaws.com:2587
 GF_SMTP_FROM_ADDRESS: alerts@mydomain.com
 GF_SMTP_FROM_NAME: Grafana

</td>
            </tr>

            <tr>
                <td>grafana.ingress.service.type</td>
                <td>ClusterIP</td>
                <td> The key name and ENV name must match in the secrets file.
 @see https://grafana.com/docs/installation/configuration/#using-environment-variables
 For example:
 ---
 apiVersion: v1
 kind: Secret
 metadata:
   name: grafana-secrets
   namespace: istio-system
 data:
   GF_SMTP_USER: bXl1c2Vy
   GF_SMTP_PASSWORD: bXlwYXNzd29yZA==
 type: Opaque
 ---
 env_variable_key_name: secretsName
 ---
 GF_SMTP_USER: grafana-secrets
 GF_SMTP_PASSWORD: grafana-secrets

 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>grafana.ingress.service.externalPort</td>
                <td>3000</td>
                <td>
</td>
            </tr>

            <tr>
                <td>grafana.ingress.service.loadBalancerIP</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.apiVersion</td>
                <td>1</td>
                <td>
</td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.name</td>
                <td>Prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.type</td>
                <td>prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.orgId</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.url</td>
                <td>http://prometheus:9090</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.access</td>
                <td>proxy</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.isDefault</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.jsonData.timeInterval</td>
                <td>5s</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.datasources.datasources.yaml.datasources.editable</td>
                <td>true</td>
                <td>

</td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.apiVersion</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.name</td>
                <td>istio</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.orgId</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.folder</td>
                <td>istio</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.type</td>
                <td>file</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.disableDeletion</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers.options.path</td>
                <td>/var/lib/grafana/dashboards/istio</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `istiocoredns` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>istiocoredns.enabled</td>
                <td>false</td>
                <td>
 addon istiocoredns tracing configuration

</td>
            </tr>

            <tr>
                <td>istiocoredns.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>istiocoredns.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>istiocoredns.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>istiocoredns.coreDNSImage</td>
                <td>coredns/coredns</td>
                <td></td>
            </tr>

            <tr>
                <td>istiocoredns.coreDNSTag</td>
                <td>1.6.2</td>
                <td>
# Source code for the plugin can be found at
# https://github.com/istio-ecosystem/istio-coredns-plugin
# The plugin listens for DNS requests from coredns server at 127.0.0.1:8053
</td>
            </tr>

            <tr>
                <td>istiocoredns.coreDNSPluginImage</td>
                <td>istio/coredns-plugin:0.2-istio-1.1</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `kiali` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>kiali.enabled</td>
                <td>false</td>
                <td>
 addon kiali

</td>
            </tr>

            <tr>
                <td>kiali.replicaCount</td>
                <td>1</td>
                <td> Note that if using the demo or demo-auth yaml when installing via Helm, this default will be `true`.
</td>
            </tr>

            <tr>
                <td>kiali.hub</td>
                <td>quay.io/kiali</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.image</td>
                <td>kiali</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.tag</td>
                <td>v1.9</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.contextPath</td>
                <td>/kiali</td>
                <td> The root context path to access the Kiali UI.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.enabled</td>
                <td>false</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>kiali.ingress.hosts.tls</td>
                <td></td>
                <td>
</td>
            </tr>

            <tr>
                <td>kiali.ingress.dashboard.auth.strategy</td>
                <td>login</td>
                <td>
  ## Used to create an Ingress record.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.dashboard.secretName</td>
                <td>kiali</td>
                <td> kubernetes.io/ingress.class: nginx
 kubernetes.io/tls-acme: "true"
</td>
            </tr>

            <tr>
                <td>kiali.ingress.dashboard.viewOnlyMode</td>
                <td>false</td>
                <td> Secrets must be manually created in the namespace.
 - secretName: kiali-tls
   hosts:
     - kiali.local

</td>
            </tr>

            <tr>
                <td>kiali.ingress.dashboard.grafanaURL</td>
                <td></td>
                <td> Can be anonymous, login, or openshift
</td>
            </tr>

            <tr>
                <td>kiali.ingress.dashboard.jaegerURL</td>
                <td></td>
                <td> You must create a secret with this name - one is not provided out-of-box.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.prometheusAddr</td>
                <td>http://prometheus:9090</td>
                <td> Bind the service account to a role with only read access
</td>
            </tr>

            <tr>
                <td>kiali.ingress.createDemoSecret</td>
                <td>false</td>
                <td> If you have Grafana installed and it is accessible to client browsers, then set this to its external URL. Kiali will redirect users to this URL when Grafana metrics are to be shown.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.security.enabled</td>
                <td>false</td>
                <td> If you have Jaeger installed and it is accessible to client browsers, then set this property to its external URL. Kiali will redirect users to this URL when Jaeger tracing is to be shown.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.security.cert_file</td>
                <td>/kiali-cert/cert-chain.pem</td>
                <td>

# When true, a secret will be created with a default username and password. Useful for demos.
</td>
            </tr>

            <tr>
                <td>kiali.ingress.security.private_key_file</td>
                <td>/kiali-cert/key.pem</td>
                <td>

</td>
            </tr>

    </tbody>
</table>

## `mixer` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>mixer.image</td>
                <td>mixer</td>
                <td>
 mixer configuration

</td>
            </tr>

            <tr>
                <td>mixer.env.GOMAXPROCS</td>
                <td>6</td>
                <td>

</td>
            </tr>

            <tr>
                <td>mixer.policy.enabled</td>
                <td>false</td>
                <td> max procs should be ceil(cpu limit + 1)
</td>
            </tr>

            <tr>
                <td>mixer.policy.replicaCount</td>
                <td>1</td>
                <td>

</td>
            </tr>

            <tr>
                <td>mixer.policy.autoscaleEnabled</td>
                <td>true</td>
                <td> if policy is enabled, global.disablePolicyChecks has affect.
</td>
            </tr>

            <tr>
                <td>mixer.policy.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.autoscaleMax</td>
                <td>5</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.rollingMaxUnavailable</td>
                <td>25%</td>
                <td>

</td>
            </tr>

            <tr>
                <td>mixer.telemetry.enabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.autoscaleEnabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.autoscaleMax</td>
                <td>5</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.sessionAffinityEnabled</td>
                <td>false</td>
                <td>

  # mixer load shedding configuration.
  # When mixer detects that it is overloaded, it starts rejecting grpc requests.
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.loadshedding.mode</td>
                <td>enforce</td>
                <td> disabled, logonly or enforce
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.loadshedding.latencyThreshold</td>
                <td>100ms</td>
                <td>
    # based on measurements 100ms p50 translates to p99 of under 1s. This is ok for telemetry which is inherently async.
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.resources.requests.cpu</td>
                <td>1000m</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.resources.requests.memory</td>
                <td>1G</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.resources.limits.cpu</td>
                <td>4800m</td>
                <td> It is best to do horizontal scaling of mixer using moderate cpu allocation.
 We have experimentally found that these values work well.
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.resources.limits.memory</td>
                <td>4G</td>
                <td>

  # Set reportBatchMaxEntries to 0 to use the default batching behavior (i.e., every 100 requests). 
  # A positive value indicates the number of requests that are batched before telemetry data 
  # is sent to the mixer server
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.reportBatchMaxEntries</td>
                <td>100</td>
                <td>

  # Set reportBatchMaxTime to 0 to use the default batching behavior (i.e., every 1 second). 
  # A positive time value indicates the maximum wait time since the last request will telemetry data 
  # be batched before being sent to the mixer server
</td>
            </tr>

            <tr>
                <td>mixer.telemetry.reportBatchMaxTime</td>
                <td>1s</td>
                <td>

</td>
            </tr>

            <tr>
                <td>mixer.adapters.kubernetesenv.enabled</td>
                <td>true</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>mixer.adapters.stdio.enabled</td>
                <td>false</td>
                <td>
</td>
            </tr>

            <tr>
                <td>mixer.adapters.stdio.outputAsJson</td>
                <td>true</td>
                <td>

  # stdio is a debug adapter in istio-telemetry, it is not recommended for production use.
</td>
            </tr>

            <tr>
                <td>mixer.adapters.prometheus.enabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.prometheus.metricsExpiryDuration</td>
                <td>10m</td>
                <td>
  # Setting this to false sets the useAdapterCRDs mixer startup argument to false
</td>
            </tr>

            <tr>
                <td>mixer.adapters.useAdapterCRDs</td>
                <td>false</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `nodeagent` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>nodeagent.enabled</td>
                <td>false</td>
                <td>
 nodeagent configuration

</td>
            </tr>

            <tr>
                <td>nodeagent.image</td>
                <td>node-agent-k8s</td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.env.CA_PROVIDER</td>
                <td></td>
                <td> name of authentication provider.
</td>
            </tr>

            <tr>
                <td>nodeagent.env.CA_ADDR</td>
                <td></td>
                <td>
  # CA endpoint.
</td>
            </tr>

            <tr>
                <td>nodeagent.env.PLUGINS</td>
                <td></td>
                <td>
  # names of authentication provider's plugins.
</td>
            </tr>

    </tbody>
</table>

## `pilot` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>pilot.enabled</td>
                <td>true</td>
                <td>
 pilot configuration

</td>
            </tr>

            <tr>
                <td>pilot.autoscaleEnabled</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.autoscaleMax</td>
                <td>5</td>
                <td>
# specify replicaCount when autoscaleEnabled: false
# replicaCount: 1
</td>
            </tr>

            <tr>
                <td>pilot.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.image</td>
                <td>pilot</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.sidecar</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.traceSampling</td>
                <td>1.0</td>
                <td>
# if protocol sniffing is enabled for outbound
</td>
            </tr>

            <tr>
                <td>pilot.enableProtocolSniffingForOutbound</td>
                <td>true</td>
                <td>
# if protocol sniffing is enabled for inbound
</td>
            </tr>

            <tr>
                <td>pilot.enableProtocolSniffingForInbound</td>
                <td>false</td>
                <td>
# Resources for a small pilot install
</td>
            </tr>

            <tr>
                <td>pilot.resources.requests.cpu</td>
                <td>500m</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.resources.requests.memory</td>
                <td>2048Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.env.PILOT_PUSH_THROTTLE</td>
                <td>100</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.keepaliveMaxServerConnectionAge</td>
                <td>30m</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>pilot.configSource.subscribedResources</td>
                <td></td>
                <td>
 The following is used to limit how long a sidecar can be connected
 to a pilot. It balances out load across pilot instances at the cost of
 increasing system churn.
</td>
            </tr>

    </tbody>
</table>

## `prometheus` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>prometheus.enabled</td>
                <td>true</td>
                <td>
 addon prometheus configuration

</td>
            </tr>

            <tr>
                <td>prometheus.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.hub</td>
                <td>docker.io/prom</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.image</td>
                <td>prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.tag</td>
                <td>v2.12.0</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.retention</td>
                <td>6h</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.scrapeInterval</td>
                <td>15s</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>prometheus.contextPath</td>
                <td>/prometheus</td>
                <td>
 Controls the frequency of prometheus scraping
</td>
            </tr>

            <tr>
                <td>prometheus.ingress.enabled</td>
                <td>false</td>
                <td>

</td>
            </tr>

            <tr>
                <td>prometheus.ingress.hosts.annotations</td>
                <td></td>
                <td>

</td>
            </tr>

            <tr>
                <td>prometheus.ingress.hosts.tls</td>
                <td></td>
                <td>
  ## Used to create an Ingress record.
</td>
            </tr>

            <tr>
                <td>prometheus.ingress.service.nodePort.enabled</td>
                <td>false</td>
                <td> kubernetes.io/ingress.class: nginx
 kubernetes.io/tls-acme: "true"
</td>
            </tr>

            <tr>
                <td>prometheus.ingress.service.nodePort.port</td>
                <td>32090</td>
                <td> Secrets must be manually created in the namespace.
 - secretName: prometheus-tls
   hosts:
     - prometheus.local

</td>
            </tr>

            <tr>
                <td>prometheus.ingress.security.enabled</td>
                <td>true</td>
                <td>

</td>
            </tr>

    </tbody>
</table>

## `security` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>security.enabled</td>
                <td>true</td>
                <td>
 security configuration

</td>
            </tr>

            <tr>
                <td>security.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>security.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>security.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>security.image</td>
                <td>citadel</td>
                <td></td>
            </tr>

            <tr>
                <td>security.selfSigned</td>
                <td>true</td>
                <td> indicate if self-signed CA is used.
</td>
            </tr>

            <tr>
                <td>security.createMeshPolicy</td>
                <td>true</td>
                <td></td>
            </tr>

            <tr>
                <td>security.citadelHealthCheck</td>
                <td>false</td>
                <td>
 Enable health checking on the Citadel CSR signing API.
 https://istio.io/docs/tasks/security/health-check/
</td>
            </tr>

            <tr>
                <td>security.workloadCertTtl</td>
                <td>2160h</td>
                <td>
# 90*24hour = 2160h
</td>
            </tr>

            <tr>
                <td>security.enableNamespacesByDefault</td>
                <td>true</td>
                <td>
# Environment variables that configure Citadel.
</td>
            </tr>

    </tbody>
</table>

## `sidecarInjectorWebhook` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>sidecarInjectorWebhook.enabled</td>
                <td>true</td>
                <td>
 sidecar-injector webhook configuration

</td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.image</td>
                <td>sidecar_injector</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.enableNamespacesByDefault</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.rewriteAppHTTPProbe</td>
                <td>false</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

    </tbody>
</table>

## `tracing` options

<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>

            <tr>
                <td>tracing.enabled</td>
                <td>false</td>
                <td>
 addon jaeger tracing configuration

</td>
            </tr>

            <tr>
                <td>tracing.provider</td>
                <td>jaeger</td>
                <td>

</td>
            </tr>

            <tr>
                <td>tracing.jaeger.hub</td>
                <td>docker.io/jaegertracing</td>
                <td>
 Specify the pod anti-affinity that allows you to constrain which nodes
 your pod is eligible to be scheduled based on labels on pods that are
 already running on the node rather than based on labels on nodes.
 There are currently two types of anti-affinity:
    "requiredDuringSchedulingIgnoredDuringExecution"
    "preferredDuringSchedulingIgnoredDuringExecution"
 which denote "hard" vs. "soft" requirements, you can define your values
 in "podAntiAffinityLabelSelector" and "podAntiAffinityTermLabelSelector"
 correspondingly.
 For example:
 podAntiAffinityLabelSelector:
 - key: security
   operator: In
   values: S1,S2
   topologyKey: "kubernetes.io/hostname"
 This pod anti-affinity rule says that the pod requires not to be scheduled
 onto a node if that node is already running a pod with label having key
 "security" and value "S1".
</td>
            </tr>

            <tr>
                <td>tracing.jaeger.image</td>
                <td>all-in-one</td>
                <td>
</td>
            </tr>

            <tr>
                <td>tracing.jaeger.tag</td>
                <td>1.14</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.memory.max_traces</td>
                <td>50000</td>
                <td>
  # spanStorageType value can be "memory" and "badger" for all-in-one image
</td>
            </tr>

            <tr>
                <td>tracing.jaeger.spanStorageType</td>
                <td>badger</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.persist</td>
                <td>false</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.storageClassName</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.accessMode</td>
                <td>ReadWriteMany</td>
                <td>


</td>
            </tr>

            <tr>
                <td>tracing.zipkin.hub</td>
                <td>docker.io/openzipkin</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.image</td>
                <td>zipkin</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.tag</td>
                <td>2.14.2</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.probeStartupDelay</td>
                <td>200</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.queryPort</td>
                <td>9411</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.resources.limits.cpu</td>
                <td>300m</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.resources.limits.memory</td>
                <td>900Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.resources.requests.cpu</td>
                <td>150m</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.resources.requests.memory</td>
                <td>900Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.javaOptsHeap</td>
                <td>700</td>
                <td>
  # From: https://github.com/openzipkin/zipkin/blob/master/zipkin-server/src/main/resources/zipkin-server-shared.yml#L51
  # Maximum number of spans to keep in memory.  When exceeded, oldest traces (and their spans) will be purged.
  # A safe estimate is 1K of memory per span (each span with 2 annotations + 1 binary annotation), plus
  # 100 MB for a safety buffer.  You'll need to verify in your own environment.
</td>
            </tr>

            <tr>
                <td>tracing.zipkin.maxSpans</td>
                <td>500000</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.node.cpus</td>
                <td>2</td>
                <td>

</td>
            </tr>

            <tr>
                <td>tracing.service.name</td>
                <td>http</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.service.type</td>
                <td>ClusterIP</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.service.externalPort</td>
                <td>9411</td>
                <td>

</td>
            </tr>

            <tr>
                <td>tracing.ingress.enabled</td>
                <td>false</td>
                <td>
  # Used to create an Ingress record.
</td>
            </tr>

            <tr>
                <td>tracing.ingress.hosts</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.ingress.annotations</td>
                <td></td>
                <td> - tracing.local
</td>
            </tr>

            <tr>
                <td>tracing.ingress.tls</td>
                <td></td>
                <td> kubernetes.io/ingress.class: nginx
 kubernetes.io/tls-acme: "true"
</td>
            </tr>

    </tbody>
</table>


<!-- AUTO-GENERATED-END -->
