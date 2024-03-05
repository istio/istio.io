---
title: 金丝雀升级
description: 通过先运行一个金丝雀部署的新控制平面升级 Istio。
weight: 10
keywords: [kubernetes,upgrading,canary]
owner: istio/wg-environments-maintainers
test: yes
---

通过先运行一个金丝雀部署的新控制平面来完成 Istio 的升级，从而允许您在将所有流量迁移到新版本之前以一小部分工作负载监视升级的效果，
这比[原地升级](/zh/docs/setup/upgrade/in-place/)要安全得多，这也是推荐的升级方法。

安装 Istio 时，`revision` 安装设置可用于同时部署多个独立的控制平面。升级的金丝雀版本可以通过使用不同的
`revision`，在旧版本的旁边安装启动新版本的 Istio 控制平面。每个修订都是一个完整的 Istio 控制平面实现，
具有自己的 `Deployment`、`Service` 等。

## 升级之前 {#before-you-upgrade}

在升级 Istio 之前，建议执行 `istioctl x precheck` 命令，以确保升级与您的环境兼容。

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/
{{< /text >}}

{{< idea >}}
当使用基于版本的升级时，支持跨越两个次要版本（例如，直接从版本 `1.15` 到 `1.17`）。
这与原地升级不同，原地升级要求必须升级到每一个中间的次要版本。
{{< /idea >}}

## 控制平面 {#control-plane}

要安装名为 `canary` 的新修订版本，您可以按照如下所示设置 `revision` 字段：

{{< tip >}}
在生产环境中，更好的修订名称将对应 Istio 的版本。但是您必须替换修订名称的 `.` 字符，
例如 `revision={{< istio_full_version_revision >}}` 表示 Istio `{{< istio_full_version >}}`，
因为 `.` 不是一个有效的修订名称字符。
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

运行该命令后，您将有两个并行运行的控制平面 Deployment 和 Service：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-htddg    1/1     Running   0          47s
istiod-canary-84c8d4dcfb-skcfv   1/1     Running   0          25s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
istiod-{{< istio_previous_version_revision >}}-1   ClusterIP   10.96.93.151     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   109s
istiod-canary   ClusterIP   10.104.186.250   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   87s
{{< /text >}}

您还将看到包括新版本在内的两个 Sidecar 注入配置。

{{< text bash >}}
$ kubectl get mutatingwebhookconfigurations
NAME                            WEBHOOKS   AGE
istio-sidecar-injector-{{< istio_previous_version_revision >}}-1   2          2m16s
istio-sidecar-injector-canary   2          114s
{{< /text >}}

## 数据平面 {#data-plane}

