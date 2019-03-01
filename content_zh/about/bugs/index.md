---
title: 报告 Bug
description: 发现 Bug 怎么办。
weight: 34
icon: bugs
---

哦不！你发现了 Bug？我们很乐于倾听。

## 产品 Bug

在我们的 [Issue 数据库](https://github.com/istio/istio/issues/)中搜索，看看这一 Bug 是不是一个已知问题，以及我们打算在什么时候修复它。如果你没有在数据库中找到，请提交一个[新 Issue](https://github.com/istio/istio/issues/new/choose)告诉我们发生了什么。

如果你认为这是一个安全漏洞，请访问[报告安全漏洞](/about/security-vulnerabilities/)页面以了解其报告步骤。

## 生成集群状态归档文件

如果你在 Kubernetes 上运行，考虑将集群状态归档文件附加在你的 Bug 报告中。

为了方便起见，你可以执行一个拷贝脚本来生成包含 Kubernetes 集群所有需要状态：

* 通过 `curl` 执行:

    {{< text bash >}}
    $ curl {{< github_file >}}/tools/dump_kubernetes.sh | sh -s -- -z
    {{< /text >}}

* 在本地执行，从发布目录的根目录：

    {{< text bash >}}
    $ @tools/dump_kubernetes.sh@ -z
    {{< /text >}}

然后在你的问题报告中加上生成的 `istio-dump.tar.gz` 文件。

如果你不能使用上面的脚本，请附上如下信息：

* 所有命名空间下的 Pod、Service、Deployment 和 Endpoint：

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* `istio-system` 中的 Secret 的名字：

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* `istio-system` 命名空间下的 Configmap：

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* Istio 组件和 Sidecar 中的日志

* Mixer 日志：

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=mixer -c mixer
    $ kubectl logs -n istio-system -l istio=policy -c mixer
    $ kubectl logs -n istio-system -l istio=telemetry -c mixer
    {{< /text >}}

* Pilot 日志:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=pilot -c discovery
    $ kubectl logs -n istio-system -l istio=pilot -c istio-proxy
    {{< /text >}}

* 所有的 Istio 组件配置：

    {{< text bash >}}
    $ kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces
    {{< /text >}}

## 文档 Bug

在我们的[文档 Issue 数据库](https://github.com/istio/istio.io/issues/)中搜索，看看是不是现存问题，以及我们预期的修复时间。如果没有找到你要提出的问题，请浏览有问题的页面，点击页面右上角的齿轮菜单，选择**报告网站 Bug**。