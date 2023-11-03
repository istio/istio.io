---
title: 使用 Istio Operator 安装
description: 使用 Istio Operator 在 Kubernetes 集群中安装 Istio 的说明。
weight: 99
keywords: [kubernetes, operator]
aliases:
    - /zh/docs/setup/install/standalone-operator
owner: istio/wg-environments-maintainers
test: yes
status: Beta
---

{{< warning >}}
全新安装 Istio 时不鼓励使用 Operator，请优先使用 [Istioctl](/zh/docs/setup/install/istioctl)
和 [Helm](/zh/docs/setup/install/helm) 安装方法。Operator 仍然会得到维护，但新的功能请求可能不会优先考虑。
{{< /warning >}}

除了手动在生产环境中安装、升级、和卸载 Istio，您还可以用
Istio [Operator](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/operator/) 管理安装。
这样做还能缓解管理不同 Istio 版本的负担。
您只需简单的更新 Operator {{<gloss CRD>}}自定义资源（CR）{{</gloss>}}即可，
Operator 控制器将为您应用更改的相应配置。

当您[使用 Istioctl](/zh/docs/setup/install/istioctl)安装 Istio 时，
底层使用的是和 Operator 安装相同的 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)。
在这两种场景下，都会以架构验证配置，并执行同样的正确性检查。

{{< warning >}}
使用 Operator 确实存在安全隐患：
这是因为当使用 `istioctl install` 命令时，操作运行于管理员用户的安全上下文中；
而使用 Operator 时，操作运行于集群内 pod 自己的安全上下文中。
为避免此漏洞，需要确保 Operator 自身部署的足够安全。
{{< /warning >}}

## 先决条件 {#prerequisites}

1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)。

1. 检查 [服务和 Pod 的要求](/zh/docs/ops/deployment/requirements/)。

1. 安装 [{{< istioctl >}} 可执行程序](/zh/docs/ops/diagnostic-tools/istioctl/)。

## 安装 {#install}

### 部署 Istio Operator {#deploy-the-Istio-operator}

`istioctl` 命令可用于自动部署 Istio 操作符：

{{< text syntax=bash snip_id=deploy_istio_operator >}}
$ istioctl operator init
{{< /text >}}

此命令运行 Operator 在 `istio-operator` 命名空间中创建以下资源：

- Operator 自定义资源定义（CRD）
- Operator 控制器的 Deployment 对象
- 一个用来访问 Operator 指标的服务
- Istio Operator 运行必须的 RBAC 规则

您可以配置 Operator 控制器安装的命名空间、Operator 观测的命名空间、Istio 的镜像源和版本、以及更多。
例如，可以使用参数 `--watchedNamespaces` 指定一个或多个命名空间来观测：

{{< text syntax=bash snip_id=deploy_istio_operator_watch_ns >}}
$ istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
{{< /text >}}

更多详细信息，请参阅 [`istioctl operator init` 命令参考](/zh/docs/reference/commands/istioctl/#istioctl-operator-init)。

{{< tip >}}
您也可以使用 Helm 部署 Operator：

1. 创建 `istio-operator` 命名空间。

    {{< text syntax=bash snip_id=create_ns_istio_operator >}}
    $ kubectl create namespace istio-operator
    {{< /text >}}

2) 使用 Helm 安装 Operator。

    {{< text syntax=bash snip_id=deploy_istio_operator_helm >}}
    $ helm install istio-operator manifests/charts/istio-operator \
        --set watchedNamespaces="istio-namespace1\,istio-namespace2" \
        -n istio-operator
    {{< /text >}}

