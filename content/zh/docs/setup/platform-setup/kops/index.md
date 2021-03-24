---
title: Kops
description: 与Istio 一起使用的 Kops 设置说明。
weight: 33
skip_seealso: true
keywords: [platform-setup,kubernetes,kops]
owner: istio/wg-environments-maintainers
test: no
---

如果您想要在 Kops 管理的集群上为 Mesh 运行 Istio [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) (SDS)，必须添加 [Extra Configurations](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection)，以便在 API Server 中启动服务令牌 Projection Volumes。

1. 打开配置文件:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. 在配置文件中添加以下内容:

    {{< text yaml >}}
    kubeAPIServer:
        apiAudiences:
        - api
        - istio-ca
        serviceAccountIssuer: kubernetes.default.svc
    {{< /text >}}

1. 更新:

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. 进行滚动更新:

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}
