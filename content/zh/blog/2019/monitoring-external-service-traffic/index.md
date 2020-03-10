---
title: "监控被阻止的和透传的外部服务流量"
description: "如何使用 Istio 去监控被阻止的和透传的外部服务流量。"
publishdate: 2019-09-28
attribution: Neeraj Poddar (Aspen Mesh)
keywords: [monitoring,blackhole,passthrough]
target_release: 1.3
---

了解，控制和保护外部服务访问权限是你能够从 Istio 这样的服务网格中获得的主要好处之一。
从安全和操作的角度来看，监控哪些外部服务流量被阻止是非常重要的；因为如果程序试图与不合适的服务进行通信，它们可能会出现错误配置或安全漏洞。
同样，如果你现在有允许任何外部服务访问的策略，那么你可以根据对流量的监控，逐步地添加明确的 Istio 配置来限制访问并提高集群的安全性。
在任何情况下，通过遥测了解这种流量都非常有帮助，因为你可以根据它来创建警报和仪表板，并更好地了解安全状况。
这是 Istio 的生产用户强烈要求的功能，我们很高兴在版本 1.3 中添加了对此功能的支持。

为了实现此功能，Istio 的[默认监控指标](/zh/docs/reference/config/policy-and-telemetry/metrics)增加了显式标签，以捕获被阻止和透传的外部服务流量。
这篇博客将介绍如何使用这些增强指标来监视所有外部服务流量。

Istio 控制平面使用了预定义集群 BlackHoleCluster 和 Passthrough 来配置 sidecar 代理，它们的作用分别是阻止和通过所有流量。
为了了解这些集群，让我们先从外部和内部服务在 Istio 服务网格的意义开始。

## 外部和内部服务{#external-and-internal-services}

内部服务被定义为平台中的一部分，并被视为在网格中。对于内部服务，默认情况下，Istio 控制平面为 sidecars 提供所有必需的配置。
例如，在 Kubernetes 集群中，Istio 会为所有 Kubernetes 服务配置 sidecar，以保留所有能够与其他服务通信的服务的默认 Kubernetes 行为。

外部服务是不属于平台的服务，即不在网格内的服务。
对于外部服务，Istio 提供了两个选项，一个是阻止所有外部服务访问（通过将 `global.outboundTrafficPolicy.mode` 设置
为 `REGISTRY_ONLY` 启用）, 另一个是允许所有对外部服务的访问（通过将 `global.outboundTrafficPolicy.mode` 设置为 `ALLOW_ANY` 启用）。
从 Istio 1.3 开始，此设置的默认选项是允许所有外部服务访问。此选项可以通过[网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode)进行配置。

这就是使用 BlackHole 和 Passthrough 集群的地方。

## 什么是 BlackHole 和 Passthrough 集群？{#what-are-black-hole-and-pass-through-clusters}

