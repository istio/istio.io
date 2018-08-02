---
title: Istio 的软性多租户支持
description: 使用 Kubernetes 命名空间和 RBAC 为 Istio 构建软性多租户环境
publishdate: 2018-04-19
subtitle: 使用多个 Istio 控制平面和 RBAC 提供多租户支持
attribution: John Joyce 和 Rich Curran
weight: 90
keywords: [tenancy]
---

多租户是一个在各种环境和各种应用中都得到了广泛应用的概念，但是不同环境中，为每租户提供的具体实现和功能性都是有差异的。[Kubernetes 多租户工作组](https://github.com/kubernetes/community/blob/master/wg-multitenancy/README.md)致力于在 Kubernetes 中定义多租户用例和功能。然而根据他们的工作进展来看，恶意容器和负载对于其他租户的 Pod 和内核资源的访问无法做到完全控制，因此只有"软性多租户”支持是可行的。

## 软性多租户

文中提到的"软性多租户”的定义指的是单一 Kubernetes 控制平面和多个 Istio 控制平面以及多个服务网格相结合；每个租户都有自己的一个控制平面和一个服务网格。集群管理员对所有 Istio 控制面都有控制和监控的能力，而租户管理员仅能得到指定 Istio 的控制权。使用 Kubernetes 的命名空间和 RBAC 来完成不同租户的隔离。

这种模式的一个用例就是企业内部共享的基础设施中，虽然预计不会发生恶意行为，但租户之间的清晰隔离仍然是很有必要的。

本文最后会对 Istio 未来的多租户模型进行一些描述。

> 注意：这里仅就在有限多租户环境中部署 Istio 做一些概要描述。当官方多租户支持实现之后，会在[文档](/zh/docs/)中具体阐述。

## 部署

### 多个 Istio 控制面

要部署多个 Istio 控制面，首先要在 Istio 清单文件中对所有的 `namespace` 引用进行替换。以 `istio.yaml` （0.8 中应该是 `istio.yaml`） 为例：如果需要两个租户级的 Istio 控制面，那么第一个租户可以使用 `istio.yaml` 中的缺省命名空间也就是 `istio-system`；而第二个租户就要生成一个新的 Yaml 文件，并在其中使用不同的命名空间。例如使用下面的命令创建一个使用 `istio-system1` 命名空间的 Yaml 文件：

{{< text bash >}}
$ cat istio.yaml | sed s/istio-system/istio-system1/g > istio-system1.yaml
{{< /text >}}

Istio Yaml 文件包含了 Istio 控制面的部署细节，包含组成控制面的 Pod（Mixer、Pilot、Ingress 以及 CA）。部署这两个控制面 Yaml 文件：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio.yaml
$ kubectl apply -f install/kubernetes/istio-system1.yaml
{{< /text >}}

会在两个命名空间生成两个 Istio 控制面

{{< text bash >}}
$ kubectl get pods --all-namespaces
NAMESPACE       NAME                                       READY     STATUS    RESTARTS   AGE
istio-system    istio-ca-ffbb75c6f-98w6x                   1/1       Running   0          15d
istio-system    istio-ingress-68d65fc5c6-dnvfl             1/1       Running   0          15d
istio-system    istio-mixer-5b9f8dffb5-8875r               3/3       Running   0          15d
istio-system    istio-pilot-678fc976c8-b8tv6               2/2       Running   0          15d
istio-system1   istio-ca-5f496fdbcd-lqhlk                  1/1       Running   0          15d
istio-system1   istio-ingress-68d65fc5c6-2vldg             1/1       Running   0          15d
istio-system1   istio-mixer-7d4f7b9968-66z44               3/3       Running   0          15d
istio-system1   istio-pilot-5bb6b7669c-779vb               2/2       Running   0          15d
{{< /text >}}

如果需要 Istio [Sidecar 注入组件](/zh/docs/setup/kubernetes/sidecar-injection/)以及[遥测组件](/zh/docs/tasks/telemetry/)，也需要根据租户的命名空间定义，修改所需的 Yaml 文件。

需要由集群管理员、而不是租户自己的管理员来加载这两组 Yaml 文件。另外，要把租户管理员的操作权限限制在各自的命名空间内，还需要额外的 RBAC 配置。

### 区分通用资源和命名空间资源

Istio 仓库中的清单文件中会创建两种资源，一种是能够被所有 Istio 控制面访问的通用资源，另一种是每个控制平面一份的专属资源。上面所说的在 Yaml 文件中替换 `istio-system` 命名空间的方法自然是很简单的，更好的一种方法就是把 Yaml 文件拆分为两块，一块是所有租户共享的通用部分；另一块就是租户自有的部分。根据 [CRD 资源定义（Custom Resource Definitions）](https://kubernetes.io/docs/concepts/api-extension/custom-resources/#customresourcedefinitions)中的说法，角色和角色绑定资源需要从 Istio 文件中进行剥离。另外，清单文件中提供的角色和角色绑定的定义可能不适合多租户环境，还需要进一步的细化和定制。

### Istio 控制面的 Kubernetes RBAC 设置

租户管理员应该被限制在单独的 Istio 命名空间中，要完成这个限制，集群管理员需要创建一个清单，其中至少要包含一个 `Role` 和 `RoleBinding` 的定义，类似下面的文件所示。例子中定义了一个租户管理员，命名为 `sales-admin`，他被限制在命名空间 `istio-system` 之中。完整的清单中可能要在 `Role` 中包含更多的 `apiGroups` 条目，来定义租户管理员的资源访问能力。

{{< text yaml >}}
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: istio-system1
  name: ns-access-for-sales-admin-istio-system1
rules:
- apiGroups: [""] # "" 代表核心 API 资源组
  resources: ["*"]
  verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: access-all-istio-system1
  namespace: istio-system1
subjects:
- kind: User
  name: sales-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ns-access-for-sales-admin-istio-system1
  apiGroup: rbac.authorization.k8s.io
{{< /text >}}

### 关注特定命名空间进行服务发现

除了创建 RBAC 规则来限制租户管理员只能访问指定 Istio 控制平面之外，Istio 清单还需要为 Istio Pilot 指定一个用于应用程序的命名空间，以便生成 xDS 缓存。Pilot 组件提供了命令行参数 `--appNamespace, ns-1` 可以完成这一任务。`ns-1` 就是租户用来部署自己应用的命名空间。`istio-system1.yaml` 中包含的相关代码大致如下：

{{< text yaml >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: istio-pilot
  namespace: istio-system1
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  replicas: 1
  template:
    metadata:
      labels:
        istio: pilot
    spec:
      serviceAccountName: istio-pilot-service-account
      containers:
      - name: discovery
        image: docker.io/<user ID>/pilot:<tag>
        imagePullPolicy: IfNotPresent
        args: ["discovery", "-v", "2", "--admission-service", "istio-pilot", "--appNamespace", "ns-1"]
        ports:
        - containerPort: 8080
        - containerPort: 443
{{< /text >}}

### 在特定命名空间中部署租户应用

现在集群管理员已经给租户创建了命名空间（`istio-system1`），并且对 Istio Pilot 的服务发现进行了配置，要求它关注应用的命名空间（`ns-1`），创建应用的 Yaml 文件，将其部署到租户的专属命名空间中：

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: ns-1
{{< /text >}}

然后把每个资源的命名空间都指定到 `ns-1`，例如：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
  namespace: ns-1
{{< /text >}}

虽然没有展示出来，但是应用的命名空间也应该有 RBAC 设置，用来对特定资源进行访问控制。集群管理员和租户管理员都有权完成这种 RBAC 限制。

### 在多租户环境中使用 `istioctl`

定义[路由规则](https://archive.istio.io/v0.7/docs/reference/config/istio.routing.v1alpha1/#RouteRule)或者[目标策略](https://archive.istio.io/v0.7/docs/reference/config/istio.routing.v1alpha1/#DestinationPolicy)时，要确认 `istioctl` 命令是针对专有的 Istio 控制面所在的命名空间运行的。另外规则自身的定义也要限制在租户的命名空间里，这样才能保证规则在租户自己的网格中生效。`-i` 选项用来在 Istio 控制面所属的命名空间中创建（get 和 describe 也一样）规则。`-n` 参数会限制规则的所在范围是租户的网格，取值就是租户应用所在的命名空间。如果 Yaml 文件中的资源已经指定了范围，`-n` 参数会被跳过。

例如下面的命令会创建到 `istio-system1` 命名空间的路由规则：

{{< text bash >}}
$ istioctl –i istio-system1 create -n ns-1 -f route_rule_v2.yaml
{{< /text >}}

用下面的命令可以查看：

{{< text bash >}}
$ istioctl -i istio-system1 -n ns-1 get routerule
NAME                  KIND                                  NAMESPACE
details-Default       RouteRule.v1alpha2.config.istio.io    ns-1
productpage-default   RouteRule.v1alpha2.config.istio.io    ns-1
ratings-default       RouteRule.v1alpha2.config.istio.io    ns-1
reviews-default       RouteRule.v1alpha2.config.istio.io    ns-1
{{< /text >}}

[Multiple Istio control planes](/zh/blog/2018/soft-multitenancy/#多个-istio-控制面) 中讲述了更多多租户环境下命名空间的相关问题。

### 测试结果

根据前文的介绍，一个集群管理员能够创建一个受限于 RBAC 和命名空间的环境，租户管理员能在其中进行部署。

完成部署后，租户管理员就可以访问指定的 Istio 控制平面的 Pod 了。

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY     STATUS    RESTARTS   AGE
grafana-78d649479f-8pqk9                  1/1       Running   0          1d
istio-ca-ffbb75c6f-98w6x                  1/1       Running   0          1d
istio-ingress-68d65fc5c6-dnvfl            1/1       Running   0          1d
istio-mixer-5b9f8dffb5-8875r              3/3       Running   0          1d
istio-pilot-678fc976c8-b8tv6              2/2       Running   0          1d
istio-sidecar-injector-7587bd559d-5tgk6   1/1       Running   0          1d
prometheus-cf8456855-hdcq7                1/1       Running   0          1d
servicegraph-75ff8f7c95-wcjs7             1/1       Running   0          1d
{{< /text >}}

然而无法访问全部命名空间的 Pod：

{{< text bash >}}
$ kubectl get pods --all-namespaces
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods at the cluster scope
{{< /text >}}

访问其他租户的命名空间也是不可以的：

{{< text bash >}}
$ kubectl get pods -n istio-system1
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods in the namespace "istio-system1"
{{< /text >}}

租户管理员能够在租户指定的应用命名空间中进行应用部署。例如可以修改一下 [Bookinfo](/zh/docs/examples/bookinfo/) 的 Yaml 然后部署到租户的命名空间 `ns-0` 中，然后租户管理员就可以在这一命名空间中列出 Pod 了：

{{< text bash >}}
$ kubectl get pods -n ns-0
NAME                              READY     STATUS    RESTARTS   AGE
details-v1-64b86cd49-b7rkr        2/2       Running   0          1d
productpage-v1-84f77f8747-rf2mt   2/2       Running   0          1d
ratings-v1-5f46655b57-5b4c5       2/2       Running   0          1d
reviews-v1-ff6bdb95b-pm5lb        2/2       Running   0          1d
reviews-v2-5799558d68-b989t       2/2       Running   0          1d
reviews-v3-58ff7d665b-lw5j9       2/2       Running   0          1d
{{< /text >}}

同样也是不能访问其他租户的应用程序命名空间：

{{< text bash >}}
$ kubectl get pods -n ns-1
Error from server (Forbidden): pods is forbidden: User "dev-admin" cannot list pods in the namespace "ns-1"
{{< /text >}}

如果部署了[遥测组件](/zh/docs/tasks/telemetry/), 例如
[Prometheus](/zh/docs/tasks/telemetry/querying-metrics/)（限制在 Istio 的 `namespace`），其中获得的统计结果展示的也只是租户应用命名空间的私有数据。

## 结语

上面的一些尝试表明 Istio 有足够的能力和安全性，符合少量多租户的用例需求。另外也很明显的，Istio 和 Kubernetes **无法**提供足够的能力和安全性来满足其他的用例，尤其是在租户之间要求完全的安全性和隔离的要求的用例。只有等容器技术（例如 Kubernetes ）能够提供更好的安全模型以及隔离能力，我们才能进一步的增强这方面的支持，Istio 的支持并不是很重要。

## 问题

* 一个租户的 CA(Certificate Authority) 和 Mixer 的 Pod 中产生的 Log 包含了另一个租户的控制面的 `info` 信息。

## 其他多租户模型的挑战

还有其他值得考虑的多租户部署模型：

1. 一个网格中运行多个应用程序，每个租户一个应用。集群管理员能控制和监控网格范围内的所有应用，租户管理员只能控制一个特定应用。

1. 单独的 Istio 控制平面控制多个网格，每个租户一个网格。集群管理员控制和监控整个 Istio 控制面以及所有网格，租户管理员只能控制特定的网格。

1. 一个云环境（集群控制），多个 Kubernetes 控制面（租户控制）

这些选项，有的需要改写代码才能支持，有的无法满足用户要求。

目前的 Istio 能力不适合第一种方案，这是因为其 RBAC 能力无法覆盖这种租户操作。另外在当前的网格模型中，Istio 的配置信息需要传递给 Envoy 代理服务器，多个租户在同一网格内共存的做法非常不安全。

再看看第二个方式，目前的 Istio 假设每个 Istio 控制面对应一个网格。要支持这种模型需要大量改写。这种情况需要更好的对资源的范围限制进行调整，同时根据命名空间进行安全限制，此外还需要调整 Istio 的 RBAC 模型。这种模式未来可能会支持，但目前来说是不可能的。

第三个方式对多数案例都是不合适的，毕竟多数集群管理员倾向于将同一个 Kubernetes 控制面作为 [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service) 提供给他们的租户。

## 未来

很明显，单一 Istio 控制面控制多个网格可能是下一个功能。还有可能就是在同一个网格中支持多个租户，并提供某种程度的隔离和安全保障。要完成这样的能力，就需要像 Kubernetes 中对命名空间的的操作那样，在一个单独的控制平面中进行分区，社区中发出了[这篇文档](https://docs.google.com/document/d/14Hb07gSrfVt5KX9qNi7FzzGwB_6WBpAnDpPG6QEEd9Q)来定义其他的用例，以及要支持这些用例所需要的 Istio 功能。

## 参考

* 视频：[用 RBAC 和命名空间支持的多租户功能及安全模型](https://www.youtube.com/watch?v=ahwCkJGItkU), [幻灯片](https://schd.ws/hosted_files/kccncna17/21/Multi-tenancy%20Support%20%26%20Security%20Modeling%20with%20RBAC%20and%20Namespaces.pdf).
* Kubecon 讨论，关于对”协同软性多租户"的支持 [Building for Trust: How to Secure Your Kubernetes](https://www.youtube.com/watch?v=YRR-kZub0cA).
* Kubernetes [RBAC 文档](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 以及 [命名空间文档](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/).
* Kubecon 幻灯片 [Multi-tenancy Deep Dive](https://schd.ws/hosted_files/kccncna17/a9/kubecon-multitenancy.pdf).
* Google 文档 [Multi-tenancy models for Kubernetes](https://docs.google.com/document/d/15w1_fesSUZHv-vwjiYa9vN_uyc--PySRoLKTuDhimjc). (需要授权)
* Cloud Foundry 提出的文档：[Multi-cloud and Multi-tenancy](https://docs.google.com/document/d/14Hb07gSrfVt5KX9qNi7FzzGwB_6WBpAnDpPG6QEEd9Q)
* [Istio Auto Multi-Tenancy 101](https://docs.google.com/document/d/12F183NIRAwj2hprx-a-51ByLeNqbJxK16X06vwH5OWE)
