---
title: 使用 Ansible 安装
description: 使用内置的 Ansible playbook 安装 Istio。
weight: 40
keywords: [kubernetes,ansible]
---

使用 Ansible 安装和配置 Istio 的说明。

## 先决条件

1. [下载对应的 Istio 版本](/zh/docs/setup/kubernetes/download-release/)。

1. 执行所有必要的[平台特定配置](/zh/docs/setup/kubernetes/platform-setup/)。

1. [安装 Ansible 2.4](https://docs.ansible.com/ansible/latest/intro_installation.html).

如果使用 OpenShift，必须满足以下先决条件。

* 最低版本：**3.9.0**
* **oc** 配置为可以访问集群
* 用户已登录到集群
* 用户在 OpenShift 上具有 `cluster-admin` 角色

## 使用 Ansible 进行部署

**重要**：`Ansible playbook` 的所有执行都必须在 Istio 的 `install/kubernetes/ansible` 路径中进行。

此 `playbook` 将在您的机器上下载并本地安装 Istio。需要在 OpenShift 上部署默认配置的 Istio，可以使用以下命令：

{{< text bash >}}
$ ansible-playbook main.yml
{{< /text >}}

## 使用 Ansible 进行自定义安装

{{< warning >}}
所有 Ansible `playbook` 都必须在 Istio 的 `install/kubernetes/ansible` 目录下执行。
{{< /warning >}}

`Ansible playbook` 附带了合理的默认值。

目前公开的选项有：

| 参数 | 描述 | 值 | 默认值 |
| --- | --- | --- | --- |
| `cluster_flavour` | 定义目标集群类型 | `k8s` 或 `ocp` | `ocp` |
| `cmd_path` | 自定义 `kubectl` 或 `oc` 路径 | 到 `kubectl` 或 `oc` 二进制文件的有效路径 | `$PATH/oc` |
| `istio.auth` | 使用双向 TLS 进行安装 | `true` 或 `false` | `false` |
| `istio.delete_resources` | 删除 Istio 命名空间下安装的资源 | `true` 或 `false` | false |
| `istio.samples` | 包含应该安装的示例的名称的数组 | `bookinfo`, `helloworld`, `httpbin`, `sleep` | none |

## 默认安装

运维人员使用所有默认选项在 OpenShift 上安装 Istio：

{{< text bash >}}
$ ansible-playbook main.yml
{{< /text >}}

## 可选覆盖

在某些情况下，默认值可能需要被覆盖。

以下命令描述了运维人员如何覆盖 `Ansible playbook` 的默认值：

运维人员在 Kubernetes 上安装 Istio：

{{< text bash >}}
$ ansible-playbook main.yml -e '{"cluster_flavour": "k8s"}'
{{< /text >}}

运维人员在 Kubernetes 上安装 Istio 并显式指定 `kubectl` 的路径：

{{< text bash >}}
$ ansible-playbook main.yml -e '{"cluster_flavour": "k8s", "cmd_path": "~/kubectl"}'
{{< /text >}}

运维人员在 OpenShift 上安装 Istio，使用非默认配置：

{{< text bash >}}
$ ansible-playbook main.yml -e '{"istio": {"auth": true, "delete_resources": true}}'
{{< /text >}}

运维人员在 OpenShift 上安装 Istio 并额外部署了一些示例：

{{< text bash >}}
$ ansible-playbook main.yml -e '{"istio": {"samples": ["helloworld", "bookinfo"]}}'
{{< /text >}}

## 卸载

如果需要不同版本的 Istio，请在执行 `playbook` 之前删除 `istio-system` 命名空间。
这种情况下，不需要设置 `istio.delete_resources` 参数。

将 `istio.delete_resources` 设置为 true 会从集群中删除 Istio 控制平面。

{{< warning >}}
为了避免任何不一致，该标志只能在集群上重新安装相同版本的 Istio 时使用。
{{< /warning >}}
