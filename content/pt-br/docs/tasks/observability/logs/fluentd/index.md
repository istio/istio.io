---
title: Logging with Fluentd
description: This task shows you how to configure Istio to log to a Fluentd daemon.
weight: 90
keywords: [telemetry,logging]
aliases:
    - /docs/tasks/telemetry/fluentd/
    - /docs/tasks/telemetry/logs/fluentd/
---

This task shows how to configure Istio to create custom log entries
and send them to a [Fluentd](https://www.fluentd.org/) daemon. Fluentd
is an open source log collector that supports many [data
outputs](https://www.fluentd.org/dataoutputs) and has a pluggable
architecture. One popular logging backend is
[Elasticsearch](https://www.elastic.co/products/elasticsearch), and
[Kibana](https://www.elastic.co/products/kibana) as a viewer. At the
end of this task, a new log stream will be enabled sending logs to an
example Fluentd / Elasticsearch / Kibana stack.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup/) in your cluster and deploy an
  application. This task assumes that Mixer is setup in a default configuration
  (`--configDefaultNamespace=istio-system`). If you use a different
  value, update the configuration and commands in this task to match the value.

## Setup Fluentd

In your cluster, you may already have a Fluentd daemon set running,
such the add-on described
[here](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)
and
[here](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch),
or something specific to your cluster provider. This is likely
configured to send logs to an Elasticsearch system or logging
provider.

You may use these Fluentd daemons, or any other Fluentd daemon you
have set up, as long as they are listening for forwarded logs, and
Istio's Mixer is able to connect to them. In order for Mixer to
connect to a running Fluentd daemon, you may need to add a
[service](https://kubernetes.io/docs/concepts/services-networking/service/)
for Fluentd. The Fluentd configuration to listen for forwarded logs
is:

{{< text xml >}}
<source>
  type forward
</source>
{{< /text >}}

The full details of connecting Mixer to all possible Fluentd
configurations is beyond the scope of this task.

### Example Fluentd, Elasticsearch, Kibana Stack

For the purposes of this task, you may deploy the example stack
provided. This stack includes Fluentd, Elasticsearch, and Kibana in a
non production-ready set of
[Services](https://kubernetes.io/docs/concepts/services-networking/service/)
and
[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
all in a new
[Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
called `logging`.

Save the following as `logging-stack.yaml`.

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

Create the resources:

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

## Configure Istio

Now that there is a running Fluentd daemon, configure Istio with a new
log type, and send those logs to the listening daemon. Apply a
YAML file with configuration for the log stream that
Istio will generate and collect automatically:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/telemetry/fluentd-istio.yaml@
{{< /text >}}

{{< warning >}}
If you use Istio 1.1.2 or prior, please use the following configuration instead:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/telemetry/fluentd-istio-crd.yaml@
{{< /text >}}

{{< /warning >}}

Notice that the `address: "fluentd-es.logging:24224"` line in the
handler configuration is pointing to the Fluentd daemon we setup in the
example stack.

## View the new logs

1.  Send traffic to the sample application.

    For the
    [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port)
    sample, visit `http://$GATEWAY_URL/productpage` in your web browser
    or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  In a Kubernetes environment, setup port-forwarding for Kibana by
    executing the following command:

    {{< text bash >}}
    $ kubectl -n logging port-forward $(kubectl -n logging get pod -l app=kibana -o jsonpath='{.items[0].metadata.name}') 5601:5601 &
    {{< /text >}}

    Leave the command running. Press Ctrl-C to exit when done accessing the Kibana UI.

1. Navigate to the [Kibana UI](http://localhost:5601/) and click the "Set up index patterns" in the top right.

1. Use `*` as the index pattern, and click "Next step.".

1. Select `@timestamp` as the Time Filter field name, and click "Create index pattern."

1. Now click "Discover" on the left menu, and start exploring the logs generated

## Cleanup

*   Remove the new telemetry configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/fluentd-istio.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/fluentd-istio-crd.yaml@
    {{< /text >}}

*   Remove the example Fluentd, Elasticsearch, Kibana stack:

    {{< text bash >}}
    $ kubectl delete -f logging-stack.yaml
    {{< /text >}}

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.
