---
title: 报告错误
description: 如果发现错误该怎么办。
weight: 34
aliases:
    - /zh/bugs.html
    - /zh/bugs/index.html
    - /zh/help/bugs/
icon: bugs
---

不好！您发现了一个错误？我们希望知道这一点。

## 产品错误{#product-bugs}

搜索我们的 [问题数据库](https://github.com/istio/istio/issues/) 来查看是否我们已经知道您的问题，并了解何时可以解决它。如果您在该数据库中没有找到你的问题，请打开一个 [新问题](https://github.com/istio/istio/issues/new/choose) 让我们知道出现了什么错误。

如果您认为错误实际上是一个安全漏洞，请访问 [报告安全漏洞](/about/security-vulnerabilities/) 了解如何处理。

### Kubernetes 集群状态档案{#Kubernetes-cluster-state-archives}

如果您正在运行 Kubernetes，请考虑使用错误报告将集群状态存档。为了方便起见，您可以运行转储脚本生成一个档案，该档案包含 Kubernetes 集群中所有相关的状态：

* 运行 `curl`：

    {{< text bash >}}
    $ curl {{< github_file >}}/tools/dump_kubernetes.sh | sh -s -- -z
    {{< /text >}}

* 在发布版本目录的根目录本地运行：

    {{< text bash >}}
    $ @tools/dump_kubernetes.sh@ -z
    {{< /text >}}

然后，将产生的 `istio-dump.tar.gz` 与您的报告问题连接。

如果您无法使用转储脚本，请附加自己的存档
包含：

* 在所有命名空间中的 pods、services、deployments 和 endpoints：

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* 在 `istio-system` 中的密名：

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* 在 `istio-system` 命名空间的 configmap：

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* 所有 Istio 组件和 sidecar 的当前和以前的日志

* Mixer logs:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=mixer -c mixer
    $ kubectl logs -n istio-system -l istio=policy -c mixer
    $ kubectl logs -n istio-system -l istio=telemetry -c mixer
    {{< /text >}}

* Pilot logs:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=pilot -c discovery
    $ kubectl logs -n istio-system -l istio=pilot -c istio-proxy
    {{< /text >}}

* 所有 Istio 配置工件：

    {{< text bash >}}
    $ kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces
    {{< /text >}}

## 文档错误{#documentation-bugs}

搜索我们的 [文档问题数据库](https://github.com/istio/istio.io/issues/) 以查看是否我们已经知道您的问题，并了解何时可以解决它。如果您在该数据库中找不到问题，请导航到这个问题的页面，然后在页面的右上角选择齿轮菜单，最后选择 *Report a Site Bug*。
