---
title: 安全管理 Webhook
description: 一种更安全管理 Istio Webhook 的方法。
publishdate: 2019-11-14
attribution: Lei Tang (Google)
keywords: [security, kubernetes, webhook]
target_release: 1.4
---

`Istio` 有两个 `Webhook`，分别是 `Galley` 和 `Sidecar Injector`。`Galley` 负责验证 `Kubernetes` 资源，`Sidecar Injector` 负责将 `Sidecar` 容器注入 `Istio`中。

默认情况下，`Galley` 和 `Sidecar Injector` 管理它们自己 `Webhook` 的配置。如果出现漏洞（例如，缓冲区溢出）它们便会受到威胁，可能会带来一些安全隐患。所以，配置 `Webhook` 是一项权限很高的操作，因为 `Webhook` 会监控和更改所有 `Kubernetes` 资源。

在以下示例中，攻击者破坏了 `Galley` 并修改了 `Galley` 的 `Webhook` 配置，以便于窃听所有 `Kubernetes` 机密（攻击者对 `clientConfig` 进行了修改，将 `Secret` 资源改变为攻击者自己所拥有的服务）。

{{< image width="70%"
    link="./example_attack.png"
    caption="攻击示例"
    >}}

为了防止这种攻击，`Istio` 1.4 引入了一项新功能，可以使用 `istioctl` 更安全地管理 `Webhook`：

1. `istioctl` 替代 `Galley` 和 `Sidecar Injector` 去管理 `Webhook` 配置。`Galley` 和 `Sidecar Injector` 已经被解除特殊权限，因此即便受到侵入，它们也无法更改 `Webhook` 的配置。

1. 在配置 `Webhook` 前，`istioctl` 将验证 `Webhook` 服务器是否已启动和该 `Webhook` 服务器使用的证书链是否有效。这样可以减少在服务器就绪之前或服务器证书失效时可能发生的错误。

要尝试此新功能，请参阅 [Istio Webhook 管理内容](https://archive.istio.io/v1.4/docs/tasks/security/webhook)。
