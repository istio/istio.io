---
title: 如何查看 Mixer 配置？
weight: 10
---

*instances* 、*handlers* 和 *rules* 的相关配置以 Kubernetes [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 的方式进行存储。其配置可以使用 `kubectl` 访问 Kubernetes API server 获得。

## Rules

查看所有的 `rule` 列表，执行以下命令：

{{< text bash >}}
$ kubectl get rules --all-namespaces
NAMESPACE      NAME                     AGE
istio-system   kubeattrgenrulerule      20h
istio-system   promhttp                 20h
istio-system   promtcp                  20h
istio-system   stdiohttp                20h
istio-system   stdiotcp                 20h
istio-system   tcpkubeattrgenrulerule   20h
{{< /text >}}

查看单个 `rule` 配置，执行以下命令：

{{< text bash >}}
$ kubectl -n <namespace> get rules <name> -o yaml
{{< /text >}}

## Handlers

`Handlers` 基于 Kubernetes [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) 中的 `adapters` 资源进行定义。

首先，查看所有的 `adapter` 列表，执行以下命令：

{{< text bash >}}
$ kubectl get crd -listio=mixer-adapter
NAME                              AGE
adapters.config.istio.io          20h
bypasses.config.istio.io          20h
circonuses.config.istio.io        20h
deniers.config.istio.io           20h
fluentds.config.istio.io          20h
kubernetesenvs.config.istio.io    20h
listcheckers.config.istio.io      20h
memquotas.config.istio.io         20h
noops.config.istio.io             20h
opas.config.istio.io              20h
prometheuses.config.istio.io      20h
rbacs.config.istio.io             20h
servicecontrols.config.istio.io   20h
signalfxs.config.istio.io         20h
solarwindses.config.istio.io      20h
stackdrivers.config.istio.io      20h
statsds.config.istio.io           20h
stdios.config.istio.io            20h
{{< /text >}}

然后，对列表中的每个 `adapter` 执行以下命令：

{{< text bash >}}
$ kubectl get <adapter kind name> --all-namespaces
{{< /text >}}

`stdios` 将输出以下类似内容：

{{< text plain >}}
NAMESPACE      NAME      AGE
istio-system   handler   20h
{{< /text >}}

查看单个 `handler` 配置，执行以下命令：

{{< text bash >}}
$ kubectl -n <namespace> get <adapter kind name> <name> -o yaml
{{< /text >}}

## Instances

`Instances` 基于 Kubernetes [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) 中的 `instances` 资源进行定义。

首先，查看所有的 `instance` 列表，执行以下命令：

{{< text bash >}}
$ kubectl get crd -listio=mixer-instance
NAME                                    AGE
apikeys.config.istio.io                 20h
authorizations.config.istio.io          20h
checknothings.config.istio.io           20h
edges.config.istio.io                   20h
instances.config.istio.io               20h
kuberneteses.config.istio.io            20h
listentries.config.istio.io             20h
logentries.config.istio.io              20h
metrics.config.istio.io                 20h
quotas.config.istio.io                  20h
reportnothings.config.istio.io          20h
servicecontrolreports.config.istio.io   20h
tracespans.config.istio.io              20h
{{< /text >}}

然后，对列表中的每个 `instance` 执行以下命令：

{{< text bash >}}
$ kubectl get <instance kind name> --all-namespaces
{{< /text >}}

`metrics` 将输出以下类似内容：

{{< text plain >}}
NAMESPACE      NAME              AGE
istio-system   requestcount      20h
istio-system   requestduration   20h
istio-system   requestsize       20h
istio-system   responsesize      20h
istio-system   tcpbytereceived   20h
istio-system   tcpbytesent       20h
{{< /text >}}

查看单个 `instance` 配置，执行以下命令：

{{< text bash >}}
$ kubectl -n <namespace> get <instance kind name> <name> -o yaml
{{< /text >}}
