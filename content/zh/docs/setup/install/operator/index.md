---
title: 使用 Istio Operator 安装
description: 使用 Istio operator 在 Kubernetes 集群中安装 Istio 的说明。
weight: 25
keywords: [kubernetes, operator]
test: no
---

除了手动在生产环境中安装、升级、和卸载 Istio，你还可以用
Istio [operator](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/operator/)
管理安装。
这样做还能缓解管理不同 Istio 版本的负担。
你只需简单的更新 operator {{<gloss CRDs>}}自定义资源（CR）{{</gloss>}}即可，
operator 控制器将为你应用相应的配置更改。

当你用 [istioctl install 命令](/zh/docs/setup/install/istioctl)安装 Istio 时，
底层使用的是和 operator 安装相同的
[`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)。
在这两种场景下，都会以架构验证配置，并执行同样的正确性检查。

{{< warning >}}
使用 operator 确实存在安全隐患：
这是因为当使用 `istioctl install` 命令时，操作运行于管理员用户的安全上下文中；
而使用 operator 时，操作运行于集群内 pod 自己的安全上下文中。
为避免此漏洞，需要确保 operator 自身部署的足够安全。
{{< /warning >}}

## 先决条件

1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)。

1. 检查 [服务和 Pod 的要求](/zh/docs/ops/deployment/requirements/)。

1. 安装 [{{< istioctl >}} 可执行程序](/zh/docs/ops/diagnostic-tools/istioctl/)。

1. 部署 Istio operator：

    {{< text bash >}}
    $ istioctl operator init
    {{< /text >}}

    此命令运行 operator 在 `istio-operator` 命名空间中创建以下资源：

    - operator 自定义资源定义（CRD）
    - operator 控制器的 deployment 对象
    - 一个用来访问 operator 指标的服务
    - Istio operator 运行必须的 RBAC 规则

    你可以配置 operator 控制器安装的命名空间、operator 观测的命名空间、Istio 的镜像源和版本、以及更多。
    例如，可以使用参数 `--watchedNamespaces` 指定一个或多个命名空间来观测：

    {{< text bash >}}
    $ istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
    {{< /text >}}

    更多详细信息，请参阅 [`istioctl operator init` 命令参考](/zh/docs/reference/commands/istioctl/#istioctl-operator-init)。

    {{< tip >}}
    您也可以使用 Helm 部署 operator：

    {{< text bash >}}
    $ helm install istio-operator manifests/charts/istio-operator \
      --set hub=docker.io/istio \
      --set tag={{< istio_full_version >}} \
      --set operatorNamespace=istio-operator \
      --set watchedNamespaces=istio-namespace1,istio-namespace2
    {{< /text >}}

    注意：为了运行上面的命令，你需要[下载 Istio 的发行版本](/zh/docs/setup/getting-started/#download)。
    {{< /tip >}}

## 安装

要使用 operator 安装 Istio `demo` [配置项（configuration profile）](/zh/docs/setup/additional-setup/config-profiles/)，请运行以下命令：

{{< text bash >}}
$ kubectl create ns istio-system
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

控制器将检测 `IstioOperator` 资源，然后安装（`demo`）配置指定的 Istio 组件。

{{< tip >}}
Istio operator 控制器在创建 `IstioOperator` 资源的90秒内启动 Istio 的安装。
Istio 安装过程将在 120 秒内完成。
{{< /tip >}}

可以使用以下命令确认 Istio 控制平面服务是否成功：

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE
istio-egressgateway         ClusterIP      10.103.243.113   <none>        80/TCP,443/TCP,15443/TCP                                                     17s
istio-ingressgateway        LoadBalancer   10.101.204.227   <pending>     15020:31077/TCP,80:30689/TCP,443:32419/TCP,31400:31411/TCP,15443:30176/TCP   17s
istiod                      ClusterIP      10.96.237.249    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,53/UDP,853/TCP                         30s                                                              13s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                   READY   STATUS    RESTARTS   AGE
istio-egressgateway-5444c68db8-9h6dz   1/1     Running   0          87s
istio-ingressgateway-5c68cb968-x7qv9   1/1     Running   0          87s
istiod-598984548d-wjq9j                1/1     Running   0          99s
{{< /text >}}

## 更新

现在，控制器已经运行起来，你可以通过编辑或替换 `IstioOperator` 来改变 Istio 配置。
控制器将检测到改变，继而用相应配置更新 Istio 的安装内容。

例如，使用以下命令将安装切换到 `default` 配置：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

还可以启用或禁用组件、改变资源设置。
例如，启用 `istio-egressgateway` 组件并增加 pilot 的内存要求：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
  components:
    pilot:
      k8s:
        resources:
          requests:
            memory: 3072Mi
    egressGateways:
    - name: istio-egressgateway
      enabled: true
EOF
{{< /text >}}

通过检查 operator 控制器日志，
你可以检测到控制器为了响应 `IstioOperator`  CR 的更新，而在集群中所做的改变：

{{< text bash >}}
$ kubectl logs -f -n istio-operator $(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')
{{< /text >}}

参阅 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec)完整的配置设置。

## 就地升级

下载并提取希望升级到的 Istio 版本对应的 `istioctl`。
在目标 Istio 版本的目录中，重新安装 operator：

{{< text bash >}}
$ <extracted-dir>/bin/istioctl operator init
{{< /text >}}

你会看到 `istio-operator` 的 Pod 已重新启动，其版本已更改到目标版本：

{{< text bash >}}
$ kubectl get pods --namespace istio-operator \
  -o=jsonpath='{range .items[*]}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

经过一两分钟后，Istio 控制平面组件也会重新启动为新版本：

{{< text bash >}}
$ kubectl get pods --namespace istio-system \
  -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

## 金丝雀升级

金丝雀升级的过程类似于
[`istioctl` 版本的金丝雀升级](/zh/docs/setup/upgrade/#canary-upgrades)。

例如，要升级上一节中安装的 Istio 修订版本，
首先验证群集中名为 `example-istiocontrolplane` 的 `IstioOperator` CR 是否存在：

{{< text bash >}}
$ kubectl get iop --all-namespaces
NAMESPACE      NAME                        REVISION   STATUS    AGE
istio-system   example-istiocontrolplane              HEALTHY   11m
{{< /text >}}

下载并提取希望升级到的 Istio 版本对应的 `istioctl`。
然后，运行以下命令，基于群集内的 `IstioOperator` CR 的方式，安装 Istio 目标版本的控制平面
（这里，我们假设目标修订版本为 1.8.1）：

{{< text bash >}}
$ istio-1.8.1/bin/istioctl operator init --revision 1-8-1
{{< /text >}}

{{< tip >}}
你也可以通过 Helm 用不同的修订设置部署另一个 operator：

{{< text bash >}}
$ helm install istio-operator manifests/charts/istio-operator \
  --set hub=docker.io/istio \
  --set tag={{< istio_full_version >}} \
  --set operatorNamespace=istio-operator \
  --set watchedNamespaces=istio-system \
  --set revision=1-7-0
{{< /text >}}

注意：你需要[下载 Istio 的发行版本](/zh/docs/setup/getting-started/#download)来运行上面的命令。
{{< /tip >}}

运行该命令后，你将看到两组并排运行的控制平面 deployments 和 services：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-5f4f9dd5fc-4xc8p          1/1     Running   0          10m
istiod-1-8-1-55887f699c-t8bh8    1/1     Running   0          8m13s
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get svc -l app=istiod
NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                         AGE
istiod          ClusterIP   10.87.7.69   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   10m
istiod-1-8-1    ClusterIP   10.87.4.92   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   7m55s
{{< /text >}}

要完成升级，请给工作负载的命名空间打这个标签： `istio.io/rev=1-8-1` ，并重新启动工作负载，
就如 [数据平面升级](/zh/docs/setup/upgrade/canary/#data-plane) 文档的描述。

## 卸载

如果你使用 operator 完成了控制平面的金丝雀升级，
请运行以下命令卸载旧版本的控件平面，并保留新版本：

{{< text bash >}}
$ istioctl operator remove --revision <revision>
{{< /text >}}

否则，删除集群内运行的 `IstioOperator` CR，该 CR 将卸载正在运行的 Istio 的所有修订版本：

{{< text bash >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

等到 Istio 卸载完成 - 这可能需要一些时间。
  然后删除 Istio 运算符：

{{< text bash >}}
$ istioctl operator remove
{{< /text >}}

或：

{{< text bash >}}
$ kubectl delete ns istio-operator --grace-period=0 --force
{{< /text >}}

注意：在 Istio 完全移除之前删除 operator 可能会导致 Istio 资源残留。
需要清理 operator 未删除的内容：

{{< text bash >}}
$ istioctl manifest generate | kubectl delete -f -
$ kubectl delete ns istio-system --grace-period=0 --force
 {{< /text >}}
