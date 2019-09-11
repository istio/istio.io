---
title: 使用 Fluentd 记录日志
description: 此任务说明如何配置 Istio 以将日志输出到 Fluentd 守护程序。
weight: 90
keywords: [telemetry,logging]
---

此任务说明了如何配置 Istio 以创建自定义日志条目并将它们输出到一个 [Fluentd](https://www.fluentd.org/) 守护程序。Fluentd 是一个开源日志收集器，支持许多[数据
输出方式](https://www.fluentd.org/dataoutputs)，而且是可插拔架构。一种流行的日志后端是 [Elasticsearch](https://www.elastic.co/products/elasticsearch)，以及作为展示的 [Kibana](https://www.elastic.co/products/kibana)。在此任务结束时，将会实现一个新的日志流，把日志发送到一个示例 Fluentd / Elasticsearch / Kibana 工具栈。

[Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序被用作贯穿全文的例子。

## 开始之前

* 在您的集群中[安装 Istio](/zh/docs/setup/) 并部署一个应用程序。此任务假设 Mixer 使用默认配置（`--configDefaultNamespace=istio-system`）进行设置。如果你使用不同的配置值，请更新此任务中的配置和命令以匹配该值。

## 安装 Fluentd

在您的集群中可能已经运行了一个 Fluentd 守护程序，例如通过[这里](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)和[这里](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch)描述的 add-on 进行安装，或者由您的集群提供商安装。这很可能会将日志配置为发送到 Elasticsearch 系统或日志提供者。

您可以使用这些 Fluentd 守护程序，或者您配置的其他 Fluentd。只要他们能够监听转发日志，Istio 的 Mixer 就可以连接他们。要使 Istio 的 Mixer 连接到一个运行的 Fluentd 守护程序，您需要为 Fluentd 添加一个 [service](https://kubernetes.io/docs/concepts/services-networking/service/)。监听转发日志的 Fluentd 配置为：

{{< text xml >}}
<source>
  type forward
</source>
{{< /text >}}

将 Mixer 连接到所有可能的 Fluentd 的全部配置细节超出了此任务的范围。

### 示例 Fluentd、Elasticsearch、Kibana 工具栈

为了此任务的目标，您可以部署提供的示例工具栈。此栈在一个非生产就绪的 [Services](https://kubernetes.io/docs/concepts/services-networking/service/) 和 [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 集合中包含了 Fluentd、Elasticsearch 和 Kibana，它们都位于一个名为 `logging` 的新 [Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) 中。

将下面的内容保存为 `logging-stack.yaml`。

{{< text yaml >}}
# Logging Namespace。下列内容都在此 namespace 中.
apiVersion: v1
kind: Namespace
metadata:
  name: logging
---
# Elasticsearch Service
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
spec:
  ports:
  - port: 9200
    protocol: TCP
    targetPort: db
  selector:
    app: elasticsearch
---
# Elasticsearch Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.1.1
        name: elasticsearch
        resources:
          # 在初始化时需要更多的 cpu，因此使用 burstable 级别。
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: discovery.type
            value: single-node
        ports:
        - containerPort: 9200
          name: db
          protocol: TCP
        - containerPort: 9300
          name: transport
          protocol: TCP
        volumeMounts:
        - name: elasticsearch
          mountPath: /data
      volumes:
      - name: elasticsearch
        emptyDir: {}
---
# Fluentd Service
apiVersion: v1
kind: Service
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    app: fluentd-es
spec:
  ports:
  - name: fluentd-tcp
    port: 24224
    protocol: TCP
    targetPort: 24224
  - name: fluentd-udp
    port: 24224
    protocol: UDP
    targetPort: 24224
  selector:
    app: fluentd-es
---
# Fluentd Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    app: fluentd-es
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: fluentd-es
    spec:
      containers:
      - name: fluentd-es
        image: gcr.io/google-containers/fluentd-elasticsearch:v2.0.1
        env:
        - name: FLUENTD_ARGS
          value: --no-supervisor -q
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: config-volume
          mountPath: /etc/fluent/config.d
      terminationGracePeriodSeconds: 30
      volumes:
      - name: config-volume
        configMap:
          name: fluentd-es-config
---
# Fluentd ConfigMap，包含配置文件。
kind: ConfigMap
apiVersion: v1
data:
  forward.input.conf: |-
    # 采用 TCP 发送的消息
    <source>
      type forward
    </source>
  output.conf: |-
    <match **>
       type elasticsearch
       log_level info
       include_tag_key true
       host elasticsearch
       port 9200
       logstash_format true
       # 设置 chunk limits.
       buffer_chunk_limit 2M
       buffer_queue_limit 8
       flush_interval 5s
       # 重试间隔绝对不要超过 5 分钟。
       max_retry_wait 30
       # 禁用重试次数限制（永远重试）。
       disable_retry_limit
       # 使用多线程。
       num_threads 2
    </match>
metadata:
  name: fluentd-es-config
  namespace: logging
---
# Kibana Service
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
spec:
  ports:
  - port: 5601
    protocol: TCP
    targetPort: ui
  selector:
    app: kibana
---
# Kibana Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana-oss:6.1.1
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: ELASTICSEARCH_URL
            value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
---
{{< /text >}}

创建资源：

{{< text bash >}}
$ kubectl apply -f logging-stack.yaml
namespace "logging" created
service "elasticsearch" created
deployment "elasticsearch" created
service "fluentd-es" created
deployment "fluentd-es" created
configmap "fluentd-es-config" created
service "kibana" created
deployment "kibana" created
{{< /text >}}

## 配置 Istio

现在已经有了一个运行的 Fluentd 守护程序，接下来使用新的日志类型配置 Istio，并将日志发送到监听的守护程序。创建一个新的用于保存日志流配置 YAML 文件，Istio 将自动生成和收集这些日志流。

将下列内容保存为 `fluentd-istio.yaml`：

{{< text yaml >}}
# logentry 实例配置
apiVersion: "config.istio.io/v1alpha2"
kind: logentry
metadata:
  name: newlog
  namespace: istio-system
spec:
  severity: '"info"'
  timestamp: request.time
  variables:
    source: source.labels["app"] | source.workload.name | "unknown"
    user: source.user | "unknown"
    destination: destination.labels["app"] | destination.workload.name | "unknown"
    responseCode: response.code | 0
    responseSize: response.size | 0
    latency: response.duration | "0ms"
  monitored_resource_type: '"UNSPECIFIED"'
---
# Fluentd handler 配置
apiVersion: "config.istio.io/v1alpha2"
kind: fluentd
metadata:
  name: handler
  namespace: istio-system
spec:
  address: "fluentd-es.logging:24224"
---
# 将 logentry 示例发送到 Fluentd handler 的 rule
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: newlogtofluentd
  namespace: istio-system
spec:
  match: "true" # 匹配所有请求
  actions:
   - handler: handler.fluentd
     instances:
     - newlog.logentry
---
{{< /text >}}

创建资源：

{{< text bash >}}
$ kubectl apply -f fluentd-istio.yaml
Created config logentry/istio-system/newlog at revision 22374
Created config fluentd/istio-system/handler at revision 22375
Created config rule/istio-system/newlogtofluentd at revision 22376
{{< /text >}}

请注意，handler 配置中的 `address: "fluentd-es.logging:24224"` 一行指向我们在示例工具栈中配置的 Fluentd 守护程序。

## 查看新的日志

1. 发送流量到示例应用程序。

    对于 [Bookinfo](/zh/docs/examples/bookinfo/) 示例，请在您的浏览器中访问 `http://$GATEWAY_URL/productpage`，或执行以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 在 Kubernetes 环境中，通过以下命令为 Kibana 设置端口转发：

    {{< text bash >}}
    $ kubectl -n logging port-forward $(kubectl -n logging get pod -l app=kibana -o jsonpath='{.items[0].metadata.name}') 5601:5601 &
    {{< /text >}}

    保持命令运行。在结束对 Kibana UI 的访问时，使用 Ctrl-C 退出。

1. 导航到 [Kibana UI](http://localhost:5601/) 并点击右上角的 "Set up index patterns"。

1. 使用 `*` 作为索引模式，并点击 "Next step"。

1. 选择 `@timestamp` 作为 Time Filter 字段名称，并点击 "Create index pattern"。

1. 现在点击左侧目录中的 "Discover"，开始探索生成的日志。

## 清理

* 删除新的遥测配置：

    {{< text bash >}}
    $ kubectl delete -f fluentd-istio.yaml
    {{< /text >}}

* 删除示例 Fluentd、Elasticsearch、Kibana 工具栈：

    {{< text bash >}}
    $ kubectl delete -f logging-stack.yaml
    {{< /text >}}

* 删除任何可能还在运行的  `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)中的指示停止应用程序。