* **BlackHoleCluster** - 当将 `global.outboundTrafficPolicy.mode` 设置为 `REGISTRY_ONLY` 时，BlackHoleCluster 是
  在 Envoy 配置中创建的虚拟集群。在这种模式下，除非为每个服务显式添加了
  [service entries](/zh/docs/reference/config/networking/service-entry)，否则
  所有到外部服务的流量都会被阻止。为了实现此目的，
  将使用了 [original destination](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#original-destination) 且在 `0.0.0.0:15001` 的默认虚拟出站监听器设置为以 BlackHoleCluster 为静态集群的 TCP 代理。
  BlackHoleCluster 的配置如下所示：

  {{< text json >}}
    {
      "name": "BlackHoleCluster",
      "type": "STATIC",
      "connectTimeout": "10s"
    }
  {{< /text >}}

  如你所见，这个集群是静态的且没有任何的 endpoints，所以所有的流量都会被丢弃。
  此外，Istio 会为平台服务的每个端口/协议组合创建唯一的监听器，如果对同一端口上的外部服务发出了请求，则监听器将会取代虚拟监听器。
  在这种情况下，Envoy 中每个虚拟路由的路由配置都会被扩展，以添加 BlackHoleCluster，如下所示：

  {{< text json >}}
    {
      "name": "block_all",
      "domains": [
        "*"
      ],
      "routes": [
        {
          "match": {
            "prefix": "/"
          },
          "directResponse": {
            "status": 502
          }
        }
      ]
    }
  {{< /text >}}

  该路由被设置为响应码是 502 的[直接响应](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route_components.proto#envoy-api-field-route-route-direct-response)，这意味着如果没有其他路由匹配，则 Envoy 代理将直接返回 502 HTTP 状态代码。

* **PassthroughCluster** - 当将 `global.outboundTrafficPolicy.mode` 设置为 `ALLOW_ANY` 时，
  PassthroughCluster 是在 Envoy 配置中创建的虚拟集群。在此模式下，允许流向外部服务的所有流量。
  为了实现此目的，将使用 `SO_ORIGINAL_DST` 且监听 `0.0.0.0:15001` 的默认虚拟出站监听器设置为 TCP 代理，并将 PassthroughCluster 作为静态集群。
   PassthroughCluster 的配置如下所示：

  {{< text json >}}
    {
      "name": "PassthroughCluster",
      "type": "ORIGINAL_DST",
      "connectTimeout": "10s",
      "lbPolicy": "ORIGINAL_DST_LB",
      "circuitBreakers": {
        "thresholds": [
          {
            "maxConnections": 102400,
            "maxRetries": 1024
          }
        ]
      }
    }
  {{< /text >}}

  该集群使用[原始目标负载均衡策略](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#original-destination)，
  该策略将 Envoy 配置为将流量发送到原始目标，即透传。

  与 BlackHoleCluster 类似，对于每个基于端口/协议的监听器，虚拟路由配置都会添加 PassthroughCluster 以作为默认路由：

  {{< text json >}}
    {
      "name": "allow_any",
      "domains": [
        "*"
      ],
      "routes": [
        {
          "match": {
            "prefix": "/"
          },
          "route": {
            "cluster": "PassthroughCluster"
          }
        }
      ]
    }
  {{< /text >}}

在 Istio 1.3 之前，没有流量报告，即使流量报告到达这些群集，也没有报告明确的标签设置，从而导致流经网格的流量缺乏可见性。

下一节将介绍如何利用此增强功能，因为发出的指标和标签取决于是否命中了虚拟出站或显式端口/协议监听器。

## 使用增强指标{#using-the-augmented-metrics}

要捕获两种情况（ BlackHole 或 Passthrough）中的所有外部服务流量，你将需要监控 `istio_requests_total` 和 `istio_tcp_connections_closed_total` 指标。
根据 Envoy 监听器的类型，即被调用的 TCP 代理或 HTTP 代理，将增加相应的指标。

此外，如果使用 TCP 代理监听器以查看被 BlackHole 阻止或被 Passthrough 透传的外部服务的 IP 地址，
则需要将 `destination_ip` 标签添加到 `istio_tcp_connections_closed_total` 指标。
在这种情况下，不会捕获外部服务的主机名。默认情况下不添加此标签，但是可以通过扩展 Istio 配置以生成属性和 Prometheus 处理程序，轻松地添加此标签。
如果你有许多服务的 IP 地址不稳定，则应注意时序的基数爆炸。

### PassthroughCluster 指标{#pass-through-cluster-metrics}

本节将说明基于被 Envoy 调用的监听器类型的指标和发出的标签。

* HTTP 代理监听器: 当外部服务的端口与集群中定义的服务端口之一相同时，就会触发这种情况。
  在这种情况下，当命中 PassthroughCluster 时，指标 `istio_requests_total` 会增加类似以下内容：

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_requests_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_principal": "unknown",
        "destination_service": "httpbin.org",
        "destination_service_name": "PassthroughCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "permissive_response_code": "none",
        "permissive_response_policyid": "none",
        "reporter": "source",
        "request_protocol": "http",
        "response_code": "200",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567033080.282,
        "1"
      ]
    }
  {{< /text >}}

  请注意，标签 `destination_service_name` 设置为 PassthroughCluster，以表明已命中该集群，而 `destination_service` 设置为外部服务的主机。

* TCP 代理虚拟监听器 - 如果外部服务端口未映射到集群中任何基于 HTTP 的服务端口，则将调用此监听器，
  并且会增加指标 `istio_tcp_connections_closed_total`:

  {{< text json >}}
    {
      "status": "success",
      "data": {
        "resultType": "vector",
        "result": [
          {
            "metric": {
              "__name__": "istio_tcp_connections_closed_total",
              "connection_security_policy": "unknown",
              "destination_app": "unknown",
              "destination_ip": "52.22.188.80",
              "destination_principal": "unknown",
              "destination_service": "unknown",
              "destination_service_name": "PassthroughCluster",
              "destination_service_namespace": "unknown",
              "destination_version": "unknown",
              "destination_workload": "unknown",
              "destination_workload_namespace": "unknown",
              "instance": "100.96.2.183:42422",
              "job": "istio-mesh",
              "reporter": "source",
              "response_flags": "-",
              "source_app": "sleep",
              "source_principal": "unknown",
              "source_version": "unknown",
              "source_workload": "sleep",
              "source_workload_namespace": "default"
            },
            "value": [
              1567033761.879,
              "1"
            ]
          }
        ]
      }
    }
  {{< /text >}}

  在这种情况下，`destination_service_name` 设置为 PassthroughCluster，而 `destination_ip` 设置为外部服务的 IP 地址。
  标签 `destination_ip` 可用于执行反向 DNS 查找并获取外部服务的主机名。
  在通过该集群时，还将更新其他与 TCP 相关的指标，例如 `istio_tcp_connections_opened_total`，
  `istio_tcp_received_bytes_total` 和 `istio_tcp_sent_bytes_total`。

### BlackHoleCluster 指标{#black-hole-cluster-metrics}

与 PassthroughCluster 类似，本节将说明基于被 Envoy 调用的监听器类型的指标和发出的标签。

* HTTP 代理监听器: 这种情况发生在外部服务的端口与群集中定义的服务端口之一相同时。
  在这种情况下，如果命中了 BlackHoleCluster，标签 `istio_requests_total` 会增加类似以下的内容：

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_requests_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_principal": "unknown",
        "destination_service": "httpbin.org",
        "destination_service_name": "BlackHoleCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "permissive_response_code": "none",
        "permissive_response_policyid": "none",
        "reporter": "source",
        "request_protocol": "http",
        "response_code": "502",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567034251.717,
        "1"
      ]
    }
  {{< /text >}}

  请注意，标签 `destination_service_name` 设置为 BlackHoleCluster，而 `destination_service` 设置为外部服务的主机名。
  在这种情况下，响应码应始终为 502。

