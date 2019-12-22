---
title: Istio client-go 发布公告
description: 正式启用访问 Istio 资源。
publishdate: 2019-11-14
attribution: Neeraj Poddar (Aspen Mesh)
keywords: [client-go,tools,crd]
target_release: 1.4
---

我们很高兴地宣布 [Istio client go](https://github.com/istio/client-go) 的第一个版本发布了，该存储库使开发人员能够在 `Kubernetes` 环境中访问 `Istio API` 。在此存储库中的 `Kubernetes` 程序和客户端使开发人员可以轻松地为所有 `Istio` 客户端自定义的资源 `(CRDs)` 创建，读取，更新和删除 `(CRUD)`。

这是许多 Istio 用户强烈要求的功能，从 [Aspen Mesh](https://github.com/aspenmesh/istio-client-go)
和 [Knative project](https://github.com/knative/pkg)  项目对客户端产生的功能请求中可以明显地看出这一点。如果您正在使用上述客户端之一，则可以像如下这样轻松地切换到 [Istio client go](https://github.com/istio/client-go)：

{{< text go>}}
import (
  ...
  - versionedclient "github.com/aspenmesh/istio-client-go/pkg/client/clientset/versioned"
  + versionedclient "istio.io/client-go/pkg/clientset/versioned"
)
{{< /text >}}

由于生成的客户端在功能上是等效的，因此使用新的 `istio-client-go` 也不会有什么问题。

## 如何使用客户端{#how-to-use-client-go}

[Istio client go](https://github.com/istio/client-go) 存储库遵循与 [Istio API](https://github.com/istio/api) 存储库 相同的分支策略，因为客户端存储库取决于 `API` 定义。如果要使用稳定的客户端，则可以在 [client go](https://github.com/istio/client-go) 存储库中使用发行版分支或标记的版本。使用客户端与使用 [Kubernetes client go](https://github.com/kubernetes/client-go) 非常相似，这是一个使用客户端列出命名空间中所有 [Istio
virtual services](/zh/docs/reference/config/networking/virtual-service) 的简单示例：

{{< text go >}}
package main

import (
  "log"
  "os"

  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/client-go/tools/clientcmd"

  versionedclient "istio.io/client-go/pkg/clientset/versioned"
)

func main() {
  kubeconfig := os.Getenv("KUBECONFIG")
  namespace := os.Getenv("NAMESPACE")
  if len(kubeconfig) == 0 || len(namespace) == 0 {
    log.Fatalf("Environment variables KUBECONFIG and NAMESPACE need to be set")
  }
  restConfig, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
  if err != nil {
    log.Fatalf("Failed to create k8s rest client: %s", err)
  }

  ic, err := versionedclient.NewForConfig(restConfig)
  if err != nil {
    log.Fatalf("Failed to create istio client: %s", err)
  }
  // Print all VirtualServices
  vsList, err := ic.NetworkingV1alpha3().VirtualServices(namespace).List(metav1.ListOptions{})
  if err != nil {
    log.Fatalf("Failed to get VirtualService in %s namespace: %s", namespace, err)
  }
  for i := range vsList.Items {
    vs := vsList.Items[i]
    log.Printf("Index: %d VirtualService Hosts: %+v\n", i, vs.Spec.GetHosts())
  }
}
{{< /text >}}

您可以在 [这里](https://github.com/istio/client-go/blob/{{< source_branch_name >}}/cmd/example/client.go) 找到更详尽的示例。

## 为生成 Istio client go 而创建的工具{#useful-tools-created-for-generating-Istio-client-go}

如果您想知道为什么花费大量时间也很难生成此客户端，本小节将对此进行说明。在 `Istio` 中，我们使用[protobuf](https://developers.google.com/protocol-buffers) 规范编写 `API`，然后使用 `protobuf` 工具链将其转换为 `Go` 定义。如果尝试从 `protobuf` 的 `API` 生成 `Kubernetes` 客户端，可能会面临三个主要的挑战：

* **创建 Kubernetes 装饰器类型** - Kubernetes [客户端生成库](https://github.com/kubernetes/code-generator/tree/master/cmd/client-gen)
仅适用于遵循 `Kubernetes` 对象规范的 `Go` 对象， 例如： [Authentication Policy Kubernetes Wrappers](https://github.com/istio/client-go/blob/{{< source_branch_name >}}/pkg/apis/authentication/v1alpha1/types.gen.go)。这意味着对于需要程序访问的每个API，您都需要创建这些装饰器。此外，每个 `CRD` 组，版本和种类都需要大量的样板，需要用客户端代码生成。为了自动化该过程，我们创建了一个 [Kubernetes type
generator](https://github.com/istio/tools/tree/master/cmd/kubetype-gen) 工具，可以基于注释去自动创建 `Kubernetes`类型。该工具的注释和各种可用选项在 [README](https://github.com/istio/tools/blob/master/cmd/kubetype-gen/README.md) 中进行了说明。请注意，如果您使用 `protobuf` 工具生成 `Go` 类型，则需要将这些注释添加到 `proto` 文件中，以便注释出现在生成的 `Go` 文件中，然后供该工具使用。

* **生成 deep copy 方法** - 在 `Kubernetes` 客户端机制中，如果您想对从客户端集返回的任何对象进行修改，则需要创建该对象的副本以防止直接修改缓存中的对象。为了不直接修改缓存中的对象，我们一般是在所有嵌套类型上创建一个 `deep copy` 方法。我们开发了一个 [protoc deep copy
generator](https://github.com/istio/tools/tree/master/cmd/protoc-gen-deepcopy) 工具 ，该工具是一个 `protoc` 插件，可以使用 [Proto
Clone](https://godoc.org/github.com/golang/protobuf/proto#Clone) 库上的注释自动创建 `deepcopy` 方法。这是一个生成了 `deepcopy` 方法的[示例](https://github.com/istio/api/blob/{{< source_branch_name >}}/authentication/v1alpha1/policy_deepcopy.gen.go)。

* **类型和 JSON 的互相转换** - 对于从 `proto` 定义生成的类型，使用默认的 `Go JSON` 编码器或解码器通常会出现问题，因为像 `protobuf` 的 `oneof` 这类字段需要进行特殊处理。另外，名称中带有下划线的任何 `Proto` 字段都可以序列化或反序列化为不同的字段名称，具体取决于编码器/解码器，因为 `Go` 结构体的标记方式[不同](https://github.com/istio/istio/issues/17600)。始终建议使用 `protobuf` 原语对 `JSON` 进行序列化或反序列化，而不是依赖默认的 `Go` 库。我们创建了一个 [protoc JSON shim](https://github.com/istio/tools/tree/master/cmd/protoc-gen-jsonshim) 工具，它是一个 `protoc` 插件，可以为从 `Proto` 定义所有 `Go` 类型自动创建的 `Marshalers` 或 `Unmarshalers`。这是用此工具生成代码的一个[示例](https://github.com/istio/api/blob/{{< source_branch_name >}}/authentication/v1alpha1/policy_json.gen.go)。

我们希望新发布的客户端使用户能够为 `Istio API` 创建更多的 `integrations` 和 `controllers`，并且开发人员可以使用上述工具从 `Proto API` 生成 `Kubernetes` 客户端。
