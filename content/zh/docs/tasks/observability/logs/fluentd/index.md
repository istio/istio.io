---
title: 使用 Fluentd 进行日志收集
description: 此任务向您展示如何配置 Istio 以连接到 Fluentd 守护程序进行日志收集。
weight: 90
keywords: [telemetry,logging]
aliases:
    - /zh/docs/tasks/telemetry/fluentd/
    - /zh/docs/tasks/telemetry/logs/fluentd/
---

此任务展示如何配置 Istio 以创建自定义日志条目，并将其发送到 [Fluentd](https://www.fluentd.org/) 守护程序。
Fluentd 是一个开源的日志收集器，它支持许多[数据输出](https://www.fluentd.org/dataoutputs)并具有可插拔的体系结构。
一个常见的日志收集后端是 [Elasticsearch](https://www.elastic.co/products/elasticsearch)
和作为查看器的 [Kibana](https://www.elastic.co/products/kibana)。
接下来，将启用新的日志流，并把日志发送到示例堆栈 Fluentd / Elasticsearch / Kibana。

整个任务中，使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用程序。

## 开始之前{#before-you-begin}

* 在您的集群中[安装 Istio](/zh/docs/setup/) 并部署应用程序。
此任务假定已将 Mixer 设置为默认配置（`--configDefaultNamespace=istio-system`）。
如果使用其它值，此任务中请更新配置和命令以匹配该值。

## 安装 Fluentd{#setup-Fluentd}

在您的集群中，您可能已经在运行 Fluentd 守护程序，例如
[此处](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)和
[此处](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)所述的插件，
或其他定制化的相关程序。这可能配置为将日志发送到 Elasticsearch 系统或日志收集程序。

您可以使用这些 Fluentd 守护程序或任何其他已设置的 Fluentd 守护程序，只要它们正在侦听转发的日志，
并且 Istio 的 Mixer 可以连接到它们。为了使 Mixer 连接到正在运行的 Fluentd 守护程序，您可能需要为 Fluentd 添加 [service](https://kubernetes.io/docs/concepts/services-networking/service/)。
以下是侦听转发日志的 Fluentd 配置：

{{< text xml >}}
<source>
  type forward
</source>
{{< /text >}}

将 Mixer 连接到所有可能的 Fluentd 配置的完整细节不在此任务的讨论范围。

### 示例堆栈 Fluentd、Elasticsearch、Kibana{#example-Fluentd-Elasticsearch-Kibana-Stack}

出于此任务的目的，您可以部署提供的示例堆栈。该堆栈包括 Fluentd，Elasticsearch 和 Kibana，
它们位于非生产就绪的一组 [Services](https://kubernetes.io/docs/concepts/services-networking/service/) 和 [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 中，
其全部部署到一个名为 `logging` 的新 [Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) 中。

将以下内容另存为 `logging-stack.yaml`。

{{< text yaml >}}
# Logging Namespace. All below are a part of this namespace.
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.1.1
        name: elasticsearch
        resources:
          # need more cpu upon initialization, therefore burstable class
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    app: fluentd-es
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fluentd-es
  template:
    metadata:
      labels:
        app: fluentd-es
      annotations:
        sidecar.istio.io/inject: "false"
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
# Fluentd ConfigMap, contains config files.
kind: ConfigMap
apiVersion: v1
data:
  forward.input.conf: |-
    # Takes the messages sent over TCP
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
       # Set the chunk limits.
       buffer_chunk_limit 2M
       buffer_queue_limit 8
       flush_interval 5s
       # Never wait longer than 5 minutes between retries.
       max_retry_wait 30
       # Disable the limit on the number of retries (retry forever).
       disable_retry_limit
       # Use multiple threads for processing.
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
      annotations:
        sidecar.istio.io/inject: "false"
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

## 配置 Istio{#configure-Istio}

现在有了一个正在运行的 Fluentd 守护进程，用一个新的日志类型配置 Istio，并将这些日志发送到侦听守护进程。
应用配置 Istio 自动生成和收集日志流的 YAML 文件：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/telemetry/fluentd-istio.yaml@
{{< /text >}}

{{< warning >}}
如果您使用的是 Istio 1.1.2 或更早版本，请改用以下配置：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/telemetry/fluentd-istio-crd.yaml@
{{< /text >}}

{{< /warning >}}

请注意，处理程序配置中的 `address: "fluentd-es.logging:24224"` 指向我们在示例堆栈中设置的 Fluentd 守护程序。

## 查看新日志{#view-the-new-logs}

1.  将流量发送到示例应用程序。

    对于 [Bookinfo](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port) 示例，
    请在您的浏览器中访问 `http://$GATEWAY_URL/productpage`，或使用以下命令在命令行中发送请求：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  在 Kubernetes 环境中，通过执行以下命令来设置 Kibana 的端口转发：

    {{< text bash >}}
    $ kubectl -n logging port-forward $(kubectl -n logging get pod -l app=kibana -o jsonpath='{.items[0].metadata.name}') 5601:5601 &
    {{< /text >}}

    运行命令以可以访问 Kibana UI，当完成访问时，注意在命令行中用 Ctrl-C 退出。

1. 导航到 [Kibana UI](http://localhost:5601/)，然后单击右上角的“Set up index patterns”。

1. 使用 `*` 指标类型，然后单击“Next step”。

1. 选择 `@timestamp` 作为“时间过滤器”字段名称，然后单击“Create index pattern”。

1. 现在，单击左侧菜单上的“Discover”，然后开始浏览生成的日志。

## 清除{#cleanup}

*   删除新的遥测配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/fluentd-istio.yaml@
    {{< /text >}}

    如果您使用的是 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/fluentd-istio-crd.yaml@
    {{< /text >}}

*   删除示例堆栈 Fluentd、Elasticsearch 和 Kibana:

    {{< text bash >}}
    $ kubectl delete -f logging-stack.yaml
    {{< /text >}}

*   删除所有可能仍在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果您不打算继续探索后续任务，请参考 [Bookinfo 清除](/zh/docs/examples/bookinfo/#cleanup)以关闭应用程序。
