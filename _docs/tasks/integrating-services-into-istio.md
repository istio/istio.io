---
title: Integrating Services into the Mesh
overview: This task shows you how to integrate your applications with the Istio service mesh.

order: 20

layout: docs
type: markdown
---

This task shows how to integrate applications on Kubernetes with
Istio. You'll learn how to inject the Envoy sidecar into deployments
using [istioctl kube-inject](/docs/reference/istioctl/istioctl_kube-inject.html)

## Before you begin

This task assumes you have deployed Istio on Kubernetes.
If you have not done so, please first complete the
[Installation Steps](/docs/tasks/installing-istio.html).

## Injecting Envoy sidecar into a deployment

Example deployment and service to demonstrate this task. Save this as
echo.yaml.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo
  labels:
    app: echo
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: http
  selector:
    app: echo
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: gcr.io/google_containers/echoserver:1.4
        ports:
        - containerPort: 8080
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: busybox
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - name: busybox
        image: radial/busyboxplus:curl
```

[Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
are required for properly functioning Istio service. Service ports
must be named and these names must begin with _http_ or _grpc_ prefix
to take advantage of Istio's L7 routing features, e.g. `name: httpFoo`
is good. Services with non-named ports or with ports that do not have
a _http_ or _grpc_ prefix will be routed as L4 traffic.

Submit a YAML resource to API server with injected Envoy sidecar. Any
one of the following methods will work.

```bash
kubectl apply -f <(istioctl kube-inject -f echo.yaml)
```

Make a request from the client (busybox) to the server (echo).

```bash
CLIENT=$(kubectl get pod -l app=busybox -o jsonpath='{.items[0].metadata.name}')
SERVER=$(kubectl get pod -l app=echo -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it ${CLIENT} -c echo -- curl echo:80 | grep x-request-id
x-request-id=a641eff7-eb82-4a4f-b67b-53cd3a03c399
```

Verify traffic is intercepted by the Envoy sidecar. Compare
`x-request-id` in the HTTP response with the sidecar's access
logs. `x-request-id` is random. The IP in the inbound request logs is
the echo pod's IP.

Outbound request on client pod's proxy.

```
kubectl logs ${CLIENT} proxy | grep a641eff7-eb82-4a4f-b67b-53cd3a03c399
[2017-05-01T22:08:39.310Z] "GET / HTTP/1.1" 200 - 0 398 2 0 "-" "curl/7.47.0" "a641eff7-eb82-4a4f-b67b-53cd3a03c399" "echo" "127.0.0.1:8080"
```

Inbound request on server pod's proxy.

```
kubectl logs ${SERVER} proxy | grep a641eff7-eb82-4a4f-b67b-53cd3a03c399
[2017-05-01T22:08:39.310Z] "GET / HTTP/1.1" 200 - 0 398 3 3 "-" "curl/7.47.0" "a641eff7-eb82-4a4f-b67b-53cd3a03c399" "echo" "10.4.180.7:8080"
```


The Envoy sidecar does _not_ intercept container-to-container traffic
within the same pod when traffic is routed via localhost. This is by
design.

```bash
kubectl exec -it ${SERVER} -c echo -- curl localhost:8080 | grep x-request-id
```

## Understanding what happened

`istioctl kube-inject` injects additional containers into YAML
resource on the client _before_ submitting to the Kubernetes API
server. This will eventually be replaced by server-side injection via
admission controller. Use `kubectl get deployment echo -o yaml` to
inspect the modified deployment and look for the following:

* A proxy container which includes the Envoy proxy and agent to manage
  local proxy configuration.

* An [init-container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
  to program [iptables](https://en.wikipedia.org/wiki/Iptables).

The proxy container runs with a specific UID so that the iptables can
differentiate outbound traffic from the proxy itself from the
applications which are redirected to proxy.

```yaml
- args:
    - proxy
    - sidecar
    - "-v"
    - "2"
  env:
    -
      name: POD_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.name
    -
      name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.namespace
    -
      name: POD_IP
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: status.podIP
  image: "docker.io/istio/proxy:<...tag... >"
  imagePullPolicy: Always
  name: proxy
  securityContext:
    runAsUser: 1337

```

iptables is used to transparently redirect all inbound and outbound
traffic to the proxy. An init-container is used for two reasons:

1. iptables requires
[NET_CAP_ADMIN](http://man7.org/linux/man-pages/man7/capabilities.7.html).

2. The sidecar iptable rules are fixed and don't need to be updated
after pod creation. The proxy container is responsible for dynamically
routing traffic.

```json
{
  "name":"init",
  "image":"docker.io/istio/init:<..tag...>",
  "args":[ "-p", "15001", "-u", "1337" ],
  "imagePullPolicy":"Always",
  "securityContext":{
    "capabilities":{
      "add":[
        "NET_ADMIN"
      ]
    }
  }
},
```

## What's next

* Review full documentation for [istioctl kube-inject](/docs/reference/istioctl/istioctl_kube-inject.html)

* See the [bookinfo sample](/docs/samples/bookinfo.html) for a more complete example of applications integrated on Kubernetes with Istio.
