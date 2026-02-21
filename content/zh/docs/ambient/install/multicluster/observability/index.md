---
title: 适用于 Ambient 多网络的 Kiali 仪表盘
description: 配置联邦 Prometheus 实例并在 Ambient 多网络中部署 Kiali。
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /zh/docs/ambient/install/multicluster/verify
---
按照本指南在多网络环境部署中部署多集群感知型 Kiali，以查看集群之间的流量流动情况。

在继续操作之前，请务必完成[开始之前](/zh/docs/ambient/install/multicluster/before-you-begin)、
[多集群安装指南](/zh/docs/ambient/install/multicluster)和[验证您的部署](/zh/docs/ambient/install/multicluster/verify)下的步骤。

本指南首先将部署联邦 Prometheus 实例，用于聚合所有集群的指标。
然后，我们将部署定制的 Kiali 实例，该实例连接到所有集群，并提供统一的网格流量视图。

{{< warning >}}
本指南中所示的配置旨在简化操作，不建议用于生产环境。有关 Prometheus 生产环境部署的最佳实践，
请参阅[使用 Prometheus 进行生产规模监控](/zh/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring)。
有关 Kiali 部署的详细信息，请参阅 [Kiali 文档](https://kiali.io/docs/)。
{{< /warning >}}

## 准备 Kiali 部署 {#prepare-for-kiali-deployment}

我们将把定制的 Prometheus 和 Kiali 安装到单独的命名空间中，所以让我们先在两个集群中创建命名空间：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" create namespace kiali
$ kubectl --context="${CTX_CLUSTER2}" create namespace kiali
{{< /text >}}

我们还将使用 `helm` 来部署 Kiali，所以让我们添加相关的 Helm 仓库：

{{< text bash >}}
$ helm repo add kiali https://kiali.org/helm-charts
{{< /text >}}

## 联邦 Prometheus {#federated-prometheus}

Istio 提供了一个基本的示例安装，可以帮助用户在单集群部署中快速启动并运行
Prometheus - 我们将使用该示例在每个集群中安装 Prometheus。
然后，我们将部署另一个 Prometheus 实例，该实例将抓取每个集群中的 Prometheus 数据并汇总指标。

为了能够抓取远程集群中的 Prometheus，我们将通过 Ingress Gateway 暴露 Prometheus 实例。

### 在每个集群中部署 Prometheus {#deploy-prometheus-in-each-cluster}

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

上述命令将安装 Prometheus，用于从 waypoint 和 ztunnel 收集本地集群指标。

### 暴露 Prometheus {#expose-prometheus}

下一步是将 Prometheus 实例对外公开，​​以便可以抓取它们：

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

我们将在第二个集群中也执行相同的操作：

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 9090
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prometheus
  namespace: istio-system
spec:
  parentRefs:
  - name: prometheus-gateway
    port: 9090
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: prometheus
      port: 9090
EOF
{{< /text >}}

### 汇总指标 {#aggregate-metrics}

集群本地的 Prometheus 实例启动并运行后，我们现在可以设置另一个 Prometheus 实例，
用于抓取这些实例的数据，从而在一个地方收集两个集群的指标。
首先，我们需要为新的 Prometheus 实例创建一个配置，
使其指向要抓取数据的集群本地 Prometheus 实例：

{{< text bash >}}
$ TARGET1="$(kubectl --context="${CTX_CLUSTER1}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ TARGET2="$(kubectl --context="${CTX_CLUSTER2}" get gtw prometheus-gateway -n istio-system -o jsonpath='{.status.addresses[0].value}')"
$ cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'federate-1'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET1}:9090'
        labels:
          cluster: 'cluster1'
  - job_name: 'federate-2'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="kubernetes-pods"}'
    static_configs:
      - targets:
        - '${TARGET2}:9090'
        labels:
          cluster: 'cluster2'
EOF
$ kubectl --context="${CTX_CLUSTER1}" create configmap prometheus-config -n kiali --from-file prometheus.yml
{{< /text >}}

现在我们可以使用该配置来部署一个新的 Prometheus 实例：

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
            defaultMode: 420
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
    service: prometheus
spec:
  ports:
  - port: 9090
    name: http
  selector:
    app: prometheus
EOF
{{< /text >}}

新的 Prometheus 实例部署完成后，将开始从两个集群抓取指标。

### 验证联邦 Prometheus {#verify-federated-prometheus}

为了进行测试，我们可以多次运行 `curl` 命令来生成一些流量，从而访问两个集群中的后端服务器：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
{{< /text >}}

然后我们可以使用 `curl` 查询 Prometheus，看看是否所有集群都已上报指标：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pods ---context="${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s prometheus.kiali:9090/api/v1/query?query=istio_tcp_received_bytes_total | jq '.'
{{< /text >}}

如果 `curl` 请求到达了两个集群的后端，那么对于 `ztunnel` 报告的
`istio_tcp_received_bytes_total` 指标，您应该能够在输出中看到来自两个集群的值：