* TCP 代理虚拟监听器 - 如果外部服务端口未映射到集群中任何基于 HTTP 的服务端口，则会调用此监听器，
  并增加指标 `istio_tcp_connections_closed_total`：

  {{< text json >}}
    {
      "metric": {
        "__name__": "istio_tcp_connections_closed_total",
        "connection_security_policy": "unknown",
        "destination_app": "unknown",
        "destination_ip": "52.22.188.80",
        "destination_principal": "unknown",
        "destination_service": "unknown",
        "destination_service_name": "BlackHoleCluster",
        "destination_service_namespace": "unknown",
        "destination_version": "unknown",
        "destination_workload": "unknown",
        "destination_workload_namespace": "unknown",
        "instance": "100.96.2.183:42422",
        "job": "istio-mesh",
        "reporter": "source",
        "response_flags": "-",
        "source_app": "sleep",
        "source_principal": "unknown",
        "source_version": "unknown",
        "source_workload": "sleep",
        "source_workload_namespace": "default"
      },
      "value": [
        1567034481.03,
        "1"
      ]
    }
  {{< /text >}}

  请注意，标签 `destination_ip` 表示外部服务的 IP 地址，而 `destination_service_name` 设置为 BlackHoleCluster，表示此流量已被网格阻止。
  有趣的是，对于 BlackHole 集群，由于未建立任何连接，因此其他与 TCP 相关的指标（例如 `istio_tcp_connections_opened_total`）不会增加。

监控这些指标可以帮助管理员轻松了解其集群中的应用程序接收的所有外部服务。
