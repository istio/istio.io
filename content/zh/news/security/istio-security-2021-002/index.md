---
title: ISTIO-SECURITY-2021-002
subtitle: 安全公告
description: 由于容器端口的更改，从旧 Istio 版本升级可能会影响入口网关的访问控制。
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["All releases 1.6 and later"]
publishdate: 2021-04-07
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

从 Istio 1.5 及更早版本升级到 1.6 及更高版本，可能会导致入口流量绕过 Istio 访问控制：

- **升级授权策略上的网关端口不正确**：在 Istio 1.6 及更高版本中，Istio 入口网关的默认容器端口从端口”80“更新为“8080”，“443”更新为“8443”，
以默认允许[网关以非 root 账户运行](/zh/news/releases/1.7.x/announcing-1.7/upgrade-notes/#gateways-run-as-non-root)。
通过此更改，在升级到上述的版本之前，需要迁移任何针对端口 `80` 和 `443` 上的 Istio 入口网关的现有授权策略，以使用新的容器端口 `8080` 和 `8443`。
迁移失败可能导致到达入口网关业务端口 `80` 和 `443` 的流量被错误地允许或阻断，从而导致策略违规。

需要更新的授权策略资源示例：

    {{< text yaml >}}
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: block-admin-access
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      action: DENY
      rules:
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "80" ]
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "443" ]

    {{< /text >}}

在 Istio 1.5 版本及之前版本中，上述策略将阻止到达容器端口 `80` 和 `443` 上的 Istio 入口网关的所有访问路径 `/admin` 的流量。
在升级到 Istio 1.6 及更高版本时，应将此策略更新为以下内容，以达到相同的效果：

    {{< text yaml >}}
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: block-admin-access
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      action: DENY
      rules:
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "8080" ]
      -  to:
        - operation:
            paths: ["/admin"]
            ports: [ "8443"
    {{< /text >}}

## 防范{#mitigation}

- 升级到受影响的Istio版本之前，请更新授权策略。
您可以使用这个[脚本](./check.sh)检查是否需要更新附加到 `istio-system` 命名空间中 Istio 入口网关默认的现有授权策略。
如果您使用的是自定义网关安装，则可以自定义脚本以使用适用于您的环境的参数运行。

建议创建现有授权策略的副本，并更新授权策略副本以使用新的网关工作负载端口，之后在集群中同时使用应用现有的和已更新的策略，最后再启动升级过程。
您应该只在升级成功后删除旧策略，以确保升级失败或回滚时不会发生违反策略的情况。

## 鸣谢{#credit}

我们要感谢 [Neeraj Poddar](https://twitter.com/nrjpoddar) 报告此问题。

{{< boilerplate "安全漏洞" >}}