注意：为了运行上面的命令，您需要[下载 Istio 的发行版本](/zh/docs/setup/getting-started/#download)。
{{< /tip >}}

{{< warning >}}
在 Istio 1.10.0 之前，需要在安装 Operator 之前创建命名空间 `istio-system`。
从 Istio 1.10.0 开始，`istioctl operator init` 将创建 `istio-system` 命名空间。

如果您使用的不是 `istioctl operator init`，那么 `istio-system` 命名空间需要被手动创建。
{{< /warning >}}

### 使用 operator 安装 Istio {#install-Istio-with-the-operator}

要使用 Operator 安装 Istio `demo`
[配置项（configuration profile）](/zh/docs/setup/additional-setup/config-profiles/)，请运行以下命令：

{{< text syntax=bash snip_id=install_istio_demo_profile >}}
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

{{< warning >}}
如果在初始化 Istio Operator 时使用了 `--watchedNamespaces`，
请将 `IstioOperator` 资源应用于任一观测的命名空间中，而不是应用于 `istio-system` 中。
{{< /warning >}}

默认情况下，Istio 控制平面（istiod）将安装在 `istio-system` 命名空间中。
要将其安装到其他命名空间，请如下使用 `values.global.istioNamespace` 字段：

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
...
spec:
  profile: demo
  values:
    global:
      istioNamespace: istio-namespace1
{{< /text >}}

{{< tip >}}
Istio Operator 控制器在创建 `IstioOperator` 资源的 90 秒内开始安装 Istio。
Istio 安装过程将在 120 秒内完成。
{{< /tip >}}

可以使用以下命令确认 Istio 控制平面服务是否成功：

{{< text syntax=bash snip_id=kubectl_get_svc >}}
$ kubectl get services -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)   AGE
istio-egressgateway    ClusterIP      10.96.65.145    <none>           ...       30s
istio-ingressgateway   LoadBalancer   10.96.189.244   192.168.11.156   ...       30s
istiod                 ClusterIP      10.96.189.20    <none>           ...       37s
{{< /text >}}

{{< text syntax=bash snip_id=kubectl_get_pods >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-696cccb5-m8ndk      1/1     Running   0          68s
istio-ingressgateway-86cb4b6795-9jlrk   1/1     Running   0          68s
istiod-b47586647-sf6sw                  1/1     Running   0          74s
{{< /text >}}

## 更新 {#update}

现在，控制器已经运行起来，您可以通过编辑或替换 `IstioOperator` 资源来改变 Istio 配置。
控制器将检测到改变，继而用相应配置更新安装的 Istio。

例如，使用以下命令将安装切换到 `default` 配置：

{{< text syntax=bash snip_id=update_to_default_profile >}}
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

您还可以启用或禁用组件、修改资源设置。
例如，启用 `istio-egressgateway` 组件并增加 pilot 的内存请求：

{{< text syntax=bash snip_id=update_to_default_profile_egress >}}
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

通过检查 Operator 控制器日志，您可以检测到控制器为了响应 `IstioOperator` CR 的更新，而在集群中所做的改变：

{{< text syntax=bash snip_id=operator_logs >}}
$ kubectl logs -f -n istio-operator "$(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')"
{{< /text >}}

参阅 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec)
获取完整的配置设置。

## 就地升级 {#in-place-upgrade}

下载并提取希望升级到的 Istio 版本对应的 `istioctl`。
在目标 Istio 版本的目录中，重新安装 Operator：

{{< text syntax=bash snip_id=inplace_upgrade >}}
$ <extracted-dir>/bin/istioctl operator init
{{< /text >}}

您会看到 `istio-operator` 的 Pod 已重新启动，其版本已更改到目标版本：

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_operator >}}
$ kubectl get pods --namespace istio-operator \
  -o=jsonpath='{range .items[*]}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

经过一两分钟后，Istio 控制平面组件也会重新启动为新版本：

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_system >}}
$ kubectl get pods --namespace istio-system \
  -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

## 金丝雀升级 {#canary-upgrade}

