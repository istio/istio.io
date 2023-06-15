---
title: Mirroring
description: This task demonstrates the traffic mirroring/shadowing capabilities of Istio.
weight: 60
keywords: [traffic-management,mirroring]
owner: istio/wg-networking-maintainers
test: yes
---

This task demonstrates the traffic mirroring capabilities of Istio.

Traffic mirroring, also called shadowing, is a powerful concept that allows
feature teams to bring changes to production with as little risk as possible.
Mirroring sends a copy of live traffic to a mirrored service. The mirrored
traffic happens out of band of the critical request path for the primary service.

In this task, you will first force all traffic to `v1` of a test service. Then,
you will apply a rule to mirror a portion of traffic to `v2`.

{{< boilerplate gateway-api-gamma-support >}}

## Before you begin

* Set up Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start by deploying two versions of the [httpbin]({{< github_tree >}}/samples/httpbin) service that have access logging enabled:

    **httpbin-v1:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: httpbin-v1
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: httpbin
          version: v1
      template:
        metadata:
          labels:
            app: httpbin
            version: v1
        spec:
          containers:
          - image: docker.io/kennethreitz/httpbin
            imagePullPolicy: IfNotPresent
            name: httpbin
            command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
            ports:
            - containerPort: 80
    EOF
    {{< /text >}}

    **httpbin-v2:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: httpbin-v2
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: httpbin
          version: v2
      template:
        metadata:
          labels:
            app: httpbin
            version: v2
        spec:
          containers:
          - image: docker.io/kennethreitz/httpbin
            imagePullPolicy: IfNotPresent
            name: httpbin
            command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
            ports:
            - containerPort: 80
    EOF
    {{< /text >}}

    **httpbin Kubernetes service:**

    {{< text bash >}}
    $ kubectl create -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - name: http
        port: 8000
        targetPort: 80
      selector:
        app: httpbin
    EOF
    {{< /text >}}

*   Start the `sleep` service so you can use `curl` to provide load:

    **sleep service:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: sleep
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: curlimages/curl
            command: ["/bin/sleep","3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## Creating a default routing policy

By default Kubernetes load balances across both versions of the `httpbin` service.
In this step, you will change that behavior so that all traffic goes to `v1`.

1.  Create a default route rule to route all traffic to `v1` of the service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-v1
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: httpbin
    version: v1
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-v2
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: httpbin
    version: v2
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - kind: Service
    name: httpbin
    port: 8000
  rules:
  - backendRefs:
    - name: httpbin-v1
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Now, with all traffic directed to `httpbin:v1`, send a request to the service:

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec "${SLEEP_POD}" -c sleep -- curl -sS http://httpbin:8000/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Parentspanid": "57784f8bff90ae0b",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "3289ae7257c3f159",
        "X-B3-Traceid": "b56eebd279a76f0b57784f8bff90ae0b",
        "X-Envoy-Attempt-Count": "1",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=20afebed6da091c850264cc751b8c9306abac02993f80bdb76282237422bd098;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      }
    }
    {{< /text >}}

3) Check the logs for `v1` and `v2` of the `httpbin` pods. You should see access
log entries for `v1` and none for `v2`:

    {{< text bash >}}
    $ export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
    $ kubectl logs "$V1_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
    $ kubectl logs "$V2_POD" -c httpbin
    <none>
    {{< /text >}}

## Mirroring traffic to v2

1.  Change the route rule to mirror traffic to v2:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
    mirror:
      host: httpbin
      subset: v2
    mirrorPercentage:
      value: 100.0
EOF
{{< /text >}}

This route rule sends 100% of the traffic to `v1`. The last stanza specifies
that you want to mirror (i.e., also send) 100% of the same traffic to the
`httpbin:v2` service. When traffic gets mirrored,
the requests are sent to the mirrored service with their Host/Authority headers
appended with `-shadow`. For example, `cluster-1` becomes `cluster-1-shadow`.

Also, it is important to note that these requests are mirrored as "fire and
forget", which means that the responses are discarded.

You can use the `value` field under the `mirrorPercentage` field to mirror a fraction of the traffic,
instead of mirroring all requests. If this field is absent, all traffic will be mirrored.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - kind: Service
    name: httpbin
    port: 8000
  rules:
  - filters:
    - type: RequestMirror
      requestMirror:
        backendRef:
          name: httpbin-v2
          port: 80
    backendRefs:
    - name: httpbin-v1
      port: 80
EOF
{{< /text >}}

This route rule sends 100% of the traffic to `v1`. The `RequestMirror` filter
specifies that you want to mirror (i.e., also send) 100% of the same traffic to the
`httpbin:v2` service. When traffic gets mirrored,
the requests are sent to the mirrored service with their Host/Authority headers
appended with `-shadow`. For example, `cluster-1` becomes `cluster-1-shadow`.

Also, it is important to note that these requests are mirrored as "fire and
forget", which means that the responses are discarded.

{{< /tab >}}

{{< /tabset >}}

2) Send in traffic:

    {{< text bash >}}
    $ kubectl exec "${SLEEP_POD}" -c sleep -- curl -sS http://httpbin:8000/headers
    {{< /text >}}

    Now, you should see access logging for both `v1` and `v2`. The access logs
    created in `v2` are the mirrored requests that are actually going to `v1`.

    {{< text bash >}}
    $ kubectl logs "$V1_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs "$V2_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## Cleaning up

1.  Remove the rules:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete virtualservice httpbin
$ kubectl delete destinationrule httpbin
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute httpbin
$ kubectl delete svc httpbin-v1 httpbin-v2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service and client:

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    {{< /text >}}
