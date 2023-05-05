---
title: 使用 Helm 升级
linktitle: Upgrade with Helm
description: 使用 Helm 升级 Istio 的说明。
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: yes
---

请参阅本指南使用 [Helm](https://helm.sh/docs/) 升级和配置 Istio 网格。
本指南假设您已经[使用 Helm 安装](/zh/docs/setup/install/helm)了 Istio 的前一个小版本或补丁版本。

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## 升级步骤{#upgrade-steps}

升级 Istio 之前，推荐运行 `istioctl x precheck` 命令以确保升级能与您的环境兼容。

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

{{< warning >}}
执行升级时 [Helm 不支持升级或删除 CRD](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations)。因为有这个限制，所以在用 Helm 升级 Istio 时需要一个额外的步骤。
{{< /warning >}}

### 金丝雀升级（推荐）{#canary-upgrade}

您可以使用以下步骤，安装金丝雀版本的 Istio 控制平面来校验新版本是否与您现有的配置和数据平面兼容：

{{< warning >}}
请注意，当您安装一个金丝雀版本的 `istiod` 服务时，可以在主要安装和金丝雀安装之间共享来自基础 Chart 的底层集群范围资源。
{{< /warning >}}

1. 升级 Kubernetes {{< gloss >}}CRD{{</ gloss >}}：

    {{< text bash >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. 通过设置修订版的值来安装金丝雀版本的 Istio 发现 Chart：

    {{< text bash >}}
    $ helm install istiod-canary istio/istiod \
        --set revision=canary \
        -n istio-system
    {{< /text >}}

1. 验证您已经将两个 `istiod` 版本安装到了您的集群中：

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. 如果您正在使用 [Istio Gateway](/zh/docs/setup/additional-setup/gateway/#deploying-a-gateway)，
    可通过设置 revision 的值来安装金丝雀修订版的 Gateway Chart：

    {{< text bash >}}
    $ helm install istio-ingress-canary istio/gateway \
        --set revision=canary \
        -n istio-ingress
    {{< /text >}}

1. 验证您已将两个 `istio-ingress gateway` 版本安装到了集群中：

    {{< text bash >}}
    $ kubectl get pods -L istio.io/rev -n istio-ingress
      NAME                                    READY   STATUS    RESTARTS   AGE     REV
      istio-ingress-754f55f7f6-6zg8n          1/1     Running   0          5m22s   default
      istio-ingress-canary-5d649bd644-4m8lp   1/1     Running   0          3m24s   canary
    {{< /text >}}

    参见[升级 Gateway](/zh/docs/setup/additional-setup/gateway/#canary-upgrade-advanced)了解有关 Gateway 金丝雀升级的深度解析文档。

1. 遵循[此处](/zh/docs/setup/upgrade/canary/#data-plane)的步骤来测试和迁移现有工作负载，以使用金丝雀控制平面。

1. 一旦您已验证并迁移工作负载以使用金丝雀控制平面，您就可以卸载旧的控制平面：

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 升级 Istio base chart，将新的修订版作为默认值。

    {{< text bash >}}
    $ helm upgrade istio-base istio/base --set defaultRevision=canary -n istio-system --skip-crds
    {{< /text >}}

### 稳定修订标签（实验特性）{#stable-revision-labels}

{{< boilerplate revision-tags-preamble >}}

#### 用法{#usage}

{{< boilerplate revision-tags-usage >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_previous_version_revision >}}-1 -n istio-system | kubectl apply -f -
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-canary}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< warning >}}
这些命令将在您的集群中创建新的 `MutatingWebhookConfiguration` 资源，由于是通过 `kubectl` 手动应用这些模板，
所以这些资源不属于任何 Helm Chart。参见以下指示说明来卸载修订标记。
{{< /warning >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

#### 默认标记{#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{default}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

### 原地升级{#in-place-upgrade}

您可以使用 Helm 升级工作流在您的集群中对 Istio 执行原地升级。

{{< warning >}}
将您的重载值文件或自定义选项添加到以下命令，以在 Helm 升级期间保留您的自定义配置。
{{< /warning >}}

1. 升级 Kubernetes {{< gloss >}}CRD{{</ gloss >}}：

    {{< text bash >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. 升级 Istio base chart：

    {{< text bash >}}
    $ helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
    {{< /text >}}

1. 升级 Istio discovery chart：

    {{< text bash >}}
    $ helm upgrade istiod istio/istiod -n istio-system
    {{< /text >}}

1. （可选）升级集群中安装的 gateway chart：

    {{< text bash >}}
    $ helm upgrade istio-ingress istio/gateway -n istio-ingress
    {{< /text >}}

## 卸载{#uninstall}

请参阅 [Helm 安装指南](/zh/docs/setup/install/helm/#uninstall)中的卸载章节。
