---
title: Installation Options (Helm)
description: Describes the options available when installing Istio using Helm charts.
weight: 15
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
                <td>False</td>
                <td></td>
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
                <td>True</td>
                <td></td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.enableAnalysis</td>
                <td>False</td>
                <td></td>
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
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.image</td>
                <td>node-agent-k8s</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.sds.resources.requests.cpu</td>
                <td>100m</td>
                <td></td>
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
                <td></td>
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
                <td>True</td>
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
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[0].port</td>
                <td>15020</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[0].targetPort</td>
                <td>15020</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[0].name</td>
                <td>status-port</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[1].port</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[1].targetPort</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[1].name</td>
                <td>http2</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[1].nodePort</td>
                <td>31380</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[2].port</td>
                <td>443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[2].name</td>
                <td>https</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[2].nodePort</td>
                <td>31390</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[3].port</td>
                <td>31400</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[3].name</td>
                <td>tcp</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[3].nodePort</td>
                <td>31400</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[4].port</td>
                <td>15029</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[4].targetPort</td>
                <td>15029</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[4].name</td>
                <td>https-kiali</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[5].port</td>
                <td>15030</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[5].targetPort</td>
                <td>15030</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[5].name</td>
                <td>https-prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[6].port</td>
                <td>15031</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[6].targetPort</td>
                <td>15031</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[6].name</td>
                <td>https-grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[7].port</td>
                <td>15032</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[7].targetPort</td>
                <td>15032</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[7].name</td>
                <td>https-tracing</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[8].port</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[8].targetPort</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.ports[8].name</td>
                <td>tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[0].port</td>
                <td>15011</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[0].targetPort</td>
                <td>15011</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[0].name</td>
                <td>tcp-pilot-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[1].port</td>
                <td>15004</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[1].targetPort</td>
                <td>15004</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[1].name</td>
                <td>tcp-mixer-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[2].port</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[2].targetPort</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[2].name</td>
                <td>tcp-citadel-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[3].port</td>
                <td>853</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[3].targetPort</td>
                <td>853</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.meshExpansionPorts[3].name</td>
                <td>tcp-dns-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[0].name</td>
                <td>ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[0].secretName</td>
                <td>istio-ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[0].mountPath</td>
                <td>/etc/istio/ingressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[1].name</td>
                <td>ingressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[1].secretName</td>
                <td>istio-ingressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.secretVolumes[1].mountPath</td>
                <td>/etc/istio/ingressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.applicationPorts</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ingressgateway.env.ISTIO_META_ROUTER_MODE</td>
                <td>sni-dnat</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.labels.app</td>
                <td>istio-egressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.labels.istio</td>
                <td>egressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.autoscaleEnabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.autoscaleMax</td>
                <td>5</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.resources.requests.cpu</td>
                <td>100m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.resources.requests.memory</td>
                <td>128Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.resources.limits.cpu</td>
                <td>2000m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.resources.limits.memory</td>
                <td>1024Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.type</td>
                <td>ClusterIP</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[0].port</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[0].name</td>
                <td>http2</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[1].port</td>
                <td>443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[1].name</td>
                <td>https</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[2].port</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[2].targetPort</td>
                <td>15443</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.ports[2].name</td>
                <td>tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[0].name</td>
                <td>egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[0].secretName</td>
                <td>istio-egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[0].mountPath</td>
                <td>/etc/istio/egressgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[1].name</td>
                <td>egressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[1].secretName</td>
                <td>istio-egressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.secretVolumes[1].mountPath</td>
                <td>/etc/istio/egressgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-egressgateway.env.ISTIO_META_ROUTER_MODE</td>
                <td>sni-dnat</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.labels.app</td>
                <td>istio-ilbgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.labels.istio</td>
                <td>ilbgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.autoscaleEnabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.autoscaleMin</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.autoscaleMax</td>
                <td>5</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.rollingMaxSurge</td>
                <td>100%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.rollingMaxUnavailable</td>
                <td>25%</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.cpu.targetAverageUtilization</td>
                <td>80</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.resources.requests.cpu</td>
                <td>800m</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.resources.requests.memory</td>
                <td>512Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.loadBalancerIP</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.serviceAnnotations.cloud.google.com/load-balancer-type</td>
                <td>internal</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.type</td>
                <td>LoadBalancer</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[0].port</td>
                <td>15011</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[0].name</td>
                <td>grpc-pilot-mtls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[1].port</td>
                <td>15010</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[1].name</td>
                <td>grpc-pilot</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[2].port</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[2].targetPort</td>
                <td>8060</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[2].name</td>
                <td>tcp-citadel-grpc-tls</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[3].port</td>
                <td>5353</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.ports[3].name</td>
                <td>tcp-dns</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[0].name</td>
                <td>ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[0].secretName</td>
                <td>istio-ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[0].mountPath</td>
                <td>/etc/istio/ilbgateway-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[1].name</td>
                <td>ilbgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[1].secretName</td>
                <td>istio-ilbgateway-ca-certs</td>
                <td></td>
            </tr>

            <tr>
                <td>gateways.istio-ilbgateway.secretVolumes[1].mountPath</td>
                <td>/etc/istio/ilbgateway-ca-certs</td>
                <td></td>
            </tr>

    </tbody>
