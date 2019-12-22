---
title: 使用 Istioctl 安装
description: 安装和自定义任何 Istio 配置文件以进行深入评估或用于生产。
weight: 10
keywords: [istioctl, kubernetes]
---

请按照本指南安装和配置 Istio 网格，以进行深入评估或用于生产。
如果您刚接触 Istio 或者只是要简单试用，请参考 [开始](/zh/docs/setup/getting-started) 文档进行操作。

本指南使用可以高度自定义 Istio 控制平面和数据平面的 [`istioctl`](/zh/docs/reference/commands/istioctl/) 命令行工具。
该命令行工具具有用户输入校验功能，可以防止错误的安装和自定义选项。

使用这些命令说明，您可以选择 Istio 的任何内置 [配置文件](/zh/docs/setup/additional-setup/config-profiles/) 然后
根据您的特定需求进一步自定义配置。

## 前提条件{#prerequisites}

开始之前，请检查以下前提条件：

1. [下载 Istio 发行版本](/zh/docs/setup/getting-started/#download)。
1. 执行任何必要的 [特定于平台的设置](/zh/docs/setup/platform-setup/)。
1. 检查 [Pods 和 Services 的要求](/zh/docs/ops/deployment/requirements/)。

## 使用默认配置文件安装 Istio{#install-Istio-using-the-default-profile}

最简单的选择是安装 `default` Istio [配置文件](/zh/docs/setup/additional-setup/config-profiles/) 使用以下命令：

{{< text bash >}}
$ istioctl manifest apply
{{< /text >}}

此命令将在您配置的 Kubernetes 集群上安装 `default` 配置文件。
`default` 配置文件建立生产环境的良好起点，这与旨在评估广泛的 Istio 功能特性的较大的 `demo` 配置文件不同。

如果要在 `default` 配置文件之上启用安全性，可以设置与安全相关的配置参数：

{{< text bash >}}
$ istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true
{{< /text >}}

通常，您可以像使用 [helm](/zh/docs/setup/install/helm/) 一样在 `istioctl` 中配置 `--set` 标志。
唯一的区别是必须为配置路径增加 `values.` 前缀，因为这是 Helm 直通 API 的路径，如下所述。

## 从外部 Chart 安装{#install-from-external-charts}

通常，`istioctl` 使用内置 Chart 生成安装清单。这些 Chart 与 `istioctl` 一起发布，用于审核和自定义，它们
放置在 `install/kubernetes/operator/charts` 目录下。
除了使用内置 Chart 外，`istioctl` 还可以使用外部 Chart 生成安装清单。要选择外部 Chart ，请配置 `installPackagePath` 参数（接收本地文件系统路径）：

{{< text bash >}}
$ istioctl manifest apply --set installPackagePath=~/istio-releases/istio-{{< istio_full_version >}}/install/kubernetes/operator/charts
{{< /text >}}

如果使用 `istioctl` {{< istio_full_version >}} 二进制文件，该命令执行结果与通过 `istioctl manifest apply` 安装相同，因为它指向的 Chart 与内置 Chart 相同。
除了试验或测试新特性之外，我们建议使用内置 Chart 而不是外部提供，以确保 `istioctl` 二进制文件与 Chart 的兼容性。

## 安装其他配置文件{#install-a-different-profile}

可以通过在命令行上设置配置文件名称安装其他 Istio 配置文件到群集中。
例如，可以使用以下命令，安装 `demo` 配置文件：

{{< text bash >}}
$ istioctl manifest apply --set profile=demo
{{< /text >}}

## 显示可用配置文件的列表{#display-the-list-of-available-profiles}

您可以使用以下 `istioctl` 命令来列出 Istio 配置文件名称：

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    minimal
    remote
    sds
    default
    demo
{{< /text >}}

## 显示配置文件的配置{#display-the-configuration-of-a-profile}

您可以查看配置文件的配置设置。 例如，通过以下命令查看 `default` 配置文件的设置：

{{< text bash >}}
$ istioctl profile dump demo
autoInjection:
  components:
    injector:
      enabled: true
      k8s:
        replicaCount: 1
        strategy:
          rollingUpdate:
            maxSurge: 100%
            maxUnavailable: 25%
  enabled: true
cni:
  components:
    cni:
      enabled: false
  enabled: false
...
{{< /text >}}

要查看整个配置的子集，可以使用 `--config-path` 标志，该标志仅选择部分给定路径下的配置：

{{< text bash >}}
$ istioctl profile dump --config-path trafficManagement.components.pilot demo
enabled: true
k8s:
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
  - name: GODEBUG
    value: gctrace=1
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  - name: CONFIG_NAMESPACE
    value: istio-config
  hpaSpec:
    maxReplicas: 5
    metrics:
...
{{< /text >}}

## 显示配置文件中的差异{#show-differences-in-profiles}

`profile diff` 子命令可用于显示配置文件之间的差异，在将更改应用于集群之前，这对于检查自定义的效果很有用。

您可以使用以下命令显示默认配置文件和演示配置文件之间的差异：

{{< text bash >}}
$ istioctl profile dump default > 1.yaml
$ istioctl profile dump demo > 2.yaml
$ istioctl profile diff 1.yaml 2.yaml
 gateways:
   components:
     egressGateway:
-      enabled: false
+      enabled: true
...
           requests:
-            cpu: 100m
-            memory: 128Mi
+            cpu: 10m
+            memory: 40Mi
         strategy:
...
{{< /text >}}

## 安装前生成清单{#generate-a-manifest-before-installation}

您可以在安装 Istio 之前使用 `manifest generate` 子命令生成清单，而不是 `manifest apply`。
例如，使用以下命令为 `default` 配置文件生成清单：

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

根据需要检查清单，然后使用以下命令应用清单：

{{< text bash >}}
$ kubectl apply -f $HOME/generated-manifest.yaml
{{< /text >}}

{{< tip >}}
由于集群中的资源不可用，此命令可能显示暂时错误。
{{< /tip >}}

## 显示清单差异{#show-differences-in-manifests}

您可以使用以下命令显示默认配置文件和自定义安装之间生成的清单中的差异：

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f samples/operator/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yam1 2.yaml
Differences of manifests are:

Object Deployment:istio-system:istio-pilot has diffs:

spec:
  template:
    spec:
      containers:
        '[0]':
          resources:
            requests:
              cpu: 500m -> 1000m
              memory: 2048Mi -> 4096Mi
      nodeSelector: -> map[master:true]
      tolerations: -> [map[effect:NoSchedule key:dedicated operator:Exists] map[key:CriticalAddonsOnly
        operator:Exists]]


Object HorizontalPodAutoscaler:istio-system:istio-pilot has diffs:

spec:
  maxReplicas: 5 -> 10
  minReplicas: 1 -> 2
{{< /text >}}

## 验证安装成功{#verify-a-successful-installation}

您可以使用 `verify-install` 命令检查 Istio 安装是否成功，它将集群上的安装与您指定的清单进行比较。

如果未在部署之前生成清单，请运行以下命令以现在生成它：

{{< text bash >}}
$ istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
{{< /text >}}

然后运行以下 `verify-install` 命令以查看安装是否成功：

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

## 定制配置{#customizing-the-configuration}

除了安装 Istio 的任何内置组件 [配置文件](/zh/docs/setup/additional-setup/config-profiles/)，
`istioctl manifest` 提供了用于自定义配置的完整 API。

- [`IstioControlPlane` API](/zh/docs/reference/config/istio.operator.v1alpha12.pb/)

可以使用命令上的 `--set` 选项分别设置此 API 中的配置参数。 例如，要在默认配置文件中禁用遥测功能，请使用以下命令：

{{< text bash >}}
$ istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true
{{< /text >}}

Alternatively, the `IstioControlPlane` configuration can be specified in a YAML file and passed to
`istioctl` using the `-f` option:

或者，可以在YAML文件中指定 `IstioControlPlane` 配置，并使用 `-f` 选项将其传递给 `istioctlt`：

{{< text bash >}}
$ istioctl manifest apply -f samples/operator/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
为了向后兼容，还完全支持 [Helm 安装](/zh/docs/reference/config/installation-options/)。
若要在命令行中设置它们，请在选项名称前面加上  "`values.`"。
如下所示，下面命令就重写了 Helm 的 `pilot.traceSampling` 配置选项：

{{< text bash >}}
$ istioctl manifest apply --set values.pilot.traceSampling=0.1
{{< /text >}}

如 [Customize Istio settings using the Helm API](#customize-Istio-settings-using-the-helm-API) 所述，Helm 值也可以在 `IstioControlPlane` 定义中设置。
{{< /tip >}}

### 标识 Istio 功能或组件{#identify-an-Istio-feature-or-component}

`IstioControlPlane` API 按功能对控制平面组件进行分组，如下表所示：

| 功能 | 组件 |
|---------|------------|
`base` | `CRDs`
`trafficManagement` | `pilot`
`policy` | `policy`
`telemetry` | `telemetry`
`security` | `citadel`, `nodeAgent`, `certManager`
`configManagement` | `galley`
`gateways` | `ingressGateway`, `egressGateway`
`autoInjection` | `injector`
`coreDNS` | `coreDNS`
`thirdParty` | `cni`

除了核心的 Istio 组件之外，还提供了第三方附加功能和组件：

| 功能 | 组件 |
|---------|------------|
`telemetry` | `prometheus`, `prometheusOperator`, `grafana`, `kiali`, `tracing`

可以启用或禁用功能，这可以启用或禁用作为功能一部分的所有组件。
可以通过组件，功能部件或全局设置组件安装到的命名空间。

### 配置功能或组件设置{#configure-the-feature-or-component-settings}

从上表中识别功能部件或组件的名称后，可以使用 API 设置值
使用 `--set` 标志，或创建一个覆盖文件并使用 `--filename` 标志。
`--set` 标志自定义一些参数的效果很好。
覆盖文件旨在进行更广泛的自定义，或者跟踪配置更改。

最简单的自定义是从配置配置文件默认值打开或关闭功能或组件。

要在默认配置配置文件中禁用遥测功能，请使用以下命令：

{{< text bash >}}
$ istioctl manifest apply --set telemetry.enabled=false
{{< /text >}}

或者，您可以使用配置覆盖文件禁用遥测功能：

1. 创建一个文件 `telemetry_off.yaml` 文件并且写入以下内容：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  telemetry:
    enabled: false
{{< /text >}}

1. 将 `telemetry_off.yaml` 覆盖文件与 `manifest apply` 命令一起使用：

{{< text bash >}}
$ istioctl manifest apply -f telemetry_off.yaml
{{< /text >}}

您还可以使用这种方法来设置组件级配置，例如启用节点代理：

{{< text bash >}}
$ istioctl manifest apply --set security.components.nodeAgent.enabled=true
{{< /text >}}

另一个定制是为功能部件和组件选择不同的命名空间。
以下是一个定制命名空间的例子：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  defaultNamespace: istio-system
  security:
    namespace: istio-security
    components:
      citadel:
        namespace: istio-citadel
{{< /text >}}

安装此文件将应用默认配置文件，并将组件安装到以下命名空间中：

- Citadel 组件 将被安装到 `istio-citadel` 命名空间
- 所有其他安全相关的组件将被安装到 `istio-security` 命名空间
- 剩余的 Istio 组件安装到 istio-system 命名空间

### 自定义 Kubernetes 设置{#customize-Kubernetes-settings}

`IstioControlPlane` API 允许以一致的方式自定义每个组件的 Kubernetes 设置。

每一个组件都有一个允许修改配置的 [`KubernetesResourceSpec`](/zh/docs/reference/config/istio.operator.v1alpha12.pb/#KubernetesResourcesSpec)。使用此列表来标识要自定义的设置：

1. [Resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)
1. [Readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
1. [Replica count](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
1. [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
1. [`PodDisruptionBudget`](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)
1. [Pod annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
1. [Service annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
1. [`ImagePullPolicy`](https://kubernetes.io/docs/concepts/containers/images/)
1. [Priority class name](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)
1. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
1. [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)

所有这些 Kubernetes 设置都使用 Kubernetes API 定义，因此 [Kubernetes文档](https://kubernetes.io/docs/concepts/) 可以用作参考。

以下示例覆盖文件可调整 `TrafficManagement` 功能的资源和 pod 的自动水平缩放的 Pilot 设置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  trafficManagement:
    components:
      pilot:
        k8s:
          resources:
            requests:
              cpu: 1000m # override from default 500m
              memory: 4096Mi # ... default 2048Mi
          hpaSpec:
            maxReplicas: 10 # ... default 5
            minReplicas: 2  # ... default 1
          nodeSelector:
            master: "true"
          tolerations:
          - key: dedicated
            operator: Exists
            effect: NoSchedule
          - key: CriticalAddonsOnly
            operator: Exists
{{< /text >}}

使用 `manifest apply` 将修改后的设置应用于集群：

{{< text syntax="bash" repo="operator" >}}
$ istioctl manifest apply -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### 使用 Helm API 自定义 Istio 设置{#customize-Istio-settings-using-the-helm-API}

`IstioControlPlane` API 使用 `values` 字段直接调用 [Helm API](/zh/docs/reference/config/installation-options/) 的接口对于字段进行设值。

下面的 YAML 文件可以通过 Helm API 配置全局和 Pilot 配置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  trafficManagement:
    components:
      pilot:
        values:
          traceSampling: 0.1 # override from 1.0

  # global Helm settings
  values:
    global:
      monitoringPort: 15050
{{< /text >}}

一些参数将在 Helm 和 `IstioControlPlane` API 中暂时存在，包括 Kubernetes 资源，
命名空间和启用设置。 Istio 社区建议使用 `IstioControlPlane` API，因为它更专一，经过验证并遵循[社区毕业流程](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist)。

## 卸载 Istio{#uninstall-Istio}

可以使用以下命令来卸载 Istio：

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete -f -
{{< /text >}}
