---
title: Health Checking of Istio Services
description: Shows how to do health checking for Istio services.
weight: 50
aliases:
  - /docs/tasks/traffic-management/app-health-check/
  - /docs/ops/security/health-checks-and-mtls/
  - /help/ops/setup/app-health-check
  - /help/ops/app-health-check
  - /docs/ops/app-health-check
  - /docs/ops/setup/app-health-check
keywords: [security,health-check]
owner: istio/wg-user-experience-maintainers
test: yes
---

[Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
describes several ways to configure liveness and readiness probes:

1. [Command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
1. [HTTP request](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request)
1. [TCP probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe)
1. [gRPC probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe)

The command approach works with no changes required, but HTTP requests, TCP probes, and gRPC probes require Istio to make changes to the pod configuration.

The health check requests to the `liveness-http` service are sent by Kubelet.
This becomes a problem when mutual TLS is enabled, because the Kubelet does not have an Istio issued certificate.
Therefore the health check requests will fail.

TCP probe checks need special handling, because Istio redirects all incoming traffic into the sidecar, and so all TCP ports appear open. The Kubelet simply checks if some process is listening on the specified port, and so the probe will always succeed as long as the sidecar is running.

Istio solves both these problems by rewriting the application `PodSpec` readiness/liveness probe,
so that the probe request is sent to the [sidecar agent](/docs/reference/commands/pilot-agent/).

## Liveness probe rewrite example

To demonstrate how the readiness/liveness probe is rewritten at the application `PodSpec` level, let us use the [liveness-http-same-port sample]({{< github_file >}}/samples/health-check/liveness-http-same-port.yaml).

First create and label a namespace for the example:

{{< text bash >}}
$ kubectl create namespace istio-io-health-rewrite
$ kubectl label namespace istio-io-health-rewrite istio-injection=enabled
{{< /text >}}

And deploy the sample application:

{{< text bash yaml >}}
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
  namespace: istio-io-health-rewrite
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

Once deployed, you can inspect the pod's application container to see the changed path:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o json | jq '.spec.containers[0].livenessProbe.httpGet'
{
  "path": "/app-health/liveness-http/livez",
  "port": 15020,
  "scheme": "HTTP"
}
{{< /text >}}

The original `livenessProbe` path is now mapped against the new path in the sidecar container environment variable `ISTIO_KUBE_APP_PROBERS`:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o=jsonpath="{.spec.containers[1].env[?(@.name=='ISTIO_KUBE_APP_PROBERS')]}"
{
  "name":"ISTIO_KUBE_APP_PROBERS",
  "value":"{\"/app-health/liveness-http/livez\":{\"httpGet\":{\"path\":\"/foo\",\"port\":8001,\"scheme\":\"HTTP\"},\"timeoutSeconds\":1}}"
}
{{< /text >}}

For HTTP and gRPC requests, the sidecar agent redirects the request to the application and strips the response body, only returning the response code. For TCP probes, the sidecar agent will then do the port check while avoiding the traffic redirection.

The rewriting of problematic probes is enabled by default in all built-in Istio
[configuration profiles](/docs/setup/additional-setup/config-profiles/) but can be disabled as described below.

## Liveness and readiness probes using the command approach

Istio provides a [liveness sample]({{< github_file >}}/samples/health-check/liveness-command.yaml) that
implements this approach. To demonstrate it working with mutual TLS enabled,
first create a namespace for the example:

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

To configure strict mutual TLS, run:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Next, change directory to the root of the Istio installation and run the following command to deploy the sample service:

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

To confirm that the liveness probes are working, check the status of the sample pod to verify that it is running.

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Liveness and readiness probes using the HTTP, TCP, and gRPC approach {#liveness-and-readiness-probes-using-the-http-request-approach}

As stated previously, Istio uses probe rewrite to implement HTTP, TCP, and gRPC probes by default. You can disable this
feature either for specific pods, or globally.

### Disable the probe rewrite for a pod {#disable-the-http-probe-rewrite-for-a-pod}

You can [annotate the pod](/docs/reference/config/annotations/) with `sidecar.istio.io/rewriteAppHTTPProbers: "false"`
to disable the probe rewrite option. Make sure you add the annotation to the
[pod resource](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) because it will be ignored
anywhere else (for example, on an enclosing deployment resource).

{{< tabset category-name="disable-probe-rewrite" >}}

{{< tab name="HTTP Probe" category-value="http-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="gRPC Probe" category-value="grpc-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-grpc
spec:
  selector:
    matchLabels:
      app: liveness-grpc
      version: v1
  template:
    metadata:
      labels:
        app: liveness-grpc
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: etcd
        image: registry.k8s.io/etcd:3.5.1-0
        command: ["--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
        ports:
        - containerPort: 2379
        livenessProbe:
          grpc:
            port: 2379
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

This approach allows you to disable the health check probe rewrite gradually on individual deployments,
without reinstalling Istio.

### Disable the probe rewrite globally

[Install Istio](/docs/setup/install/istioctl/) using `--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=false`
to disable the probe rewrite globally. **Alternatively**, update the configuration map for the Istio sidecar injector:

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
{{< /text >}}

## Cleanup

Remove the namespaces used for the examples:

{{< text bash >}}
$ kubectl delete ns istio-io-health istio-io-health-rewrite
{{< /text >}}
