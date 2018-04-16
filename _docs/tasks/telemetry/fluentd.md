---
title: Logging with Fluentd

overview: This task shows you how to configure Istio to log to a Fluentd daemon

order: 60

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to configure Istio to create custom log entries
and send them to a [Fluentd](https://www.fluentd.org/) daemon. Fluentd
is an open source log collector that supports many [data
outputs](https://www.fluentd.org/dataoutputs) and has a pluggable
architecture. One popular logging backend is
[Elasticsearch](https://www.elastic.co/products/elasticsearch), and
[Kibana](https://www.elastic.co/products/kibana) as a viewer. At the
end of this task, a new log stream will be enabled sending logs to an
example Fluentd / Elasticsearch / Kibana stack.

The [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio]({{home}}/docs/setup/) in your cluster and deploy an
  application. This task assumes that Mixer is setup in a default configuration
  (`--configDefaultNamespace=istio-system`). If you use a different
  value, update the configuration and commands in this task to match the value.

## Setup Fluentd

In your cluster, you may already have a Fluentd DaemonSet running,
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

```xml
<source>
  type forward
</source>
```

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

```yaml
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
```

Create the resources:

```bash
kubectl apply -f logging-stack.yaml
```

You should see the following:

```xxx
namespace "logging" created
service "elasticsearch" created
deployment "elasticsearch" created
service "fluentd-es" created
deployment "fluentd-es" created
configmap "fluentd-es-config" created
service "kibana" created
deployment "kibana" created
```

## Configure Istio

Now that there is a running Fluentd daemon, configure Istio with a new
log type, and send those logs to the listening daemon. Create a new
YAML file to hold configuration for the log stream that
Istio will generate and collect automatically.

Save the following as `fluentd-istio.yaml`:

```yaml
# Configuration for logentry instances
apiVersion: "config.istio.io/v1alpha2"
kind: logentry
metadata:
  name: newlog
  namespace: istio-system
spec:
  severity: '"info"'
  timestamp: request.time
  variables:
    source: source.labels["app"] | source.service | "unknown"
    user: source.user | "unknown"
    destination: destination.labels["app"] | destination.service | "unknown"
    responseCode: response.code | 0
    responseSize: response.size | 0
    latency: response.duration | "0ms"
  monitored_resource_type: '"UNSPECIFIED"'
---
# Configuration for a fluentd handler
apiVersion: "config.istio.io/v1alpha2"
kind: fluentd
metadata:
  name: handler
  namespace: istio-system
spec:
  address: "fluentd-es.logging:24224"
---
# Rule to send logentry instances to the fluentd handler
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: newlogtofluentd
  namespace: istio-system
spec:
  match: "true" # match for all requests
  actions:
   - handler: handler.fluentd
     instances:
     - newlog.logentry
---
```

Create the resources:

```bash
istioctl create -f fluentd-istio.yaml
```

The expected output is similar to:
```
Created config logentry/istio-system/newlog at revision 22374
Created config fluentd/istio-system/handler at revision 22375
Created config rule/istio-system/newlogtofluentd at revision 22376
```

Notice that the `address: "fluentd-es.logging:24224"` line in the
handler config is pointing to the Fluentd daemon we setup in the
example stack.

## View the new logs

1. Send traffic to the sample application.

   For the
   [Bookinfo]({{home}}/docs/guides/bookinfo.html#determining-the-ingress-ip-and-port)
   sample, visit `http://$GATEWAY_URL/productpage` in your web browser
   or issue the following command:

   ```bash
   curl http://$GATEWAY_URL/productpage
   ```

1. In a Kubernetes environment, setup port-forwarding for Kibana by
   executing the following command:

   ```bash
   kubectl -n logging port-forward $(kubectl -n logging get pod -l app=kibana -o jsonpath='{.items[0].metadata.name}') 5601:5601
   ```

    Leave the command running. Press Ctrl-C to exit when done accessing the Kibana UI.

1. Navigate to the [Kibana UI](http://localhost:5601/) and click the "Set up index patterns" in the top right.

1. Use `*` as the index pattern, and click "Next step.".

1. Select `@timestamp` as the Time Filter field name, and click "Create index pattern."

1. Now click "Discover" on the left menu, and start exploring the logs generated

## Cleanup

* Remove the new telemetry configuration:

  ```bash
  istioctl delete -f fluentd-istio.yaml
  ```

* Remove the example Fluentd, Elasticsearch, Kibana stack:

  ```bash
  kubectl delete -f logging-stack.yaml
  ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## What's next

* [Collecting Metrics and Logs]({{home}}/docs/tasks/telemetry/metrics-logs.html) for a detailed
  explanation of the log configurations.

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html)
  and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).

* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).
