---
title: Istio 1.12 变更说明
linktitle: 1.12.0
subtitle: 次要版本
description: Istio 1.12.0 变更说明。
publishdate: 2021-11-18
release: 1.12.0
weight: 10
aliases:
    - /zh/news/announcing-1.12.0
---

## 流量管理{#traffic-management}

- **改进** 改进了对带有未声明协议的无头服务的支持，不再需要特定的 `Host` 标头。
  ([Issue #34679](https://github.com/istio/istio/issues/34679))

- **新增** 在 VirtualService 中新增了空正则表达式匹配的验证器，防止无效的 Envoy 配置。
  ([Issue #34065](https://github.com/istio/istio/issues/34065))

- **新增** 新增了对 TCP 流量 `useSourceIP` [一致哈希负载均衡的](/zh/docs/reference/config/networking/destination-rule/#LoadBalancerSettings-ConsistentHashLB)支持，在以前，这只支持 HTTP。
  ([Issue #33558](https://github.com/istio/istio/issues/33558))

- **新增** 新增了对 Envoy 的支持，以在排空期间跟踪活动连接，并在活动连接变为零时退出，而不是等待整个排空持续进行。默认情况下这是禁用的，可以通过设置 `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` 为 true 来启用。
  ([Issue #34855](https://github.com/istio/istio/issues/34855))

- **新增** 新增了对无代理的 gRPC 客户端 `DestinationRule` 中 `trafficPolicy.loadBalancer.consistentHash` 的支持。
  ([Pull Request #35333](https://github.com/istio/istio/pull/35333))

- **新增** 新增了在 ServiceEntry 中，用户可以使用 `DNS_ROUND_ROBIN` 将指定 Envoy 的 `LOGICAL_DNS` 作为集群的连接类型功能。
  ([Issue #35475](https://github.com/istio/istio/issues/35475))

- **新增** 新增了 `failoverPriority` 负载均衡流量策略，允许用户设置用于排序端点的有序标签列表，用于对端点进行排序，以实现基于优先级的负载均衡。
  ([Pull Request #34740](https://github.com/istio/istio/pull/34740))

- **新增** 新增了为网关上的非直通 HTTPS 侦听器创建镜像 QUIC 侦听器的支持。
  ([Pull Request #33817](https://github.com/istio/istio/pull/33817))

- **新增** 新增了 `v1alpha2` 版本对 [gateway-api](https://gateway-api.org/) 的支持。
  ([Pull Request #35009](https://github.com/istio/istio/pull/35009))

- **新增** 新增了 `cluster.local` 根据 Kubernetes 多集群服务（MCS）规范定义的本地主机行为的实验性支持。这个特性在默认情况下是关闭的，但是可以通过在 Istio 中设置以下标志来启用：`ENABLE_MCS_CLUSTER_LOCAL`，`ENABLE_MCS_HOST` 和 `ENABLE_MCS_SERVICE_DISCOVERY`。启用后，对 `cluster.local` 主机的请求将仅路由到与客户端位于同一集群中的端点。
  ([Issue #35424](https://github.com/istio/istio/issues/35424))

- **修复** 修复了 TCP 探针。当使用旧版本的 Istio 的 TCP 探针时，检查总是成功的，即使应用程序没有打开端口。
  ([details](/zh/news/releases/1.12.x/announcing-1.12/upgrade-notes/#tcp-probes-now-working-as-expected))

- **修复** 修复了当权重为 `0` 时，Gateway API xRoute 不会将流量转发到该后端的问题。
  ([Issue #34129](https://github.com/istio/istio/issues/34129))

- **修复** 修复了 ADS 由于提供的 `syncCh` 大小错误而挂起的问题。
  ([Pull Request #34633](https://github.com/istio/istio/pull/34633))

- **修复** 修复了导致名称相同但命名空间不同的 Ingress 资源冲突的问题。
  ([Issue #31833](https://github.com/istio/istio/issues/31833))

## 安全{#security}

- **改进** 改进了 TLS 认证 Secret 监视的性能使用以减少内存使用。
  ([Issue #35231](https://github.com/istio/istio/issues/35231))

- **新增** 新增 istiod 通过环境变量 `AUTO_RELOAD_PLUGIN_CERTS` 来通知 `cacerts` 文件更改的支持。
  ([Issue #31522](https://github.com/istio/istio/issues/31522))

- **新增** 在 istiod 中新增了 `VERIFY_CERT_AT_CLIENT` 环境变量。设置 `VERIFY_CERT_AT_CLIENT` 环境变量为 `true` 时，将在不使用 `DestinationRule` `caCertificates` 字段时，使用 OS CA 证书验证服务器证书。
  ([Issue #33472](https://github.com/istio/istio/issues/33472))

- **新增** 新增了工作负载级别自动 mTLS 对等身份验证的支持。当服务器配置了工作负载级别的对等身份验证策略时，您不再需要配置目标规则。这可以通过设置 `ENABLE_AUTO_MTLS_CHECK_POLICIES` 为 `false` 来禁用。
  ([Issue #33809](https://github.com/istio/istio/issues/33809))

- **新增** 新增了对 GKE 工作负载证书集成的支持。
  ([Issue #35385](https://github.com/istio/istio/issues/35385))

- **新增** 向 Istio 网关 Helm charts 新增了用于在 ServiceAccount 上配置注释的值。可用于为 AWS EKS 上的[Service Accounts 启用 IAM Roles](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)。
  ([Pull Request #33914](https://github.com/istio/istio/pull/33914))

- **新增** 新增了对入口网关上[基于 JWT 声明的路由](/zh/docs/tasks/security/authentication/jwt-route)的支持
  ([Pull Request #35762](https://github.com/istio/istio/pull/35762))

- **修复** 修复了 `EnvoyExternalAuthorizationHttpProvider` 以不区分大小写的方式匹配 HTTP 标头的问题。
  ([Issue #35220](https://github.com/istio/istio/issues/35220))

- **提升** 将[外部授权](/zh/docs/tasks/security/authorization/authz-custom)特性从实验版提升到 Alpha 版。
  ([Pull Request #104](https://github.com/istio/enhancements/pull/104))

## 遥测{#telemetry}

- **修复** 修复了规范修订的 `WorkloadGroup` 和 `WorkloadEntry` 标签的问题.
  ([Issue #34395](https://github.com/istio/istio/issues/34395))

## 可扩展性{#extensibility}

- **添加** 添加了对 Istio `WasmPlugin` API 的支持。
  ([Pull Request #33374](https://github.com/istio/istio/pull/33374))

## 安装{#installation}

- **更新** 更新了 `istioctl tag set default` 来控制哪个版本处理 Istio 资源验证。
通过默认标签指示的修订版本也将赢得领导选举资源和承担单例集群责任。
  ([Pull Request #35286](https://github.com/istio/istio/pull/35286))

- **新增** 在 Pod 级别为 istio-operator 和 istiod 新增了标签。
  ([Issue #33879](https://github.com/istio/istio/issues/33879))

- **新增** 在 helm chart 上新增了 pilot 服务注释。
  ([Issue #35229](https://github.com/istio/istio/issues/35229))

- **新增** 新增了 Operator 对 arm64 API 的支持，以及新增了 nodeAffinity arm64 表达式。
  ([Pull Request #35648](https://github.com/istio/istio/pull/35648))

- **修复** 修复了使用不同协议（TCP 和 UDP）指定相同端口号导致错误合并和呈现错误的清单的错误。
  ([Issue #33841](https://github.com/istio/istio/issues/33841))

- **修复** 修复了 Istioctl 不等待 CNI DaemonSet 更新的问题。
  ([Issue #34811](https://github.com/istio/istio/issues/34811))

- **修复** 修复了没有权限在主集群中从远端集群列出 `ServiceExport` 的问题。
  ([Issue #35068](https://github.com/istio/istio/issues/35068))

## istioctl{#istioctl}

- **改进** 改进了分析器报告输出以匹配 API 预期的命名方案，即使用 `<ns>/<name>` 代替 `<name>.<ns>`。
  ([Issue #35405](https://github.com/istio/istio/issues/35405))

- **改进** 改进了目标规则 ca 分析器以在使用时显示准确的错误行 `istioctl analyze`，否则它将显示其 yaml 配置块的第一行。
  ([Issue #22872](https://github.com/istio/istio/issues/22872))

- **更新** 将 `istioctl x create-remote-secret` 和 `istioctl x remote-clusters` 更新为最高的命令，
并退出实验。
  ([Issue #33799](https://github.com/istio/istio/issues/33799))

- **新增** `istioctl install` 现在将对 webhook 做 `IST0139` 分析。
  ([Issue #33537](https://github.com/istio/istio/issues/33537))

- **新增** `istioctl x remote-clusters` 以列出每个 `istiod` 实例具有 API Server 凭据的远程集群，
以及每个集群的服务注册表同步状态。
  ([Issue #33799](https://github.com/istio/istio/issues/33799))

- **新增** 新增 pod 的 `po` 别名，供用户使用 `istioctl x describe po` 命令，与使用 `kubectl` 命令时 pod 的别名保持一致。
  ([Pull Request #34802](https://github.com/istio/istio/pull/34802))

- **新增** 预检查现在可以检测 Alpha Annotations 的使用。
  ([Pull Request #35483](https://github.com/istio/istio/pull/35483))

- **新增** `istioctl operator dump` 现在支持通过 `watchedNamespaces` 指定 operator 控制器监视的命名空间参数。
  ([Issue #35485](https://github.com/istio/istio/issues/35485))

- **修复** `istioctl operator` 子命令现在支持在 `--manifests` 参数中指定的远程 URL。
  ([Issue #34896](https://github.com/istio/istio/issues/34896))

- **修复** 修复了 `istioctl admin log` 格式。
  ([Issue #34982](https://github.com/istio/istio/issues/34982))

- **修复了** 修复了在第一次安装 Istio 时没有使用 'istio-system' 作为 Istio 命名空间，APP pods（比如 httpbin）无法创建的问题。`istioctl install`，`istioctl tag set` 和 `istioctl tag generate` 将受到影响。例如，用户可以设置指定的命名空间（以 `mesh-1` 为例），通过 `istioctl install --set profile=demo --set values.global.istioNamespace=mesh-1 -y` 来安装 Istio。
  ([Issue #35539](https://github.com/istio/istio/issues/35539))

- **修复** 修复了当 `--exclude` 没有设置时，`istioctl bug-report` 会显示额外的默认系统命名空间的问题。
  ([Issue #35593](https://github.com/istio/istio/issues/35593))

- **修复** 通过添加补丁版本修复了发布 tar URL 的问题。
  ([Pull Request #35712](https://github.com/istio/istio/pull/35712))

- **Fixed** 修复了 istioctl 错误报告中 --context 和 --kubeconfig 没有得到尊重的问题。
  ([Issue #35574](https://github.com/istio/istio/issues/35574))
