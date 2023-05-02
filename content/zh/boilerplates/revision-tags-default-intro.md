---
---
标签 `default` 指向的修订版本被认为是**默认的修订版本**，并具有额外的语义含义。
默认版本的功能如下：

- 为 `istio-injection=enabled` 命名空间选择器，`sidecar.istio.io/inject=true` 对象选择器
  和 `istio.io/rev=default` 选择器注入 Sidecar。
- 验证 Istio 资源。
- 从非默认的修订版本中窃取 leader 锁并执行单例网格任务（例如更新资源状态）。

要将修订版本 `{{< istio_full_version_revision >}}` 设为默认版本，请运行以下命令：
