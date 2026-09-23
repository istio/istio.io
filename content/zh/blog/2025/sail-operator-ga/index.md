---
title: "Sail Operator 1.0.0 发布：使用 Operator 管理 Istio"
description: 深入了解 Sail Operator 的基础知识，并查看示例，了解使用它来管理 Istio 是多么容易。
publishdate: 2025-04-03
attribution: "Francisco Herrera - Red Hat; Translated by Wilson Wu (DaoCloud)"
keywords: [istio,operator,sail,incluster,istiooperator]
---

[Sail Operator](https://github.com/istio-ecosystem/sail-operator)
是 Red Hat 发起的一个社区项目，旨在为 Istio 构建一个现代
[operator](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator)。
[于 2024 年 8 月首次发布](/zh/blog/2024/introducing-sail-operator/)，
我们很高兴地宣布 Sail Operator 现已正式发布，其明确的使命是：简化和精简集群中的 Istio 管理。

## 简化部署和管理 {#simplified-deployment---management}

Sail Operator 旨在降低安装和运行 Istio 的复杂性。
它可以自动执行手动任务，确保从初始安装到集群中 Istio 版本的持续维护和升级，
都能获得一致、可靠且简单的体验。Sail Operator API 是围绕 Istio 的 Helm Chart API 构建的，
这意味着所有 Istio 配置都可以通过 Sail Operator CRD 的值获得。

我们鼓励用户阅读我们的[文档](https://github.com/istio-ecosystem/sail-operator/tree/main/docs)以了解有关这种管理 Istio 环境的新方法的更多信息。

Sail Operator 的主要资源包括：
* `Istio`：管理 Istio 控制平面。
* `IstioRevision`：表示控制平面的修订版本。
* `IstioRevisionTag`：表示稳定的修订版本标签，用作 Istio 控制平面修订版本的别名。
* `IstioCNI`：管理 Istio 的 CNI 节点代理。
* `ZTunnel`：管理 Ambient 模式 ztunnel DaemonSet（Alpha 功能）。

{{< idea >}}
如果您正在从[自从删除 Istio 集群内 Operator](/zh/blog/2024/in-cluster-operator-deprecation-announcement/)进行迁移，
您可以查看我们[文档](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#migrating-from-istio-in-cluster-operator)中的此部分，
我们在其中解释了资源的等价性，或者您也可以尝试我们的[资源转换器](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#converter-script)轻松地将您的
`IstioOperator` 资源转换为 `Istio` 资源。
{{< /idea >}}

## 主要功能和支持 {#main-features-and-support}

- Istio 控制平面的每个组件都由 Sail Operator 通过专用的 Kubernetes 自定义资源 (CR) 独立管理。
  Sail Operator 为 `Istio`、`IstioCNI` 和 `ZTunnel` 等组件提供单独的 CRD，
  允许您单独配置、管理和升级它们。此外，还有 `IstioRevision` 和 `IstioRevisionTag` 的 CRD 来管理 Istio 控制平面修订。
- 支持多个 Istio 版本。目前 1.0.0 版本支持：1.24.3、1.24.2、1.24.1、1.23.5、1.23.4、1.23.3、1.23.0。
- 支持两种更新策略：`InPlace` 和 `RevisionBased`。查看我们的文档以获取有关支持的更新类型的更多信息。
- 支持多集群 Istio [部署模型](/zh/docs/setup/install/multicluster/)：
  多主、主远程、外部控制平面。更多信息和示例请参阅我们的[文档](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multi-cluster)。
- Ambient mode support is Alpha: check our specific [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md).
- Ambient 模式支持处于 Alpha 阶段：
  请查看我们的具体[文档](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md)。
- 插件与 Sail Operator 分开管理。它们可以轻松与 Sail Operator 集成，
  请查看本节的[文档](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#addons)以获取示例和更多信息。

## 为什么是现在？ {#why-now}

随着云原生架构的不断发展，我们认为为 Istio 提供强大且用户友好的 Operator 比以往任何时候都更加重要。
Sail Operator 为开发人员和运营团队提供了一致、安全且高效的解决方案，
让那些习惯使用 Operator 的人感觉很熟悉。它的 GA 版本标志着一个成熟的解决方案，可以支持最苛刻的生产环境。

## 尝试一下 {#try-it-out}

您想尝试 Sail Operator 吗？此示例将向您展示如何使用基于修订的升级策略安全地更新 Istio 控制平面。
这意味着您将同时运行两个 Istio 控制平面，让您轻松迁移工作负载，最大限度地降低流量中断的风险。

先决条件：
- 运行中的集群
- Helm
- Kubectl
- Istioctl

### 使用 Helm 安装 Sail Operator {#install-the-sail-operator-using-helm}

{{< text bash >}}
$ helm repo add sail-operator https://istio-ecosystem.github.io/sail-operator
$ helm repo update
$ kubectl create namespace sail-operator
$ helm install sail-operator sail-operator/sail-operator --version 1.0.0 -n sail-operator
{{< /text >}}

该 Operator 现已安装在您的集群中：

{{< text plain >}}
NAME: sail-operator
LAST DEPLOYED: Tue Mar 18 12:00:46 2025
NAMESPACE: sail-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
{{< /text >}}

检查 Operator Pod 是否正在运行：

{{< text bash >}}
$ kubectl get pods -n sail-operator
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

### 创建 `Istio` 和 `IstioRevisionTag` 资源 {#create-istio-and-istiorevisiontag-resources}

创建一个版本为 `v1.24.2` 和 `IstioRevisionTag` 的 `Istio` 资源：

{{< text bash >}}
$ kubectl create ns istio-system
$ cat <<EOF | kubectl apply -f-
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: RevisionBased
    inactiveRevisionDeletionGracePeriodSeconds: 30
  version: v1.24.2
---
apiVersion: sailoperator.io/v1
kind: IstioRevisionTag
metadata:
  name: default
spec:
  targetRef:
    kind: Istio
    name: default
EOF
{{< /text >}}

请注意，`IstioRevisionTag` 具有对名称为 `default` 的 `Istio` 资源的目标引用

检查创建的资源的状态：
- `istiod` Pod 正在运行

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-2-bd8458c4-jl8zm   1/1     Running   0          3m45s
    {{< /text >}}

- `Istio` 资源被创建

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-2   Healthy   v1.24.2   4m27s
    {{< /text >}}

- `IstioRevisionTag` 资源被创建

    {{< text bash >}}
    $ kubectl get istiorevisiontag
    NAME      STATUS                    IN USE   REVISION          AGE
    default   NotReferencedByAnything   False    default-v1-24-2   4m43s
    {{< /text >}}

请注意，`IstioRevisionTag` 状态为 `NotReferencedByAnything`。
这是因为当前没有资源使用修订版本 `default-v1-24-2`。

### 部署示例应用程序 {#deploy-sample-application}

创建命名空间并标记以启用 Istio 注入：

{{< text bash >}}
$ kubectl create namespace sample
$ kubectl label namespace sample istio-injection=enabled
{{< /text >}}

标记命名空间后，您将看到 `IstioRevisionTag` 资源状态将更改为 'In Use: True'，
因为现在有一个资源使用修订版 `default-v1-24-2`：

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-2   6m24s
{{< /text >}}

部署示例应用程序：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml -n sample
{{< /text >}}

确认示例应用的代理版本与控制平面版本匹配：

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

### 将 Istio 控制平面升级到版本 1.24.3 {#upgrade-the-istio-control-plane-to-version-1.24.3}

使用新版本更新 `Istio` 资源：

{{< text bash >}}
$ kubectl patch istio default -n istio-system --type='merge' -p '{"spec":{"version":"v1.24.3"}}'
{{< /text >}}

检查 `Istio` 资源。您将看到有两个修订版本，并且它们都已 'ready'：

{{< text bash >}}
$ kubectl get istio
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   2           2       2        default-v1-24-3   Healthy   v1.24.3   10m
{{< /text >}}

`IstioRevisiontag` 现在引用了新的修订版本：

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-3   11m
{{< /text >}}

有两个 `IstioRevisions`，每个 Istio 版本一个：

{{< text bash >}}
$ kubectl get istiorevision
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-2          True    Healthy   True     v1.24.2   11m
default-v1-24-3          True    Healthy   True     v1.24.3   92s
{{< /text >}}

Sail Operator 会自动检测给定的 Istio 控制平面是否正在使用，
并将此信息写入您在上面看到的“正在使用”状态条件中。目前，
所有 `IstioRevisions` 和我们的 `IstioRevisionTag` 都被视为“正在使用”：
* 旧修订版本 `default-v1-24-2` 被视为正在使用，因为它被示例应用程序的 Sidecar 引用。
* 新修订版本 `default-v1-24-3` 被视为正在使用，因为它被标签引用。
* 标签被视为正在使用，因为它被示例命名空间引用。

确认有两个控制平面 Pod 正在运行，每个修订版本一个：

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm     1/1     Running   0          16m
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          6m32s
{{< /text >}}

确认代理 Sidecar 版本保持不变：

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

重启示例 Pod：

{{< text bash >}}
$ kubectl rollout restart deployment -n sample
{{< /text >}}

确认代理 Sidecar 版本已更新：

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                      VERSION
sleep-6f87fcf556-k9nh9.sample     Kubernetes     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     IGNORED     istiod-default-v1-24-3-68df97dfbb-v7ndm     1.24.3
{{< /text >}}

当 `IstioRevision` 不再使用且不是 `Istio` 资源的活动修订版本时（例如，当它不是 `spec.version` 字段中设置的版本时），
Sail Operator 将在宽限期（默认为 30 秒）后将其删除。确认删除旧的控制平面和 `IstioRevision`：

- 旧的控制平面 Pod 被删除

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          10m
    {{< /text >}}

- 旧的 `IstioRevision` 被删除

    {{< text bash >}}
    $ kubectl get istiorevision
    NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
    default-v1-24-3          True    Healthy   True     v1.24.3   13m
    {{< /text >}}

- `Istio` 资源现在只有一个修订版本

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-3   Healthy   v1.24.3   24m
    {{< /text >}}

**恭喜！**您已成功使用基于修订的升级策略更新了您的 Istio 控制平面。

{{< idea >}}
要查看最新的 Sail Operator 版本，请访问我们的[发布页面](https://github.com/istio-ecosystem/sail-operator/releases)。
由于此示例可能会随着时间的推移而发展，
请参阅我们的[文档](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#example-using-the-revisionbased-strategy-and-an-istiorevisiontag)以确保您阅读的是最新版本。
{{< /idea >}}

## 结论 {#conclusion}

Sail Operator 可自动执行手动任务，确保从初始安装到集群中 Istio 的持续维护和升级，
获得一致、可靠且简单的体验。Sail Operator 是一个 [istio-ecosystem](https://github.com/istio-ecosystem) 项目，
我们鼓励您试用并提供反馈以帮助我们改进它，您可以查看我们的[贡献指南](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md)了解有关如何为项目做出贡献的更多信息。
