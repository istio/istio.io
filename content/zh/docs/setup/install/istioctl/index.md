---
title: 使用 Istioctl 安装
description: 安装、定制 Istio 配置文件，用于深入评估、及生产发布。
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

跟随本指南安装、配置 Istio 网格，用于深入评估、及生产发布。
如果你是 Istio 新手，只想简单尝试，请参考[快速入门指南](/zh/docs/setup/getting-started)。

本安装指南使用命令行工具 [istioctl](/zh/docs/reference/commands/istioctl/)，
它提供丰富的定制功能，用于定制 Istio 控制平面，以及数据平面 sidecar。
它还提供用户输入验证功能，这有助于防止安装错误；提供定制选项，可以覆盖配置的任何方面。

使用这些说明，你可以选取任意一个 Istio 内置的
[配置档](/zh/docs/setup/additional-setup/config-profiles/)，
为你的特定需求进一步定制配置。

`istioctl` 命令通过命令行的选项支持完整的
[`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)，
这些选项用于单独设置、以及接收包含 IstioOperator {{<gloss CRDs>}}定制资源（CR）{{</gloss>}}的 yaml 文件，

{{< tip >}}
Istio 生产环境最佳实践：在一个 `IstioOperator` CR 中提供完整的配置。
你除了使用 `istioctl` 手动完成，还可以选择把安装管理工作整体委托给 [Istio Operator](/zh/docs/setup/install/operator)。
{{< /tip >}}

## 先决条件 {#prerequisites}

开始之前，检查下列先决条件：

1. [下载 Istio 发行版](/zh/docs/setup/getting-started/#download).
1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/).
1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/).

## 使用默认配置档安装 Istio {#install-using-default-profile}

最简单的选择是用下面命令安装 Istio 默认
[配置档](/zh/docs/setup/additional-setup/config-profiles/)：

{{< text bash >}}
$ istioctl install
{{< /text >}}

此命令在 Kubernetes 集群上安装 `default` 配置档。
`default` 配置档是建立生产环境的一个良好起点，
这和较大的 `demo` 配置档不同，后者常用于评估一组广泛的 Istio 特性。

可以配置各种设置来修改安装。比如，要启动访问日志：

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
本页和文档其他地方的许多示例都是使用 `--set` 来修改安装参数，
而不是用 `-f` 传递配置文件。
这么做可以让例子更紧凑。
这两种方法是等价的，但强烈推荐在生产环境使用 `-f`。
上面的命令可以用 `-f` 写成如下的形式：

{{< text yaml >}}
# my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

{{< text bash >}}
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
完整的 API 记录在 [`IstioOperator` API 参考文档](/zh/docs/reference/config/istio.operator.v1alpha1/)。
通常，你可以像使用 Helm 一样，在 `istioctl` 中使用 `--set` 参数，
并且当前 Helm 的 `values.yaml` API 向后兼容。
唯一的区别是你必须给原有 `values.yaml` 路径前面加上 `values.` 前缀，这是 Helm 透传 API 的前缀。
{{< /tip >}}

## 从外部 chart 安装 {#install-from-external-charts}

默认情况下，`istioctl` 使用内置 chart 生成安装清单。
这些 chart 随同 `istioctl` 一起发布，用以满足审计和定制，你可以在发行包的 `manifests` 目录下找到它们。
`istioctl` 除了使用内置 chart 外，还可以使用外部 chart。
为了选择外部 chart，可以设置参数 `manifests` 指向本地文件系统路径：

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

如果使用 `istioctl` {{< istio_full_version >}} 版本的二进制文件，此命令将得到和独立运行 `istioctl install` 相同的结果，
这是因为它指向了和内置 chart 相同的 chart。
除非要实验或测试新特性，我们建议使用内置的 chart，而不是外部 chart，以保障 `istioctl` 与 chart 的兼容性。

## 安装一个不同的配置档 {#install-a-different-profile}

其他的 Istio 配置档，可以通过在命令行传递配置档名称的方式，安装到集群。
例如，下面命令可以用来安装 `demo` 配置档。

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## 检查安装了什么 {#check-whats-installed}

`istioctl` 命令把安装 Istio 的 `IstioOperator` CR 保存到一个叫 `installed-state` 的 CR 副本中。
故无须检查 Istio 安装的 deployments、 pods、 services等其他资源，例如：

{{< text bash >}}
$ kubectl -n istio-system get deploy
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
istio-ingressgateway   1/1     1            1           49m
istiod                 1/1     1            1           49m
{{< /text >}}

可以查看 `installed-state` CR，来了解集群中都安装了什么，也可以看到所有的定制设置。
例如：用下面命令将它的内容导出到一个 YAML 文件：

{{< text bash >}}
$ kubectl -n istio-system get IstioOperator installed-state -o yaml > installed-state.yaml
{{< /text >}}

在一些  `istioctl` 命令中，`installed-state` CR 被用于执行检查任务，因此不能删除：

## 展示可用配置档的列表 {#display-the-list-of-available-profiles}

你可以用下面命令展示 `istioctl` 可以访问到的 Istio 配置档的名称：

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
{{< /text >}}

## 展示配置档的配置信息 {#display-the-configuration-of-a-profile}

你可以浏览一个配置档的配置信息。例如，运行下面命令浏览  `demo`  配置档的设置信息：

{{< text bash >}}
$ istioctl profile dump demo
components:
  egressGateways:
  - enabled: true
    k8s:
      resources:
        requests:
          cpu: 10m
          memory: 40Mi
    name: istio-egressgateway

...
{{< /text >}}

只浏览配置文件的某个部分的话，可以用 `--config-path` 参数，它将只选择配置文件中指定路径的局部内容：

{{< text bash >}}
$ istioctl profile dump --config-path components.pilot demo
enabled: true
k8s:
  env:
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 1
    periodSeconds: 3
    timeoutSeconds: 5
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
  strategy:
    rollingUpdate:
      maxSurge: 100%
      maxUnavailable: 25%
{{< /text >}}

## 显示配置文件的差异 {#show-differences-in-profiles}

`profile diff` 子命令可用于显示配置档之间的差异，
它在把更改应用到集群之前，检查定制效果方面非常有用。

你可以使用此命令显示 default 和 demo 两个配置档之间的差异：

{{< text bash >}}
$ istioctl profile diff default demo
 gateways:
   egressGateways:
-  - enabled: false
+  - enabled: true
...
     k8s:
        requests:
-          cpu: 100m
-          memory: 128Mi
+          cpu: 10m
+          memory: 40Mi
       strategy:
...
{{< /text >}}

## 安装前生成清单文件 {#generate-a-manifest-before-installation}

在安装 Istio 之前，可以用 `manifest generate` 子命令生成清单文件。
例如，用下面命令生成 `default` 配置档的清单文件：

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

生成的清单文件可用于检查具体安装了什么，也可用于跟踪清单是如何随着时间而改变的。
虽然 `IstioOperator` CR 代表完整的用户配置，足以用于跟踪，
但 `manifest generate` 命令的输出还能截获底层 chart 潜在的改变，因此可以用于跟踪实际安装过的资源。

`manifest generate` 的输出还能传递给 `kubectl apply` 或类似的命令，用来安装 Istio。
然而，这些替代的安装方法不能像 `istioctl install` 那样，将相同的依赖顺序应用于资源，
并且也没有在 Istio 发行版中测试过。

{{< warning >}}
如果尝试使用 `istioctl manifest generate` 安装和管理 Istio，请注意以下事项：

1. Istio 的命名空间（默认为`istio-system`）必须手工创建。

1. `istioctl install` 会在 Kubernetes 上下文中自动探测环境特定的设置，
但以离线运行的 `manifest generate` 不行，而且可能导致意外结果。
特别是，如果 Kubernetes 环境不支持第三方服务帐户令牌，则必须确保遵循[这些步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)。

1. 用 `kubectl apply` 执行生成的清单，会显示临时错误，这是因为集群中的资源进入可用状态的顺序有问题。

1. `istioctl install` 自动清除一些资源，其实这些资源在配置改变时（例如，当你删除网关）就应该被删掉了。
但此机制在 `kubectl` 和 `istio manifest generate` 协同使用时并不会发生，所以这些资源必须手动删除。

{{< /warning >}}

## 显示清单的差异 {#show-differences-in-manifests}

使用这一组命令，以 YAML 风格的差异对比方式，显示 default 配置项和定制安装生成的两个清单之间的差异：

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f operator/samples/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yaml 2.yaml
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

## 验证安装是否成功 {#verify-a-successful-installation}

你可以用 `verify-install` 命令检查 Istio 是否安装成功，此命令用你指定的清单对比集群中实际的安装情况。

如果你在部署前还没有生成清单文件，那现在就运行下面命令生成一个：

{{< text bash >}}
$ istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
{{< /text >}}

紧接着运行 `verify-install` 命令，查看安装是否成功：

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

## 定制配置 {#customizing-the-configuration}

除了安装 Istio 内置的 [配置档](/zh/docs/setup/additional-setup/config-profiles/)，
`istioctl install` 提供了一套完整的用于定制配置的API。

- [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)

此 API 中的配置参数能用命令行选项 `--set` 独立设置。
例如，要在 default 配置档中启动调试日志特性，使用这个命令：

{{< text bash >}}
$ istioctl install --set values.global.logging.level=debug
{{< /text >}}

或者，可以在 YAML 文件中指定 `IstioOperator` 的配置，然后用  `-f` 选项传递给 `istioctl` ：

{{< text bash >}}
$ istioctl install -f operator/samples/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
为了向后兼容，以前的 [Helm 安装选项](https://archive.istio.io/v1.4/docs/reference/config/installation-options/)，除了 Kubernetes 资源设置之外，均被完整的支持。
为了在命令行设置他们，在选项名前面加上 "`values.`"。
例如，下面的命令覆盖了 Helm 配置选项 `pilot.traceSampling`：

{{< text bash >}}
$ istioctl install --set values.pilot.traceSampling=0.1
{{< /text >}}

Helm 值也可以在 `IstioOperator` CR（YAML 文件）中设置，就像[使用 Helm API 定制 Istio 设置](#customize-settings-using-the-helm) 中描述的那样。

如果你需要配置 Kubernetes 资源方面的设置，请用[定制 Kubernetes 设置](#customize-k-settings)中介绍的 `IstioOperator` API。
{{< /tip >}}

### 识别 Istio 组件 {#identify-an-component}

`IstioOperator` API 定义的组件如下面表格所示：

| 组件 |
| ------------|
`base` |
`pilot` |
`ingressGateways` |
`egressGateways` |
`cni` |
`istiodRemote` |

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

### 定制 Kubernetes 设置 {#customize-k-settings}

`IstioOperator` API 支持以一致性的方式定制每一个组件的 Kubernetes 设置。

每个组件都有一个 [`KubernetesResourceSpec`](/zh/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpec)，
它允许修改如下设置。
使用此列表标识要定制的设置：

1. [Resources](https://kubernetes.io/zh/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)
1. [Readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
1. [Replica count](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/)
1. [`HorizontalPodAutoscaler`](https://kubernetes.io/zh/docs/tasks/run-application/horizontal-pod-autoscale/)
1. [`PodDisruptionBudget`](https://kubernetes.io/zh/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)
1. [Pod annotations](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/annotations/)
1. [Service annotations](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/annotations/)
1. [`ImagePullPolicy`](https://kubernetes.io/zh/docs/concepts/containers/images/)
1. [Priority class name](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)
1. [Node selector](https://kubernetes.io/zh/docs/concepts/configuration/assign-pod-node/#nodeselector)
1. [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)
1. [Service](https://kubernetes.io/zh/docs/concepts/services-networking/service/)
1. [Toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
1. [Strategy](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/)
1. [Env](https://kubernetes.io/zh/docs/tasks/inject-data-application/define-environment-variable-container/)
1. [Pod security context](https://kubernetes.io/zh/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

所有这些 Kubernetes 设置均使用 Kubernetes API 定义，因此可以参考 [Kubernetes 文档](https://kubernetes.io/zh/docs/concepts/)

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
        nodeSelector:
          master: "true"
        tolerations:
        - key: dedicated
          operator: Exists
          effect: NoSchedule
        - key: CriticalAddonsOnly
          operator: Exists
{{< /text >}}

用 `istioctl install` 把改变的设置应用到集群：

{{< text syntax="bash" repo="operator" >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### 使用 Helm API 定制 Istio 设置 {#customize-settings-using-the-helm}

`IstioOperator` API 使用 `values` 字段为 [Helm API](https://archive.istio.io/v1.4/docs/reference/config/installation-options/) 保留了一个透传接口。

下面的 YAML 文件通过 Helm API 来配置 global 和 Pilot 的设置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      traceSampling: 0.1 # override from 1.0
    global:
      monitoringPort: 15050
{{< /text >}}

一些参数，比如 Kubernetes resources、namespaces、和开关设置，暂时并存在 Helm 和 `IstioOperator` APIs 中。
Istio 社区推荐使用 `IstioOperator` API ，因为它更一致、更有效、且遵循[社区毕业流程](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist).

### 配置网关 {#configure-gateways}

网关因为支持定义多个入站、出站网关，所以它是一种特殊类型的组件。
在 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/) 中，网关被定义为列表类型。
`default` 配置档会安装一个名为 `istio-ingressgateway` 的入站网关。
你可以检查这个网关的默认值：

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
如果必须为每个网关定制这些选项，建议你使用一个独立的 IstioOperator CR 来生成用户网关的清单，并和 Istio 主安装清单隔离。

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

### 定制外部 chart 和配置项 {#customizing-external-charts-and-profiles}

`istioctl` 的 `install`、 `manifest generate` 和 `profile` 命令可以使用以下任意源来生成 chart 和 配置档：

- 内置的 chart。如果没有设置 `--manifests`，则用 default。
内置的 chart 和 Istio `.tgz` 发行包内 `manifests/` 目录下的内容相同。
- 本地文件系统中的chart，例如，`istioctl install --manifests istio-{{< istio_full_version >}}/manifests`
- GitHub 上的 chart，例如，`istioctl install --manifests https://github.com/istio/istio/releases/download/{{< istio_full_version >}}/istio-{{< istio_full_version >}}-linux-arm64.tar.gz`

本地文件系统的 chart 和配置档可以通过编辑 `manifests/` 目录下的文件定制。
要进行广泛的更改，建议拷贝 `manifests` 目录，然后修改副本。
但请注意，`manifests` 目录中的内容结构必须要保留。

存放在目录 `manifests/profiles/` 下面配置档，可编辑，也可通过创建一个指定配置档名称和 `.yaml` 新文件的方式来添加。
`istioctl` 扫描 `profiles` 子目录，所有找到的配置档都可以在 `IstioOperatorSpec` 的 profile 字段中通过名称引用。
在用户的覆盖配置被应用前，内建 profile 默认的 YAML 文件被覆写。
例如，你可以创建一个名为 `custom1.yaml` 的新profile，新配置档在 `default` 配置档的基础上定制了部分设置，然后应用用户的覆盖文件：

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

### 为输出清单打补丁  {#patching-the-output-manifest}

传递给 `istioctl` 的 `IstioOperator` CR，用于生成输出清单，该清单包含将应用到集群的 Kubernetes 资源。
在输出的清单已经生成但没有应用之时，此清单可以通过 `IstioOperator` [覆盖](/zh/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay) API 深度定制以增加、修改、或删除资源。

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
              # Select list item by value
              - path: spec.template.spec.containers.[name:discovery].args.[30m]
                value: "60m" # overridden from 30m
              # Select list item by key:value
              - path: spec.template.spec.containers.[name:discovery].ports.[containerPort:8080].containerPort
                value: 1234
              # Override with object (note | on value: first line)
              - path: spec.template.spec.containers.[name:discovery].env.[name:POD_NAMESPACE].valueFrom
                value: |
                  fieldRef:
                    apiVersion: v2
                    fieldPath: metadata.myPath
              # Deletion of list item
              - path: spec.template.spec.containers.[name:discovery].env.[name:REVISION]
              # Deletion of map item
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

`istioctl --set` 参数和 `IstioOperator` CR 中的 `k8s.overlays` 字段，两者均支持由`[index]`、 `[value]`、或 `[key:value]` 选中的列表项。
--set 参数也为资源中缺少的路径创建所有的中间节点。

## 卸载 Istio {#uninstall}

要从集群中完整卸载 Istio，运行下面命令：

{{< text bash >}}
$ istioctl x uninstall --purge
{{< /text >}}

{{< warning >}}
可选的 `--purge` 参数将删除所有 Istio 资源，包括可能被其他 Istio 控制平面共享的、集群范围的资源。
{{< /warning >}}

或者，只删除指定的 Istio 控制平面，运行以下命令：

{{< text bash >}}
$ istioctl x uninstall <your original installation options>
{{< /text >}}

或

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete -f -
{{< /text >}}

控制平面的命名空间（例如：`istio-system`）默认不会删除，
如果确认不再需要，用下面命令删除它：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
