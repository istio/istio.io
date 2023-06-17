---
title: 发布 Istio 1.6.9
linktitle: 1.6.9
subtitle: 补丁更新
description: Istio 1.6.9 补丁更新。
publishdate: 2020-09-09
release: 1.6.9
aliases:
    - /news/announcing-1.6.9
---

此版本包含修复错误以提高健壮性。本版本说明介绍了 Istio 1.6.8 和 Istio 1.6.9 之间的差异。


{{< relnote >}}

## 变更

- **添加** `istioctl analyzer` 来检测 Destination Rules 未指定 `caCertificates` 时的情况 ([Istio #25652](https://github.com/istio/istio/issues/25652))
- **添加** 在 Mixer 容器参数中了缺失的 `telemetry.loadshedding.*` 选项
- **修复** 没有 `Header` 的 HTTP 匹配请求冲突
- **修复** Istio 运算符以同时监视多个命名空间([Istio #26317](https://github.com/istio/istio/issues/26317))
- **修复** 当端点出现在其服务资源之后时 `EDS` 缓存 ([Istio #26983](https://github.com/istio/istio/issues/26983))
- **修复** CNI 安装中 `istioctl remove-from-mesh` 未删除初始化容器的问题。
- **修复** `istioctl` `add-to-mesh` 和 `remove-from-mesh` 命令对 `OwnerReferences` 的影响 ([Istio #26720](https://github.com/istio/istio/issues/26720))
- **修复** 清理群集密钥被删除时的服务信息
- **修复** 由于用户权限而将出口网关端口绑定到80/443的问题
- **修复** 出站流量方向创建的网关监听器将在退出时的启动问题。
- **修复** 节点无法更新侦听器（[Istio＃26617](https://github.com/istio/istio/issues/26617)）
- **修复** 精度不准确的 `endpointsPendingPodUpdate` 指标
- **修复** SDS 未获取到密钥更新 ([Istio #18912](https://github.com/istio/istio/issues/18912))
- **修复** 账本容量大小
- **修复** 运算符由于无效权限而无法更新服务监视器的问题 ([Istio #26961](https://github.com/istio/istio/issues/26961))
- **修复** 网关名称解析回归问题（[Istio 26264](https://github.com/istio/istio/issues/26264)）
- **修复** 证书未存储到 `/etc/istio-certs` `VolumeMount` 中
- **修复** 传输套接字级别上验证信任域（[Istio #26435](https://github.com/istio/istio/issues/26435)）
- **改进** 对没有配置 `meshNetworks` 的群集指定网络
- **改进** 使用 TTL 的缓存可用性状态([Istio #26418](https://github.com/istio/istio/issues/26418))
- **更新** 了 SDS 获取工作负载证书的超时时间为`0s`
- **更新** `app_containers` 为使用逗号分隔的值进行容器规范。
- **更新** 默认协议嗅探超时时间为 `5s`([Istio #24379](https://github.com/istio/istio/issues/24379))。