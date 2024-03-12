---
title: 报告错误
description: 如果发现错误该怎么办。
weight: 34
aliases:
    - /zh/bugs.html
    - /zh/bugs/index.html
    - /zh/help/bugs/
    - /zh/about/bugs
    - /zh/latest/about/bugs
icon: bugs
owner: istio/wg-docs-maintainers
test: n/a
---

不好！您发现了一个问题？我们希望知道这一点。

## 产品问题   {#product-bugs}

搜索我们的[问题数据库](https://github.com/istio/istio/issues/)来了解我们是否已经知道您的问题以及何时可以解决它。
如果您在该数据库中没有找到您的问题，
请打开一个[新 Issue](https://github.com/istio/istio/issues/new/choose)让我们知道出现了什么错误。

如果您认为错误实际上是一个安全漏洞，请访问[报告安全漏洞](/zh/about/security-vulnerabilities/)了解如何处理。

### Kubernetes 集群状态存档   {#Kubernetes-cluster-state-archives}

如果您正在运行 Kubernetes，请考虑使用错误报告将集群状态存档。为了方便起见，
您可以运行 `istioctl bug-report` 命令生成一个存档，该存档包含 Kubernetes
集群中所有相关的状态：

{{< text bash >}}
$ istioctl bug-report
{{< /text >}}

然后在您报告问题时随附上刚生成的 `bug-report.tgz`。

如果您的网格跨越了多个集群，对每个集群运行 `istioctl bug-report` 并指定 `--context`
或者 `--kubeconfig` 参数。

{{< tip >}}
`istioctl bug-report` 命令仅适用于 `istioctl` 1.8.0 及以上版本，
但其依然可以对已经安装的较低版本 Istio 生效。
{{< /tip >}}

{{< tip >}}
如果您在大型集群上运行 `bug-report`，它可能无法完成。
请使用 `--include ns1,ns2` 选项仅针对相关命名空间的代理命令和日志集合。如需更多 `bug-report` 选项，
请参阅 [istioctl bug-report 参考](/zh/docs/reference/commands/istioctl/#istioctl-bug-report)。
{{< /tip >}}

如果您无法使用 `bug-report` 命令，请附上您自己的存档包含：

* `istioctl analyze` 的输出：

    {{< text bash >}}
    $ istioctl analyze --all-namespaces
    {{< /text >}}

* 所有命名空间下 `pods`、`services`、`deployments`、`endpoints` 资源：

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* `istio-system` 下的 Secret：

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* `istio-system` 下的 ConfigMap：

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* 来自所有 Istio 组件和 Sidecar 的当前日志和历史日志。这里有一些关于如何获取这些日志的例子，
  请根据您的环境进行调整：

    * Istiod 日志：

        {{< text bash >}}
        $ kubectl logs -n istio-system -l app=istiod
        {{< /text >}}

    * Ingress Gateway 日志：

        {{< text bash >}}
        $ kubectl logs -l istio=ingressgateway -n istio-system
        {{< /text >}}

    * Egress Gateway 日志：

        {{< text bash >}}
        $ kubectl logs -l istio=egressgateway -n istio-system
        {{< /text >}}

    * Sidecar 日志：

        {{< text bash >}}
        $ for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}') ; do kubectl logs -l service.istio.io/canonical-revision -c istio-proxy -n $ns ; done
        {{< /text >}}

* 所有 `Istio` 相关的配置文件：

    {{< text bash >}}
    $ kubectl get istio-io --all-namespaces -o yaml
    {{< /text >}}

## 文档错误   {#documentation-bugs}

搜索我们的[文档问题数据库](https://github.com/istio/istio.io/issues/)，
以查看是否我们已经知道您的问题，并了解何时可以解决这些问题。如果您没有在数据库中找到相应的问题，
请[在那里报告问题](https://github.com/istio/istio.io/issues/new)。
如果您想提交对页面的修改建议，可以在每个页面的右下角找到"在 GitHub 上编辑此页"的链接。
