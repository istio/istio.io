---
title: 安装 Gateway
description: 安装和定制 Istio Gateway。
weight: 40
keywords: [install,gateway,kubernetes]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
如果您使用 Gateway API，将不需要安装和管理本文所述的网关 `Deployment`。
默认情况下，网关 `Deployment` 和 `Service` 将基于 `Gateway` 配置被自动制备。
更多细节请参阅 [Gateway API 任务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)。
{{< /tip >}}

除了创建服务网格，Istio 还允许您管理[网关](/zh/docs/concepts/traffic-management/#gateways)，
作为 Envoy 代理运行在网格的边缘处，以精细粒度控制进出网格的流量。

Istio 内置的一些[配置文件](/zh/docs/setup/additional-setup/config-profiles/)在安装期间部署网关。
例如通过[默认设置](/zh/docs/setup/install/istioctl/#install-istio-using-the-default-profile)对
`istioctl install` 的调用将部署 Ingress 网关和控制面。
尽管在评估和简单使用场景中这个够用了，但耦合到控制面的网关后，会让管理和升级变得复杂。
对于生产环境中的 Istio 部署，强烈推荐将这些解耦，以便进行独立的操作。

遵循本指南在 Istio 的生产安装环境中分别部署和管理一个或多个网关。

## 先决条件  {#prerequisites}

本指南需要先[安装好 Istio 控制面](/zh/docs/setup/install/)，再继续操作。

{{< tip >}}
您可以使用诸如 `istioctl install --set profile=minimal` 的 `minimal` 配置，
避免在安装期间部署任何网关。
{{< /tip >}}

## 部署网关  {#deploy-gateway}

使用与 [Istio Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)相同的机制，
可以用类似的方式自动注入网关所用的 Envoy 代理配置。

对于网关 Deployment 推荐使用自动注入，因为这样可以让开发者完全控制网关 Deployment，简化了操作。
当新的升级可用时或配置发生变化时，只需重启就能更新网关 Pod。
这使得操作网关 Deployment 的体验与操作 Sidecar 的体验相同。

为了支持用户使用现有的部署工具，Istio 提供了几种不同的方式来部署网关。
每种方法都会产生相同的结果。请选择您最熟悉的方法。

{{< tip >}}
作为一种安全的最佳实践，推荐从控制面将网关部署到不同的命名空间中。
{{< /tip >}}

以下列出的所有方法均依赖于[注入](/zh/docs/setup/additional-setup/sidecar-injection/)，
在运行时填充附加的 Pod 设置。
为此，部署网关所在的命名空间不得带有 `istio-injection=disabled` 标签。
如果带有此标签，您会看到 Pod 在尝试拉取 `auto` 镜像时失败，
此镜像是创建 Pod 时将要替换的占位符。

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

首先设置名为 `ingress.yaml` 的 `IstioOperator` 配置文件：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: ingress
spec:
  profile: empty # 不安装 CRD 或控制平面
  components:
    ingressGateways:
    - name: istio-ingressgateway
      namespace: istio-ingress
      enabled: true
      label:
        # 为网关设置唯一标签。
        # 这是确保 Gateway 可以选择此工作负载所必需的。
        istio: ingressgateway
  values:
    gateways:
      istio-ingressgateway:
        # 启用网关注入
        injectionTemplate: gateway
{{< /text >}}

然后使用标准的 `istioctl` 命令安装：

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ istioctl install -f ingress.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用标准的 `helm` 命令安装：

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ helm install istio-ingressgateway istio/gateway -n istio-ingress
{{< /text >}}

要查看支持的所有可能的配置值，请运行 `helm show values istio/gateway`。
Helm 代码仓库中的 [README](https://artifacthub.io/packages/helm/istio-official/gateway)
包含了更多使用信息。

{{< tip >}}

在一个 OpenShift 集群中部署网关时，请使用 `openshift-values.yaml` 文件覆盖默认值，例如：

{{< text bash >}}
$ helm install istio-ingressgateway istio/gateway -n istio-ingress -f @manifests/charts/gateway/openshift-values.yaml@
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Kubernetes YAML" category-value="yaml" >}}

首先设置名为 `ingress.yaml` 的 Kubernetes 配置文件：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  type: LoadBalancer
  selector:
    istio: ingressgateway
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        # 选择网关注入模板（而不是默认的 Sidecar 模板）
        inject.istio.io/templates: gateway
      labels:
        # 为网关设置唯一标签。这是确保 Gateway 可以选择此工作负载所必需的
        istio: ingressgateway
        # 启用网关注入。如果后续连接到修订版的控制平面，请替换为 `istio.io/rev: revision-name`
        sidecar.istio.io/inject: "true"
    spec:
      # 允许绑定到所有端口（例如 80 和 443）
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "0"
      containers:
      - name: istio-proxy
        image: auto # 每次 Pod 启动时，该镜像都会自动更新。
        # 放弃所有 privilege 特权，允许以非 root 身份运行
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337
---
# 设置 Role 以允许读取 TLS 凭据
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

{{< warning >}}
本例显示了让网关运行所需的最小资源。对于生产环境，
推荐进行 `HorizontalPodAutoscaler`、`PodDisruptionBudget` 和资源请求/限制等更多配置。
这些会在使用其他网关安装方法时自动完成配置。
{{< /warning >}}

{{< tip >}}
本例中对 Pod 使用了 `sidecar.istio.io/inject` 标签来启用注入。
就像应用程序 Sidecar 注入，这可以转为在命名空间级别进行控制。
更多细节请参阅[控制注入策略](/zh/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy)。
{{< /tip >}}

接下来将其应用到集群：

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ kubectl apply -f ingress.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 管理网关  {#manage-gateway}

本节说明了如何在安装之后管理网关。有关具体用法的更多信息，请参阅
[Ingress](/zh/docs/tasks/traffic-management/ingress/) 和
[Egress](/zh/docs/tasks/traffic-management/egress/) 任务。

### Gateway 选择算符  {#gateway-selectors}

网关 Deployment Pod 上的标签由 `Gateway` 配置资源使用，
因此重要的是您的 `Gateway` 选择算符要与这些标签匹配。

例如在上述 Deployment 中，在网关 Pod 上设置 `istio=ingressgateway` 标签。
要将 `Gateway` 应用到这些 Deployment，您需要选择相同的标签：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
...
{{< /text >}}

### 网关部署拓扑  {#gateway-deployment-topologies}

根据您的网格配置和使用场景，您可能希望以不同的方式部署网关。
以下演示了几种不同的网关部署模式。请注意，在同一个集群内可以使用多种模式。

#### 共享网关  {#shared-gateway}

在此模型中，单个集中的网关由许多应用一起使用，可能还会跨许多命名空间使用。
`ingress` 命名空间中的网关委派路由的所有权到应用程序命名空间，但保留对 TLS 配置的控制。

{{< image width="50%" link="shared-gateway.svg" caption="共享网关" >}}

此模型适用于您有许多应用程序想要对外暴露时，这是因为这些应用程序可以使用共享的基础设施。
在许多应用程序共享相同的域或 TLS 证书的使用场景中，这种模型也能良好工作。

#### 专用的应用程序网关  {#dedicated-app-gateway}

在此模型中，应用程序命名空间具有其自身专用的网关组件。
这允许完全控制单个命名空间并赋予该命名空间的所有权。
这一级的隔离对性能或安全要求严格的关键应用程序很有帮助。

{{< image width="50%" link="user-gateway.svg" caption="专用应用程序网关" >}}

除非在 Istio 之前存在另一个负载均衡器，否则这通常意味着每个应用程序将具有自身的
IP 地址，这可能会让 DNS 配置变得复杂。

## 升级网关  {#upgrading-gateways}

### 就地升级  {#in-place-upgrade}

因为网关利用 Pod 注入，所以新创建的网关 Pod 将自动被注入包括版本在内的最新配置。

要应用对网关配置的变更，只需使用 `kubectl rollout restart deployment` 这类命令重启 Pod 即可。

如果您想要通过网关更改正在使用的[控制面修订版](/zh/docs/setup/upgrade/canary/)，
您可以在网关 Deployment 上设置 `istio.io/rev` 标签，这也会触发滚动重启。

{{< image width="50%" link="inplace-upgrade.svg" caption="正在就地升级" >}}

### 金丝雀升级  {#canary-upgrade-advanced}

{{< warning >}}
此升级方法取决于控制面修订版，且因此只能结合[控制面金丝雀升级](/zh/docs/setup/upgrade/canary/)一起使用。
{{< /warning >}}

如果想要延后新控制面修订版的发版时间，您可以运行多个版本的网关 Deployment。
例如如果您想要推出一个新修订版 `canary`，可以设置 `istio.io/rev=canary`
标签后创建网关 Deployment 的副本。

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway-canary
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: ingressgateway
        istio.io/rev: canary # 设置为你要部署的控制平面的修订版
    spec:
      containers:
      - name: istio-proxy
        image: auto
{{< /text >}}

当此 Deployment 被创建时，您将具有被同一个 Service 选中的两个版本的网关：

{{< text bash >}}
$ kubectl get endpoints -n istio-ingress -o "custom-columns=NAME:.metadata.name,PODS:.subsets[*].addresses[*].targetRef.name"
NAME                   PODS
istio-ingressgateway   istio-ingressgateway-...,istio-ingressgateway-canary-...
{{< /text >}}

{{< image width="50%" link="canary-upgrade.svg" caption="正在金丝雀升级" >}}

与网格内部署的应用程序服务不同，您不能使用
[Istio 流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)在网格版本之间分发流量，
因为流量直接来自 Istio 控制之外的外部客户端。
作为替代方案，您可以通过每个 Deployment 的副本数来控制流量的分发。
如果您在 Istio 之前使用另一个负载均衡器，您还可以使用此负载均衡器来控制流量分发。

{{< warning >}}
因为其他安装方法捆绑了控制外部 IP 地址的网关 `Service` 和网关 `Deployment`，所以这种升级方法仅支持
[Kubernetes YAML](/zh/docs/setup/additional-setup/gateway/#tabset-docs-setup-additional-setup-gateway-1-2-tab) 方法。
{{< /warning >}}

### 通过外部流量转移进行金丝雀升级（高级）{#canary-upgrade-with-external-traffic-shifting}

[金丝雀升级](#canary-upgrade)的各种方法在 Istio 外使用高级组件（例如外部负载均衡器或 DNS）在各版本之间转移流量。

{{< image width="50%" link="high-level-canary.svg" caption="正在用外部流量转移进行金丝雀升级" >}}

这提供了精细粒度的控制，但可能不适合在某些环境中搭建或过于复杂。
