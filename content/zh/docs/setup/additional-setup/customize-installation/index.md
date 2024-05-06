---
title: 定制安装配置
description: 描述如何定制安装配置选项。
weight: 50
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

## 先决条件 {#prerequisites}

开始之前，检查下列先决条件：

1. [下载 Istio 发行版](/zh/docs/setup/getting-started/#download)。
1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/)。
1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/)。

除了安装 Istio 内置的 [配置档](/zh/docs/setup/additional-setup/config-profiles/)，
`istioctl install` 提供了一套完整的用于定制配置的 API。

- [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)

此 API 中的配置参数能用命令行选项 `--set` 独立设置。
例如，要在 default 配置档中启动调试日志特性，使用这个命令：

{{< text bash >}}
$ istioctl install --set values.global.logging.level=debug
{{< /text >}}

或者，可以在 YAML 文件中指定 `IstioOperator` 的配置，然后用 `-f` 选项传递给 `istioctl`：

{{< text bash >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
为了向后兼容，以前的 [Helm 安装选项](https://archive.istio.io/v1.4/docs/reference/config/installation-options/)，
除了 Kubernetes 资源设置之外，均被完整的支持。为了在命令行设置他们，在选项名前面加上 "`values.`"。
例如，下面的命令覆盖了 Helm 配置选项 `pilot.traceSampling`：

{{< text bash >}}
$ istioctl install --set values.pilot.traceSampling=0.1
{{< /text >}}

Helm 值也可以在 `IstioOperator` CR（YAML 文件）中设置，就像[使用 Helm API 定制 Istio 设置](#customize-istio-settings-using-the-helm-api)
中描述的那样。

如果您需要配置 Kubernetes 资源方面的设置，请用[定制 Kubernetes 设置](#customize-kubernetes-settings)中介绍的
`IstioOperator` API。
{{< /tip >}}

### 识别 Istio 组件 {#identify-an-istio-component}

`IstioOperator` API 定义的组件如下面表格所示：

| 组件             |
| ----------------|
`base`            |
`pilot`           |
`ingressGateways` |
`egressGateways`  |
`cni`             |
`istiodRemote`    |

针对每一个组件的配置内容通过 `components.<component name>` 下的 API 中提供。
例如，要用 API 改变（改为 false）`pilot` 组件的 `enabled` 设置，
使用 `--set components.pilot.enabled=false`，
或在 `IstioOperator` 资源中就像这样来设置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      enabled: false
{{< /text >}}

所有的组件共享一个通用 API，用来修改 Kubernetes 特定的设置，它在 `components.<component name>.k8s` 路径下，
后续章节将会进一步描述它。

### 定制 Kubernetes 设置 {#customize-kubernetes-settings}

`IstioOperator` API 支持以一致性的方式定制每一个组件的 Kubernetes 设置。

每个组件都有一个 [`KubernetesResourceSpec`](/zh/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpec)，
它允许修改如下设置。使用此列表标识要定制的设置：

1. [资源](https://kubernetes.io/zh-cn/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container)
1. [就绪探测](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
1. [副本数](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/)
1. [`HorizontalPodAutoscaler`](https://kubernetes.io/zh-cn/docs/tasks/run-application/horizontal-pod-autoscale/)
1. [`PodDisruptionBudget`](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)
1. [Pod 注解](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/annotations/)
1. [服务（Service）注解](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/annotations/)
1. [`ImagePullPolicy`](https://kubernetes.io/zh-cn/docs/concepts/containers/images/)
1. [优先级类名称](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass)
1. [节点选择器](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)
1. [亲和性与反亲和性](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
1. [服务（Service）](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)
1. [容忍度](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration)
1. [策略](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/)
1. [环境变量](https://kubernetes.io/zh-cn/docs/tasks/inject-data-application/define-environment-variable-container/)
1. [Pod 安全性上下文](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
1. [卷及其挂载](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/)

所有这些 Kubernetes 设置均使用 Kubernetes API 定义，因此可以参考
[Kubernetes 文档](https://kubernetes.io/zh-cn/docs/concepts/)

下面覆盖文件的例子调整 Pilot 的资源限制和 Pod 水平伸缩的设置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
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
{{< /text >}}

用 `istioctl install` 把改变的设置应用到集群：

{{< text syntax="bash" repo="operator" >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### 使用 Helm API 定制 Istio 设置 {#customize-istio-settings-using-the-helm-api}

`IstioOperator` API 使用 `values` 字段为
[Helm API](https://archive.istio.io/v1.4/docs/reference/config/installation-options/)
保留了一个透传接口。

下面的 YAML 文件通过 Helm API 来配置 global 和 Pilot 的设置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      traceSampling: 0.1 # override from 1.0
    global:
      monitoringPort: 15014
{{< /text >}}

诸如 Kubernetes 资源、命名空间和开关设置等参数暂时并存在 Helm 和 `IstioOperator` API 中。
Istio 社区推荐使用 `IstioOperator` API，因为它更一致、更有效、
且遵循[社区毕业流程](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist)。

### 配置网关 {#configure-gateways}

网关因为支持定义多个入站、出站网关，所以它是一种特殊类型的组件。
在 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/) 中，
网关被定义为列表类型。`default` 配置档会安装一个名为 `istio-ingressgateway` 的入站网关。
您可以检查这个网关的默认值：

{{< text bash >}}
$ istioctl profile dump --config-path components.ingressGateways
$ istioctl profile dump --config-path values.gateways.istio-ingressgateway
{{< /text >}}

这些命令显示了网关的 `IstioOperator` 和 Helm 两种设置，它们一起用于定义生成的网关资源。
内置的网关就像其他组件一样的可以被定制。

{{< warning >}}
从 1.7 开始，覆盖路由配置时必须指定路由名称。
不指定名称时，也不会再设置 `istio-ingressgateway` 或 `istio-egressgateway` 做为默认名称。
{{< /warning >}}

新的用户网关可以通过添加新的列表条目来创建：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
      - namespace: user-ingressgateway-ns
        name: ilb-gateway
        enabled: true
        k8s:
          resources:
            requests:
              cpu: 200m
          serviceAnnotations:
            cloud.google.com/load-balancer-type: "internal"
          service:
            ports:
            - port: 8060
              targetPort: 8060
              name: tcp-citadel-grpc-tls
            - port: 5353
              name: tcp-dns
{{< /text >}}

注意：Helm 的值（`spec.values.gateways.istio-ingressgateway/egressgateway`）被所有的入/出站网关共享。
如果必须为每个网关定制这些选项，建议您使用一个独立的 IstioOperator CR 来生成用户网关的清单，并和 Istio 主安装清单隔离。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
      - name: ilb-gateway
        namespace: user-ingressgateway-ns
        enabled: true
        # Copy settings from istio-ingressgateway as needed.
  values:
    gateways:
      istio-ingressgateway:
        debug: error
{{< /text >}}

## 高级安装定制 {#advanced-install-customization}

### 定制外部 Chart 和配置项 {#customizing-external-charts-and-profiles}

`istioctl` 的 `install`、 `manifest generate` 和 `profile` 命令可以使用以下任意源来生成 Chart 和配置项：

- 内置的 Chart。如果没有设置 `--manifests`，则用 default。
  内置的 Chart 和 Istio `.tgz` 发行包内 `manifests/` 目录下的内容相同。
- 本地文件系统中的 Chart，例如 `istioctl install --manifests istio-{{< istio_full_version >}}/manifests`。

本地文件系统的 Chart 和配置档可以通过编辑 `manifests/` 目录下的文件定制。
要进行广泛的更改，建议拷贝 `manifests` 目录，然后修改副本。
但请注意，`manifests` 目录中的内容结构必须要保留。

存放在目录 `manifests/profiles/` 下面配置档，可编辑，也可通过创建一个指定配置档名称和 `.yaml` 新文件的方式来添加。
`istioctl` 扫描 `profiles` 子目录，所有找到的配置档都可以在 `IstioOperatorSpec` 的 profile 字段中通过名称引用。
在用户的覆盖配置被应用前，内建 profile 默认的 YAML 文件被覆写。
例如，您可以创建一个名为 `custom1.yaml` 的新profile，新配置档在 `default` 配置档的基础上定制了部分设置，然后应用用户的覆盖文件：

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ --set profile=custom1 -f path-to-user-overlay.yaml
{{< /text >}}

在此用例中，文件 `custom1.yaml` 和 `user-overlay.yaml` 将覆盖 `default.yaml` 文件，以得到作为 manifest generation 输入的最终值。

通常，没有必要创建新的配置档，这是因为传入多个覆盖文件也可以达到同样的效果。
例如，上面命令等价于传入两个用户覆盖文件：

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ -f manifests/profiles/custom1.yaml -f path-to-user-overlay.yaml
{{< /text >}}

只有需要在 `IstioOperatorSpec` 中指向一个配置档名称时，才需要创建定制配置档。

### 为输出清单打补丁 {#patching-the-output-manifest}

传递给 `istioctl` 的 `IstioOperator` CR，用于生成输出清单，该清单包含将应用到集群的 Kubernetes 资源。
在输出的清单已经生成但没有应用之时，此清单可以通过 `IstioOperator`
[覆盖](/zh/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay)
API 深度定制以增加、修改或删除资源。

下面例子覆盖文件（`patch.yaml`）展示输出清单补丁这种类型可以做什么：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  hub: docker.io/istio
  tag: 1.1.6
  components:
    pilot:
      enabled: true
      namespace: istio-control
      k8s:
        overlays:
          - kind: Deployment
            name: istiod
            patches:
              # 按值选择列表项
              - path: spec.template.spec.containers.[name:discovery].args.[30m]
                value: "60m" # overridden from 30m
              # 按 key:value 选择列表项
              - path: spec.template.spec.containers.[name:discovery].ports.[containerPort:8080].containerPort
                value: 1234
              # 用对象覆盖（注意 | 值：第一行）
              - path: spec.template.spec.containers.[name:discovery].env.[name:POD_NAMESPACE].valueFrom
                value: |
                  fieldRef:
                    apiVersion: v2
                    fieldPath: metadata.myPath
              # 删除列表项
              - path: spec.template.spec.containers.[name:discovery].env.[name:REVISION]
              # 删除 map 项
              - path: spec.template.spec.containers.[name:discovery].securityContext
          - kind: Service
            name: istiod
            patches:
              - path: spec.ports.[name:https-dns].port
                value: 11111 # OVERRIDDEN
{{< /text >}}

将此文件传给 `istioctl manifest generate -f patch.yaml` 会把上面的补丁应用到 default 配置档的输出清单。
两个打了补丁的资源将做如下修改（为了简洁，只显示资源的部分内容）：

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
spec:
  template:
    spec:
      containers:
      - args:
        - 60m
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v2
              fieldPath: metadata.myPath
        name: discovery
        ports:
        - containerPort: 1234
---
apiVersion: v1
kind: Service
metadata:
  name: istiod
spec:
  ports:
  - name: https-dns
    port: 11111
---
{{< /text >}}

注意：补丁按照给定的顺序执行。每个补丁基于前面补丁的输出来执行。
在补丁中的路径，如果在输出清单不存在，将被创建。

### 列出选中的项目目录 {#list-item-path-selection}

`istioctl --set` 参数和 `IstioOperator` CR 中的 `k8s.overlays` 字段，
两者均支持由 `[index]`、`[value]` 或 `[key:value]` 选中的列表项。--set
参数也为资源中缺少的路径创建所有的中间节点。