金丝雀升级的过程类似于
[`istioctl` 版本的金丝雀升级](/zh/docs/setup/upgrade/#canary-upgrades)。

例如，要升级上一节中安装的 Istio 修订版本，首先验证集群中名为 `example-istiocontrolplane` 的 `IstioOperator` CR 是否存在：

例如要升级 Istio {{< istio_previous_version >}}.0 到 {{< istio_full_version >}}，
首先安装 {{< istio_previous_version >}}.0：

{{< text syntax=bash snip_id=download_istio_previous_version >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_previous_version >}}.0 sh -
{{< /text >}}

使用 Istio 版本 {{< istio_previous_version >}}.0 部署 Operator：

{{< text syntax=bash snip_id=deploy_operator_previous_version >}}
$ istio-{{< istio_previous_version >}}.0/bin/istioctl operator init
{{< /text >}}

安装 Istio 控制平面 demo 配置文件：

{{< text syntax=bash snip_id=install_istio_previous_version >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_previous_version_revision >}}-0
spec:
  profile: default
EOF
{{< /text >}}

确认您的集群中存在名为 `example-istiocontrolplane` 的 `IstioOperator` CR：

{{< text syntax=bash snip_id=verify_operator_cr >}}
$ kubectl get iop --all-namespaces
NAMESPACE      NAME                              REVISION   STATUS    AGE
istio-system   example-istiocontrolplane{{< istio_previous_version_revision >}}-0              HEALTHY   11m
{{< /text >}}

下载并提取希望升级到的 Istio 版本对应的 `istioctl`。
然后，运行以下命令，基于集群内的 `IstioOperator` CR 的方式，安装 Istio 目标版本的控制平面
（这里，我们假设目标修订版本为 1.8.1）：

{{< text syntax=bash snip_id=canary_upgrade_init >}}
$ istio-{{< istio_full_version >}}/bin/istioctl operator init --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< tip >}}
您也可以通过 Helm 用不同的修订设置部署另一个 Operator：

{{< text syntax=bash snip_id=none >}}
$ helm install istio-operator manifests/charts/istio-operator \
  --set watchedNamespaces=istio-system \
  -n istio-operator \
  --set revision={{< istio_full_version_revision >}}
{{< /text >}}

注意：您需要[下载 Istio 的发行版本](/zh/docs/setup/getting-started/#download)来运行上面的命令。
{{< /tip >}}

复制 `example-istiocontrolplane` CR 并将其另存为 `example-istiocontrolplane-1-8-1.yaml` 文件。
在 CR 中修改该文件的名称为 `example-istiocontrolplane-1-8-1`，并添加 `revision: 1-8-1`。
更新后的 `IstioOperator` CR 如下所示：

{{< text syntax=bash snip_id=cat_operator_yaml >}}
$ cat example-istiocontrolplane-{{< istio_full_version_revision >}}.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_full_version_revision >}}
spec:
  revision: {{< istio_full_version_revision >}}
  profile: default
{{< /text >}}

运行该命令后，您将看到两组并排运行的控制平面 Deployment 和 Service：

{{< text syntax=bash snip_id=get_pods_istio_system >}}
$ kubectl get pod -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_full_version_revision >}}-597475f4f6-bgtcz   1/1     Running   0          64s
istiod-6ffcc65b96-bxzv5          1/1     Running   0          2m11s
{{< /text >}}

{{< text syntax=bash snip_id=get_svc_istio_system >}}
$ kubectl get services -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
istiod          ClusterIP   10.104.129.150   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   2m35s
istiod-{{< istio_full_version_revision >}}   ClusterIP   10.111.17.49     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP           88s
{{< /text >}}

要完成升级，请给工作负载的命名空间打这个标签：`istio.io/rev=1-8-1`，并重新启动工作负载，
就如[数据平面升级](/zh/docs/setup/upgrade/canary/#data-plane)文档的描述。

## 卸载 {#uninstall}

如果您使用 Operator 完成了控制平面的金丝雀升级，请运行以下命令卸载旧版本的控件平面，并保留新版本：

{{< text syntax=bash snip_id=delete_example_istiocontrolplane >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

等到 Istio 卸载完成 - 这可能需要一些时间。
然后删除 Istio Operator：

{{< text syntax=bash snip_id=none >}}
$ istioctl operator remove --revision <revision>
{{< /text >}}

如果省略 `revision` 标志，则 Istio Operator 的所有修订版本都将被删除。

注意：在 Istio 完全移除之前删除 Operator 可能会导致 Istio 资源残留。
需要清理 Operator 未删除的内容：

{{< text syntax=bash snip_id=cleanup >}}
$ istioctl uninstall -y --purge
$ kubectl delete ns istio-system istio-operator
{{< /text >}}
