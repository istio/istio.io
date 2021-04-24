---
title: 金丝雀升级
description: 通过先运行一个金丝雀部署的新控制平面升级 Istio。
weight: 10
keywords: [kubernetes,upgrading,canary]
owner: istio/wg-environments-maintainers
test: no
---

通过先运行一个金丝雀部署的新控制平面来完成 Istio 的升级，从而允许您在将所有流量迁移到新版本之前以一小部分工作负载监视升级的效果，这比 [就地升级](/zh/docs/setup/upgrade/in-place/) 要安全的多，这也是推荐的升级方法。

安装 Istio 时，`revision` 安装设置可用于同时部署多个独立的控制平面。升级的金丝雀版本可以通过使用不同的 `revision`，在旧版本的旁边安装启动新版本的 Istio 控制平面。每个修订都是一个完整的 Istio 控制平面实现，具有自己的 `Deployment`、`Service` 等。

## 控制平面 {#control-plane}

要安装名为 `canary` 的新修订版本，您可以按照如下所示设置 `revision` 字段：

{{< tip >}}
在生产环境中，更好的修订名称将对应 Istio 的版本。但是您必须替换修订名称的 `.` 字符，例如 `revision=1-6-8` 表示 Istio `1.6.8`，因为 `.` 不是一个有效的修订名称字符。
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

运行该命令后，您将有两个并行运行的控制平面 Deployment 和 Service：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-786779888b-p9s5n                 1/1     Running   0          114m
istiod-canary-6956db645c-vwhsk          1/1     Running   0          1m
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                AGE
istiod          ClusterIP   10.32.5.247   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                  33d
istiod-canary   ClusterIP   10.32.6.58    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,53/UDP,853/TCP   12m
{{< /text >}}

您还将看到包括新版本在内的两个 Sidecar 注入配置。

{{< text bash >}}
$ kubectl get mutatingwebhookconfigurations
NAME                            WEBHOOKS   AGE
istio-sidecar-injector          1          7m56s
istio-sidecar-injector-canary   1          3m18s
{{< /text >}}

{{< warning >}}
由于在安装过程中创建 `ValidatingWebhookConfiguration` 时存在 [一个BUG](https://github.com/istio/istio/issues/28880)，因此初始安装 Istio __不能__ 指定修订版本。作为临时的解决方法，为使 Istio 资源验证在删除未经修订的 Istio 安装后继续工作，`istiod` 必须将 Service 手动指向应处理验证的修订版本。

实现此目的的一种方法是 `istiod` 使用 [此 Service]({{< github_blob >}}/manifests/charts/istio-control/istio-discovery/templates/service.yaml) 作为模版来手动创建一个名为 istiod 的 Service，指向目标修订。另一个选择是运行以下命令，其中 `<REVISION>` 是应处理验证的修订的名称。此命令创建一个 `istiod` Service 来指向目标修订版本。

{{< text bash >}}
$ kubectl get service -n istio-system -o json istiod-<REVISION> | jq '.metadata.name = "istiod" | del(.spec.clusterIP) | del(.spec.clusterIPs)' | kubectl apply -f -
{{< /text >}}

{{</ warning >}}

## 数据平面 {#data-plane}

与 Istiod 不同，Istio Gateway 不运行特定修订版本的实例，而是就地升级以使用新的控制平面修订版本。
您可以通过运行以下命令来验证 `istio-ingress` Gateway 是否正在使用 `canary` 修订版本：

{{< text bash >}}
$ istioctl proxy-status | grep $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}') | awk '{print $8}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

但是，仅安装新版本不会对现有的 Sidecar 代理产生影响。要升级它们，必须将它们配置为指向新的 `istiod-canary` 控制平面。这是在基于命名空间标签的 Sidecar 注入期间控制的 `istio.io/rev`。

要升级名称空间 `test-ns`，请删除 `istio-injection` 标签，然后添加 `istio.io/rev` 标签以指向 `canary` 修订版本。`istio-injection` 标签必须移除，因为它的优先级高于 `istio.io/rev`，此标签用于向后兼容性。

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

命名空间更新后，您需要重新启动 Pod 才能触发重新注入。一种方法是使用：

{{< text bash >}}
$ kubectl rollout restart deployment -n test-ns
{{< /text >}}

当 Pod 被重新注入时，它们将被配置为指向 `istiod-canary` 控制平面。你可以查看 Pod 标签验证这一点。

例如，运行以下命令将显示使用 `canary` 修订版本的所有 Pod：

{{< text bash >}}
$ kubectl get pods -n test-ns -l istio.io/rev=canary
{{< /text >}}

要验证 `test-ns` 命名空间中的新 Pod 正在使用与修订版本 `istiod-canary` 相对应的服务 `canary`， 请选择一个新创建的 Pod，然后在 `pod_name` 中使用以下命令：

{{< text bash >}}
$ istioctl proxy-status | grep ${pod_name} | awk '{print $8}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

输出确认 Pod 正在使用 `istiod-canary` 控制平面的修订版本。

## 卸载旧的控制平面 {#uninstall-old-control-plane}

升级控制平面和数据平面之后，您可以卸载旧的控制平面。例如，以下命令卸载修订版本的控制平面 `1-6-5`：

{{< text bash >}}
$ istioctl x uninstall --revision 1-6-5
{{< /text >}}

如果旧的控制平面没有修订版本标签，请使用其原始安装选项将其卸载，例如：

{{< text bash >}}
$ istioctl x uninstall -f manifests/profiles/default.yaml
{{< /text >}}

确认旧的控制平面已被移除，并且集群中仅存在新的控制平面：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

请注意，以上说明仅删除了用于指定控制平面修订版的资源，而未删除与其他控制平面共享的群集作用域资源。要完全卸载 Istio，请参阅 [卸载指南](/zh/docs/setup/install/istioctl/#uninstall-istio)。

## 卸载金丝雀控制平面 {#uninstall-canary-control-plane}

如果您决定回滚到旧的控制平面，而不是完成 Canary 升级，则可以使用 `istioctl x uninstall --revision=canary` 卸载 Canary 修订版。

但是，在这种情况下，您必须首先手动重新安装先前版本的网关，因为卸载命令不会自动还原先前就地升级的网关。

{{< tip >}}
确保使用与 `istioctl` 旧控制平面相对应的版本来重新安装旧网关，并且为避免停机，请确保旧网关已启动并正在运行，然后再进行金丝雀卸载。
{{< /tip >}}
