---
title: Pod 和 Service
description: 在启用了 Istio 的集群中运行 Kubernetes 的 Pod 和 Service，您需要做些准备。
weight: 40
keywords:
  - kubernetes
  - sidecar
  - sidecar-injection
  - deployment-models
  - pods
  - setup
aliases:
  - /zh/docs/setup/kubernetes/spec-requirements/
  - /zh/docs/setup/kubernetes/prepare/spec-requirements/
  - /zh/docs/setup/kubernetes/prepare/requirements/
  - /zh/docs/setup/kubernetes/additional-setup/requirements/
  - /zh/docs/setup/additional-setup/requirements
  - /zh/docs/ops/setup/required-pod-capabilities
  - /zh/help/ops/setup/required-pod-capabilities
  - /zh/docs/ops/prep/requirements
---

作为 Istio 服务网格中的一部分，Kubernetes 集群中的 Pod 和 Service 必须满足以下要求：

- **命名的服务端口**: Service 的端口必须命名。端口名键值对必须按以下格式：`name: <protocol>[-<suffix>]`。更多说明请参看[协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。

- **Service 关联**: 每个 Pod 必须至少属于一个 Kubernetes Service，不管这个 Pod 是否对外暴露端口。如果一个 Pod 同时属于多个 [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/)，
  那么这些 Service 不能同时在一个端口号上使用不同的协议（比如：HTTP 和 TCP）。

- **带有 app 和 version 标签（label）的 Deployment**: 我们建议显式地给 Deployment 加上 `app` 和 `version` 标签。给使用 Kubernetes
  `Deployment` 部署的 Pod 部署配置中增加这些标签，可以给 Istio 收集的指标和遥测信息中增加上下文信息。

    - `app` 标签：每个部署配置应该有一个不同的 `app` 标签并且该标签的值应该有一定意义。`app` label 用于在分布式追踪中添加上下文信息。

    - `version` 标签：这个标签用于在特定方式部署的应用中表示版本。

- **应用 UID**: 确保你的 Pod 不会以用户 ID（UID）为 1337 的用户运行应用。

- **`NET_ADMIN` 功能**: 如果你的集群执行 Pod 安全策略，必须给 Pod 配置 `NET_ADMIN` 功能。如果你使用 [Istio CNI 插件](/zh/docs/setup/additional-setup/cni/)
  可以不配置。要了解更多 `NET_ADMIN` 功能的知识，请查看[所需的 Pod 功能](#required-pod-capabilities)。

## Istio 使用的端口{#ports-used-by-Istio}

Istio 使用了如下的端口和协议。请确保没有 TCP Headless Service 使用了 Istio Service 使用的 TCP 端口。

| 端口 | 协议 | 使用者 | 描述 |
|----|----|----|----|
| 8060 | HTTP | Citadel | GRPC 服务器 |
| 8080 | HTTP | Citadel agent | SDS service 监控 |
| 9090 | HTTP |  Prometheus | Prometheus |
| 9091 | HTTP | Mixer | 策略/遥测 |
| 9876 | HTTP | Citadel, Citadel agent |  ControlZ 用户界面 |
| 9901 | GRPC | Galley| 网格配置协议 |
| 15000 | TCP | Envoy | Envoy 管理端口 (commands/diagnostics) |
| 15001 | TCP | Envoy | Envoy 传出 |
| 15006 | TCP | Envoy | Envoy 传入 |
| 15004 | HTTP | Mixer, Pilot | 策略/遥测 - `mTLS` |
| 15010 | HTTP | Pilot | Pilot service - XDS pilot - 发现 |
| 15011 | TCP | Pilot | Pilot service - `mTLS` - Proxy - 发现 |
| 15014 | HTTP | Citadel, Citadel agent, Galley, Mixer, Pilot, Sidecar Injector | 控制平面监控 |
| 15020 | HTTP | Ingress Gateway | Pilot 健康检查 |
| 15029 | HTTP | Kiali | Kiali 用户界面 |
| 15030 | HTTP | Prometheus | Prometheus 用户界面 |
| 15031 | HTTP | Grafana | Grafana 用户界面 |
| 15032 | HTTP | Tracing | Tracing 用户界面 |
| 15443 | TLS | Ingress and Egress Gateways | SNI |
| 15090 | HTTP | Mixer | Proxy |
| 42422 | TCP | Mixer | 遥测 - Prometheus |

## 所需的 Pod 功能{#required-pod-capabilities}

如果集群中的 [Pod 安全策略](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)被[强制执行](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies)，并且除非您使用 Istio CNI 插件，否则您的 Pod 必须具有允许的 `NET_ADMIN` 功能。Envoy 代理的初始化容器需要此功能。

要检查您的 Pod 是否支持 `NET_ADMIN` 功能，您需要检查其 [service account(服务账户)](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 是否可以使用允许 `NET_ADMIN` 功能的 Pod 安全策略。如果尚未在 Pod 的部署中指定服务帐户，则 Pod 将在其部署的命名空间中使用 `默认` 服务帐户运行。

要实现列出服务帐户的功能，在以下命令中，用您的值替换 `<your namespace>` and `<your service account>`：

{{< text bash >}}
$ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

例如，要检查 `默认` 命名空间中的 `默认` 服务帐户，请运行以下命令：

{{< text bash >}}
$ for psp in $(kubectl get psp -o jsonpath="{range .items[*]}{@.metadata.name}{'\n'}{end}"); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp/$psp --no-headers -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

如果您在服务帐户允许的策略的功能列表中看到 `NET_ADMIN` 或者 `*`，则您的 Pod 有权利运行 Istio 初始化容器。否则，您将需要[提供许可认证](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies)。