{{< text plain >}}
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster2",
          ...
          "destination_canonical_revision": "v2",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "5040"
        ]
      },
      ...
      {
        "metric": {
          "__name__": "istio_tcp_received_bytes_total",
          ...
          "app": "ztunnel",
          ...
          "cluster": "cluster1",
          ...
          "destination_canonical_revision": "v1",
          ...
          "destination_canonical_service": "helloworld",
          ...
        },
        "value": [
          1770660628.007,
          "4704"
        ]
      },
      ...
    ]
  }
}
{{< /text >}}

## 部署多集群 Kiali {#deploy-multicluster-kiali}

### 准备远程集群 {#prepare-remote-cluster}

我们只会在一个集群 `cluster1` 中正确部署 Kiali，
但我们仍然需要准备 `cluster2`，以便 Kiali 可以访问其中的资源。
为此，我们将首先部署 Kiali Operator：

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER2}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

Kiali Operator 部署完成后，我们就可以准备所有需要的服务账号、
角色绑定和令牌了。Kiali Operator 会自动创建服务账号和角色绑定，
但我们需要手动为服务账号创建令牌：

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  deployment:
    remote_cluster_resources_only: true
EOF
$ kubectl --context="${CTX_CLUSTER2}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
$ cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f - -n kiali
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: kiali
  annotations:
    kubernetes.io/service-account.name: kiali-service-account
type: kubernetes.io/service-account-token
EOF
{{< /text >}}

### 部署 Kiali {#deploy-kiali}

远程集群准备就绪后，我们现在可以部署 Kiali 服务器了。
我们需要使用 Prometheus 端点的地址和访问远程集群的密钥来配置 Kiali。
和之前一样，我们将从部署 Kiali Operator 开始：

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" install --namespace kiali kiali-operator kiali/kiali-operator --wait
{{< /text >}}

Kiali 项目提供了一个脚本，我们可以使用该脚本创建访问远程集群资源的秘密请求：

{{< text bash >}}
$ curl -L -o kiali-prepare-remote-cluster.sh https://raw.githubusercontent.com/kiali/kiali/master/hack/istio/multicluster/kiali-prepare-remote-cluster.sh
$ chmod +x kiali-prepare-remote-cluster.sh
$ ./kiali-prepare-remote-cluster.sh \
    --kiali-cluster-context "${CTX_CLUSTER1}" \
    --remote-cluster-context "${CTX_CLUSTER2}" \
    --view-only false \
    --process-kiali-secret true \
    --process-remote-resources false \
    --kiali-cluster-namespace kiali \
    --remote-cluster-namespace kiali \
    --kiali-resource-name kiali \
    --remote-cluster-name cluster2
{{< /text >}}

远程 Secret 准备就绪后，我们现在可以部署 Kiali 服务器了：

{{< text bash >}}
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f - -n kiali
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
spec:
  auth:
    strategy: "anonymous"
  external_services:
    prometheus:
      url: http://prometheus.kiali:9090
    grafana:
      enabled: false
  server:
    web_root: "/kiali"
EOF
$ kubectl --context="${CTX_CLUSTER1}" wait --timeout=5m --for=condition=Successful kiali kiali -n kiali
{{< /text >}}

Kiali 服务器运行后，我们可以将本地端口转发到 Kiali 部署，以便在本地访问它：

{{< text syntax=bash snip_id=none >}}
$ kubectl --context="${CTX_CLUSTER1}" port-forward svc/kiali 20001:20001 -n kiali
{{< /text >}}

在浏览器中打开 Kiali 控制面板，导航至流量图，然后从 "Select Namespaces"
下拉菜单中选择 "sample" 命名空间。您应该可以看到集群之间的流量流动情况：

{{< image link="./kiali-traffic-graph.png" caption="Kiali trafic graph dashboard" >}}

{{< tip >}}
如果看不到流量图，请尝试增加流量和/或延长 Kiali 考虑的时间窗口。
{{</ tip >}}

**恭喜！**您已成功安装 Kiali，用于多集群环境部署。

## 清理 Kiali 和 Prometheus {#cleanup-kiali-and-prometheus}

要删除 Kiali，首先要删除 Kiali 自定义资源：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete kiali kiali -n kiali
$ kubectl --context="${CTX_CLUSTER2}" delete kiali kiali -n kiali
{{< /text >}}

自定义资源删除后，Kiali Operator 将停止 Kiali 服务器。
如果您还想删除 Kiali Operator，也可以这样做：

{{< text bash >}}
$ helm --kube-context="${CTX_CLUSTER1}" uninstall --namespace kiali kiali-operator
$ helm --kube-context="${CTX_CLUSTER2}" uninstall --namespace kiali kiali-operator
{{< /text >}}

最后，您可以删除自定义资源定义：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete crd kialis.kiali.io
{{< /text >}}

如果您不需要集群本地的 Prometheus 实例，也可以将其删除：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl --context="${CTX_CLUSTER2}" delete -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}
