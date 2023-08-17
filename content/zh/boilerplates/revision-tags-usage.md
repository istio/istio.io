---
---
考虑到一个安装了 `{{< istio_previous_version_revision >}}-1` 和 `{{< istio_full_version_revision >}}` 两个修订版本的集群。集群管理员创建了一个 `prod-stable` 修订标签，
以指向较旧的 `{{< istio_previous_version_revision >}}-1` 稳定版本，并创建一个 `prod-canary` 修订标签，用以指向较新的 `{{< istio_full_version_revision >}}` 修订版本。
可以通过以下命令达到该状态：