</table>

## `global.` options

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
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>galley.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>security.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>certmanager.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>istio_cni.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>istiocoredns.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.hub</td>
                <td>gcr.io/istio-testing</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tag</td>
                <td>1.4-dev</td>
                <td></td>
            </tr>

            <tr>
                <td>global.logging.level</td>
                <td>default:info</td>
                <td></td>
            </tr>

            <tr>
                <td>global.monitoringPort</td>
                <td>15014</td>
                <td></td>
            </tr>

            <tr>
                <td>global.k8sIngress.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.k8sIngress.gatewayName</td>
                <td>ingressgateway</td>
                <td></td>
            </tr>

            <tr>
                <td>global.k8sIngress.enableHttps</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.limits.cpu</td>
                <td>100m</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.limits.memory</td>
                <td>50Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.requests.cpu</td>
                <td>10m</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.init.resources.requests.memory</td>
                <td>10Mi</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.image</td>
                <td>proxyv2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.clusterDomain</td>
                <td>cluster.local</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.resources.requests.cpu</td>
                <td>100m</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.concurrency</td>
                <td>2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.accessLogFile</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.accessLogFormat</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.accessLogEncoding</td>
                <td>TEXT</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.host</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.port</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.mode</td>
                <td>DISABLE</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.clientCertificate</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.privateKey</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.caCertificates</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tlsSettings.sni</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.probes</td>
                <td>3</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.time</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyAccessLogService.tcpKeepalive.interval</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.logLevel</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.componentLogLevel</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.dnsRefreshRate</td>
                <td>300s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.protocolDetectionTimeout</td>
                <td>100ms</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.privileged</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.enableCoreDump</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.enableCoreDumpImage</td>
                <td>ubuntu:xenial</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.statusPort</td>
                <td>15020</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.readinessInitialDelaySeconds</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.readinessPeriodSeconds</td>
                <td>2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.readinessFailureThreshold</td>
                <td>30</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.kubevirtInterfaces</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.includeInboundPorts</td>
                <td>*</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.excludeInboundPorts</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.autoInject</td>
                <td>enabled</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.host</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyStatsd.port</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.host</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.port</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.mode</td>
                <td>DISABLE</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.clientCertificate</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.privateKey</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.caCertificates</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tlsSettings.sni</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.probes</td>
                <td>3</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.time</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.envoyMetricsService.tcpKeepalive.interval</td>
                <td>10s</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy.tracer</td>
                <td>zipkin</td>
                <td></td>
            </tr>

            <tr>
                <td>global.proxy_init.image</td>
                <td>proxyv2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.imagePullPolicy</td>
                <td>IfNotPresent</td>
                <td></td>
            </tr>

            <tr>
                <td>global.controlPlaneSecurityEnabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.disablePolicyChecks</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.policyCheckFailOpen</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.enableTracing</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.address</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.accessToken</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.secure</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.lightstep.cacertPath</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.zipkin.address</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.datadog.address</td>
                <td>$(HOST_IP):8126</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.debug</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfAttributes</td>
                <td>200</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfAnnotations</td>
                <td>200</td>
                <td></td>
            </tr>

            <tr>
                <td>global.tracer.stackdriver.maxNumberOfMessageEvents</td>
                <td>200</td>
                <td></td>
            </tr>

            <tr>
                <td>global.mtls.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.mtls.auto</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.arch.amd64</td>
                <td>2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.arch.s390x</td>
                <td>2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.arch.ppc64le</td>
                <td>2</td>
                <td></td>
            </tr>

            <tr>
                <td>global.oneNamespace</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.configValidation</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.meshExpansion.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.meshExpansion.useILB</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.multiCluster.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.multiCluster.clusterName</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.defaultResources.requests.cpu</td>
                <td>10m</td>
                <td></td>
            </tr>

            <tr>
                <td>global.defaultPodDisruptionBudget.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.priorityClassName</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.useMCP</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.trustDomain</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.meshID</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.outboundTrafficPolicy.mode</td>
                <td>ALLOW_ANY</td>
                <td></td>
            </tr>

            <tr>
                <td>global.sds.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.sds.udsPath</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.sds.token.aud</td>
                <td>istio-ca</td>
                <td></td>
            </tr>

            <tr>
                <td>global.network</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>global.localityLbSetting.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>global.enableHelmTest</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>global.operatorManageWebhooks</td>
                <td>False</td>
                <td></td>
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
                <td>False</td>
                <td></td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.ingress.hosts[0]</td>
                <td>grafana.local</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.persist</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.storageClassName</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.accessMode</td>
                <td>ReadWriteMany</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.security.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.security.secretName</td>
                <td>grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.security.usernameKey</td>
                <td>username</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.security.passphraseKey</td>
                <td>passphrase</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.contextPath</td>
                <td>/grafana</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.service.name</td>
                <td>http</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.service.type</td>
                <td>ClusterIP</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.service.externalPort</td>
                <td>3000</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.service.loadBalancerIP</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.apiVersion</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].name</td>
                <td>Prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].type</td>
                <td>prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].orgId</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].url</td>
                <td>http://prometheus:9090</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].access</td>
                <td>proxy</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].isDefault</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].jsonData.timeInterval</td>
                <td>5s</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.datasources.datasources.yaml.datasources[0].editable</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.apiVersion</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].name</td>
                <td>istio</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].orgId</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].folder</td>
                <td>istio</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].type</td>
                <td>file</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].disableDeletion</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>grafana.dashboardProviders.dashboardproviders.yaml.providers[0].options.path</td>
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
                <td>False</td>
                <td></td>
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
                <td></td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.replicaCount</td>
                <td>1</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>kiali.ingress.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.ingress.hosts[0]</td>
                <td>kiali.local</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.ingress.tls</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.dashboard.auth.strategy</td>
                <td>login</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.dashboard.secretName</td>
                <td>kiali</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.dashboard.viewOnlyMode</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.dashboard.grafanaURL</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.dashboard.jaegerURL</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.prometheusAddr</td>
                <td>http://prometheus:9090</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.createDemoSecret</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.security.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.security.cert_file</td>
                <td>/kiali-cert/cert-chain.pem</td>
                <td></td>
            </tr>

            <tr>
                <td>kiali.security.private_key_file</td>
                <td>/kiali-cert/key.pem</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>mixer.env.GOMAXPROCS</td>
                <td>6</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.policy.autoscaleEnabled</td>
                <td>True</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.replicaCount</td>
                <td>1</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.autoscaleEnabled</td>
                <td>True</td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.loadshedding.mode</td>
                <td>enforce</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.loadshedding.latencyThreshold</td>
                <td>100ms</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.resources.limits.memory</td>
                <td>4G</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.reportBatchMaxEntries</td>
                <td>100</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.telemetry.reportBatchMaxTime</td>
                <td>1s</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.kubernetesenv.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.stdio.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.stdio.outputAsJson</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.prometheus.enabled</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.prometheus.metricsExpiryDuration</td>
                <td>10m</td>
                <td></td>
            </tr>

            <tr>
                <td>mixer.adapters.useAdapterCRDs</td>
                <td>False</td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.image</td>
                <td>node-agent-k8s</td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.env.CA_PROVIDER</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.env.CA_ADDR</td>
                <td></td>
                <td></td>
            </tr>

            <tr>
                <td>nodeagent.env.PLUGINS</td>
                <td></td>
                <td></td>
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
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.autoscaleEnabled</td>
                <td>True</td>
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
                <td></td>
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
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.traceSampling</td>
                <td>1.0</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.enableProtocolSniffingForOutbound</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>pilot.enableProtocolSniffingForInbound</td>
                <td>False</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>pilot.configSource.subscribedResources</td>
                <td>None</td>
                <td></td>
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
                <td>True</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>prometheus.contextPath</td>
                <td>/prometheus</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.ingress.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.ingress.hosts[0]</td>
                <td>prometheus.local</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.ingress.annotations</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.ingress.tls</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.service.nodePort.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.service.nodePort.port</td>
                <td>32090</td>
                <td></td>
            </tr>

            <tr>
                <td>prometheus.security.enabled</td>
                <td>True</td>
                <td></td>
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
                <td>True</td>
                <td></td>
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
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>security.createMeshPolicy</td>
                <td>True</td>
                <td></td>
            </tr>

            <tr>
                <td>security.citadelHealthCheck</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>security.workloadCertTtl</td>
                <td>2160h</td>
                <td></td>
            </tr>

            <tr>
                <td>security.enableNamespacesByDefault</td>
                <td>True</td>
                <td></td>
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
                <td>True</td>
                <td></td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>sidecarInjectorWebhook.rewriteAppHTTPProbe</td>
                <td>False</td>
                <td></td>
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
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.provider</td>
                <td>jaeger</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.hub</td>
                <td>docker.io/jaegertracing</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.image</td>
                <td>all-in-one</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.tag</td>
                <td>1.14</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.memory.max_traces</td>
                <td>50000</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.spanStorageType</td>
                <td>badger</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.jaeger.persist</td>
                <td>False</td>
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
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.maxSpans</td>
                <td>500000</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.zipkin.node.cpus</td>
                <td>2</td>
                <td></td>
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
                <td></td>
            </tr>

            <tr>
                <td>tracing.ingress.enabled</td>
                <td>False</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.ingress.hosts</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.ingress.annotations</td>
                <td>None</td>
                <td></td>
            </tr>

            <tr>
                <td>tracing.ingress.tls</td>
                <td>None</td>
                <td></td>
            </tr>

    </tbody>
</table>


<!-- AUTO-GENERATED-END -->
