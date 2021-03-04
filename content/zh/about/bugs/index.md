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

搜索我们的[问题数据库](https://github.com/istio/istio/issues/)来查看是否我们已经知道您的问题，并了解何时可以解决它。如果您在该数据库中没有找到你的问题，请打开一个[新问题](https://github.com/istio/istio/issues/new/choose)让我们知道出现了什么错误。

如果您认为错误实际上是一个安全漏洞，请访问[报告安全漏洞](/zh/about/security-vulnerabilities/)了解如何处理。

### Kubernetes 集群状态档案{#Kubernetes-cluster-state-archives}

如果您正在运行 Kubernetes，请考虑使用错误报告将集群状态存档。为了方便起见，您可以运行 istioctl bug-report 命令生成一个档案，该档案包含 Kubernetes 集群中所有相关的状态：

* 运行：

    {{< text bash >}}
    $ istioctl bug-report
    {{< /text >}}

然后将得到的 `bug-report.tgz` 文件一起报告。

{{< tip >}}
`istioctl bug-report` 仅在 istioctl 1.8.0 及以上的版本存在，这个命令依然可以对已经安装的较低版本 Istio 生效。
{{< /tip >}}

如果你如法使用 bug-report 命令，可以使用以下方案搜集信息：

* 所有 pods, services, deployments, endpoints 资源:

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* `istio-system` 下的 Secret:

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* `istio-system` 下的 ConfigMap:

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* Istio 组件日志和 Sidecar 的日志

* Istiod 日志:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l app=istiod
    {{< /text >}}

* 所有 Istio 配置:

    {{< text bash >}}
    $ kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces
    {{< /text >}}

## 文档错误{#documentation-bugs}

搜索我们的[文档问题数据库](https://github.com/istio/istio.io/issues/)以查看是否我们已经知道您的问题，并了解何时可以解决它。如果您在该数据库中找不到问题，请导航到这个问题的页面，然后在页面的右上角选择齿轮菜单，最后选择 *Report a Site Bug*。
