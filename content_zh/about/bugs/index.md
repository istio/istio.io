---
title: 报告 Bugs
description: 如果你发现了 bug 该怎么做。
weight: 34
page_icon: /img/bugs.svg
---

哦不！你发现了bug？

在我们的 [issue 数据库](https://github.com/istio/istio/issues/)中搜索，你可以找到这是否是一个已知问题，和我们打算在什么时候修复它。如果你没有在数据库中找到，请提一个[新的 issue](https://github.com/istio/istio/issues/new/choose)告诉我们发生了什么。

如果你认为这是一个安全漏洞的问题，请访问[报告安全漏洞](/about/security-vulnerabilities/)以了解该做什么。

如果你在 Kubernetes 上运行，考虑将[集群状态归档文件](#生成集群状态归档文件)附加在你的 bug 报告中。

## 生成集群状态归档文件

为了方便起见，你可以执行一个拷贝脚本来生成包含 Kubernetes 集群所有需要状态：

* 通过 `curl` 执行:

    {{< text bash >}}
    $ curl {{< github_file >}}/tools/dump_kubernetes.sh | sh -s -- -z
    {{< /text >}}

* 在本地执行，从发布目录的根目录：

    {{< text bash >}}
    $ @tools/dump_kubernetes.sh@ -z
    {{< /text >}}

然后在你的问题报告中加上生成的 `istio-dump.tar.gz` 文件

如果你不能使用上面的脚本，请附上如下信息：

* 所有命名空间下的 Pods、services、deployments 和 endpoints

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* `istio-system` 中的 Secret 名字：

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* `istio-system` 命名空间下的 configmaps:

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* 现在和之前的 Istio 组件和 sidecar 中的日志

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

* 所有的 Istio 配置:

    {{< text bash >}}
    $ kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces
    {{< /text >}}