请参阅[网关金丝雀升级](/zh/docs/setup/additional-setup/gateway/#canary-upgrade-advanced)，
以了解如何运行 Istio Gateway 的特定修订版本的实例。在此示例中，由于我们使用了 `default` Istio
配置文件，因此 Istio Gateway 不运行特定修订版本的实例，而是原地升级以使用新的控制平面修订版本。
您可以通过运行以下命令来验证 `istio-ingress` Gateway 是否正在使用 `canary` 修订版本：

{{< text bash >}}
$ istioctl proxy-status | grep "$(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}')" | awk '{print $10}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

但是，仅安装新版本不会对现有的 Sidecar 代理产生影响。要升级它们，必须将它们配置为指向新的
`istiod-canary` 控制平面。这是在基于命名空间标签的 Sidecar 注入期间控制的 `istio.io/rev`。

创建一个命名空间 `test-ns` 并启用 `istio-injection`。
在 `test-ns` 命名空间中，部署一个示例 sleep Pod：

1. 创建命名空间 `test-ns`。

    {{< text bash >}}
    $ kubectl create ns test-ns
    {{< /text >}}

1. 使用 `istio-injection` 标签标记命名空间。

    {{< text bash >}}
    $ kubectl label namespace test-ns istio-injection=enabled
    {{< /text >}}

1. 在 `test-ns` 命名空间中启动一个示例 sleep Pod。

    {{< text bash >}}
    $ kubectl apply -n test-ns -f samples/sleep/sleep.yaml
    {{< /text >}}

要升级命名空间 `test-ns`，请删除 `istio-injection` 标签，然后添加 `istio.io/rev` 标签以指向
`canary` 修订版本。为了向后兼容性，`istio-injection` 标签必须移除，因为它的优先级高于 `istio.io/rev`。

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

命名空间更新后，您需要重新启动 Pod 才能触发重新注入。一种重启命名空间 `test-ns` 中所有 Pod 的方法是：

{{< text bash >}}
$ kubectl rollout restart deployment -n test-ns
{{< /text >}}

当 Pod 被重新注入时，它们将被配置为指向 `istiod-canary` 控制平面。您可以使用 `istioctl proxy-status` 来验证。

{{< text bash >}}
$ istioctl proxy-status | grep "\.test-ns "
{{< /text >}}

输出会展示命名空间下所有正在使用修订版本的 Pod。

## 稳定修订标签 {#stable-revision-labels}

{{< tip >}}
如果您正在使用 Helm, 请参考 [Helm 升级文档](/zh/docs/setup/upgrade/helm).
{{</ tip >}}

{{< boilerplate revision-tags-preamble >}}

### 用法 {#usage}

{{< boilerplate revision-tags-usage >}}

1. 安装两套修订版本的控制平面：

    {{< text bash >}}
    $ istioctl install --revision={{< istio_previous_version_revision >}}-1 --set profile=minimal --skip-confirmation
    $ istioctl install --revision={{< istio_full_version_revision >}} --set profile=minimal --skip-confirmation
    {{< /text >}}

1. 创建 `stable`和 `canary` 修订版本标签，将其与各自的修订相关联:

    {{< text bash >}}
    $ istioctl tag set prod-stable --revision {{< istio_previous_version_revision >}}-1
    $ istioctl tag set prod-canary --revision {{< istio_full_version_revision >}}
    {{< /text >}}

1. 为应用命名空间打标签，将其与各自的修订版本相关联：

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl label ns app-ns-1 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-2
    $ kubectl label ns app-ns-2 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-3
    $ kubectl label ns app-ns-3 istio.io/rev=prod-canary
    {{< /text >}}

1. 在每个命名空间中部署一个 sleep Pod 示例:

    {{< text bash >}}
    $ kubectl apply -n app-ns-1 -f samples/sleep/sleep.yaml
    $ kubectl apply -n app-ns-2 -f samples/sleep/sleep.yaml
    $ kubectl apply -n app-ns-3 -f samples/sleep/sleep.yaml
    {{< /text >}}

1. 使用 `istioctl proxy-status` 命令验证应用程序与控制平面的映射:

    {{< text bash >}}
    $ istioctl ps
    NAME                                CLUSTER        CDS        LDS        EDS        RDS        ECDS         ISTIOD                             VERSION
    sleep-78ff5975c6-62pzf.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-s8zfg     {{< istio_full_version >}}
    sleep-78ff5975c6-8kxpl.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version >}}.1
    sleep-78ff5975c6-8q7m6.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version_revision >}}.1
    {{< /text >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ istioctl tag set prod-stable --revision {{< istio_full_version_revision >}} --overwrite
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n app-ns-1
$ kubectl rollout restart deployment -n app-ns-2
{{< /text >}}

使用 `istioctl proxy-status` 命令验证应用程序与控制平面的映射:

{{< text bash >}}
$ istioctl ps
NAME                                                   CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                             VERSION
sleep-5984f48bc7-kmj6x.app-ns-1                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
sleep-78ff5975c6-jldk4.app-ns-3                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
sleep-7cdd8dccb9-5bq5n.app-ns-2                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
{{< /text >}}

### 默认版本 {#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ istioctl tag set default --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

## 卸载旧的控制平面 {#uninstall-old-control-plane}

升级控制平面和数据平面之后，您可以卸载旧的控制平面。例如，
以下命令卸载修订版本的控制平面 `{{< istio_previous_version_revision >}}-1`：

{{< text bash >}}
$ istioctl uninstall --revision {{< istio_previous_version_revision >}}-1 -y
{{< /text >}}

如果旧的控制平面没有修订版本标签，请使用其原始安装选项将其卸载，例如：

{{< text bash >}}
$ istioctl uninstall -f manifests/profiles/default.yaml -y
{{< /text >}}

确认旧的控制平面已被移除，并且集群中仅存在新的控制平面：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

请注意，以上说明仅删除了用于指定控制平面修订版的资源，而未删除与其他控制平面共享的集群作用域资源。
要完全卸载 Istio，请参阅[卸载指南](/zh/docs/setup/install/istioctl/#uninstall-istio)。

## 卸载金丝雀控制平面 {#uninstall-canary-control-plane}

如果您决定回滚到旧的控制平面，而不是完成 Canary 升级，则可以使用以下命令卸载 Canary 修订版：

{{< text bash >}}
$ istioctl uninstall --revision=canary -y
{{< /text >}}

但是，在这种情况下，您必须首先手动重新安装先前版本的网关，因为卸载命令不会自动还原先前原地升级的网关。

{{< tip >}}
确保使用与 `istioctl` 旧控制平面相对应的版本来重新安装旧网关，并且为避免停机，
请确保旧网关已启动并正在运行，然后再进行金丝雀卸载。
{{< /tip >}}

## 清理 {#cleanup}

1. 清理已创建的修订版本标签：

    {{< text bash >}}
    $ istioctl tag remove prod-stable
    $ istioctl tag remove prod-canary
    {{< /text >}}

1. 清理用于金丝雀升级的命名空间与修订标签的例子：

    {{< text bash >}}
    $ kubectl delete ns istio-system test-ns
    {{< /text >}}

1. 清理用于金丝雀升级的命名空间与修订版本的例子：

    {{< text bash >}}
    $ kubectl delete ns istio-system app-ns-1 app-ns-2 app-ns-3
    {{< /text >}}
