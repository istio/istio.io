---
title: Kops
description: 为 Istio 搭建 Kops 的设置说明。
weight: 33
skip_seealso: true
keywords: [platform-setup,kubernetes,kops]
owner: istio/wg-environments-maintainers
test: no
---

{{< tip >}}
在 Kubernetes 集群 1.22 或更高版本上运行 Istio 不需要特殊配置。对于以前的 Kubernetes 版本，您将需要继续执行这些步骤。
{{< /tip >}}

如果您想要在 Kops 管理的集群上为网格运行 Istio [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) (SDS)，
必须添加[附加配置](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection)，
以便在 API 服务器中启动服务账户令牌投射卷。

1. 打开配置文件：

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. 在配置文件中添加以下内容：

    {{< text yaml >}}
    kubeAPIServer:
        apiAudiences:
        - api
        - istio-ca
        serviceAccountIssuer: kubernetes.default.svc
    {{< /text >}}

1. 执行以下更新：

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. 进行滚动更新：

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}
