---
title: Mirroring
description: This task demonstrates the traffic mirroring/shadowing capabilities of Istio.
weight: 60
keywords: [traffic-management,mirroring]
---

This task demonstrates the traffic mirroring capabilities of Istio.

Traffic mirroring, also called shadowing, is a powerful concept that allows
feature teams to bring changes to production with as little risk as possible.
Mirroring sends a copy of live traffic to a mirrored service. The mirrored
traffic happens out of band of the critical request path for the primary service.

In this task, you will first force all traffic to `v1` of a test service. Then,
you will apply a rule to mirror a portion of traffic to `v2`.

## Before you begin

* Set up Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start by deploying two versions of the [httpbin]({{< github_tree >}}/samples/httpbin) service that have access logging enabled:

    **httpbin-v1:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin-v1
    spec:
      replicas: 1
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
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin-v2
    spec:
      replicas: 1
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
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: tutum/curl
            command: ["/bin/sleep","infinity"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## Creating a default routing policy

By default Kubernetes load balances across both versions of the `httpbin` service.
In this step, you will change that behavior so that all traffic goes to `v1`.

1.  Create a default route rule to route all traffic to `v1` of the service:

    {{< warning >}}
    If you installed/configured Istio with mutual TLS Authentication enabled, you must add a TLS traffic policy `mode: ISTIO_MUTUAL` to the `DestinationRule` before applying it. Otherwise requests will generate 503 errors as described [here](/help/ops/traffic-management/troubleshooting/#503-errors-after-setting-destination-rule).
    {{< /warning >}}

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

    Now all traffic goes to the `httpbin:v1` service.

1. Send some traffic to the service:

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "eca3d7ed8f2e6a0a",
        "X-B3-Traceid": "eca3d7ed8f2e6a0a",
        "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
      }
    }
    {{< /text >}}

1. Check the logs for `v1` and `v2` of the `httpbin` pods. You should see access
log entries for `v1` and none for `v2`:

    {{< text bash >}}
    $ export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V2_POD -c httpbin
    <none>
    {{< /text >}}

## Mirroring traffic to v2

1.  Change the route rule to mirror traffic to v2:

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
    EOF
    {{< /text >}}

    This route rule sends 100% of the traffic to `v1`. The last stanza specifies
    that you want to mirror to the `httpbin:v2` service. When traffic gets mirrored,
    the requests are sent to the mirrored service with their Host/Authority headers
    appended with `-shadow`. For example, `cluster-1` becomes `cluster-1-shadow`.

    Also, it is important to note that these requests are mirrored as "fire and
    forget", which means that the responses are discarded.

1. Send in traffic:

    {{< text bash >}}
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {{< /text >}}

    Now, you should see access logging for both `v1` and `v2`. The access logs
    created in `v2` are the mirrored requests that are actually going to `v1`.

    {{< text bash >}}
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs -f $V2_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

1. If you want to examine traffic internals, run the following commands on another console:

    {{< text bash >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ export V1_POD_IP=$(kubectl get pod -l app=httpbin -l version=v1 -o jsonpath={.items..status.podIP})
    $ export V2_POD_IP=$(kubectl get pod -l app=httpbin -l version=v2 -o jsonpath={.items..status.podIP})
    $ kubectl exec -it $SLEEP_POD -c istio-proxy -- sudo tcpdump -A -s 0 host $V1_POD_IP or host $V2_POD_IP
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
    05:47:50.159513 IP sleep-7b9f8bfcd-2djx5.38836 > 10-233-75-11.httpbin.default.svc.cluster.local.80: Flags [P.], seq 4039989036:4039989832, ack 3139734980, win 254, options [nop,nop,TS val 77427918 ecr 76730809], length 796: HTTP: GET /headers HTTP/1.1
    E..P2.X.X.X.
    .K.
    .K....P..W,.$.......+.....
    ..t.....GET /headers HTTP/1.1
    host: httpbin:8000
    user-agent: curl/7.35.0
    accept: */*
    x-forwarded-proto: http
    x-request-id: 571c0fd6-98d4-4c93-af79-6a2fe2945847
    x-envoy-decorator-operation: httpbin.default.svc.cluster.local:8000/*
    x-b3-traceid: 82f3e0a76dcebca2
    x-b3-spanid: 82f3e0a76dcebca2
    x-b3-sampled: 0
    x-istio-attributes: Cj8KGGRlc3RpbmF0aW9uLnNlcnZpY2UuaG9zdBIjEiFodHRwYmluLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwKPQoXZGVzdGluYXRpb24uc2VydmljZS51aWQSIhIgaXN0aW86Ly9kZWZhdWx0L3NlcnZpY2VzL2h0dHBiaW4KKgodZGVzdGluYXRpb24uc2VydmljZS5uYW1lc3BhY2USCRIHZGVmYXVsdAolChhkZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWUSCRIHaHR0cGJpbgo6Cgpzb3VyY2UudWlkEiwSKmt1YmVybmV0ZXM6Ly9zbGVlcC03YjlmOGJmY2QtMmRqeDUuZGVmYXVsdAo6ChNkZXN0aW5hdGlvbi5zZXJ2aWNlEiMSIWh0dHBiaW4uZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
    content-length: 0


    05:47:50.159609 IP sleep-7b9f8bfcd-2djx5.49560 > 10-233-71-7.httpbin.default.svc.cluster.local.80: Flags [P.], seq 296287713:296288571, ack 4029574162, win 254, options [nop,nop,TS val 77427918 ecr 76732809], length 858: HTTP: GET /headers HTTP/1.1
    E.....X.X...
    .K.
    .G....P......l......e.....
    ..t.....GET /headers HTTP/1.1
    host: httpbin-shadow:8000
    user-agent: curl/7.35.0
    accept: */*
    x-forwarded-proto: http
    x-request-id: 571c0fd6-98d4-4c93-af79-6a2fe2945847
    x-envoy-decorator-operation: httpbin.default.svc.cluster.local:8000/*
    x-b3-traceid: 82f3e0a76dcebca2
    x-b3-spanid: 82f3e0a76dcebca2
    x-b3-sampled: 0
    x-istio-attributes: Cj8KGGRlc3RpbmF0aW9uLnNlcnZpY2UuaG9zdBIjEiFodHRwYmluLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwKPQoXZGVzdGluYXRpb24uc2VydmljZS51aWQSIhIgaXN0aW86Ly9kZWZhdWx0L3NlcnZpY2VzL2h0dHBiaW4KKgodZGVzdGluYXRpb24uc2VydmljZS5uYW1lc3BhY2USCRIHZGVmYXVsdAolChhkZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWUSCRIHaHR0cGJpbgo6Cgpzb3VyY2UudWlkEiwSKmt1YmVybmV0ZXM6Ly9zbGVlcC03YjlmOGJmY2QtMmRqeDUuZGVmYXVsdAo6ChNkZXN0aW5hdGlvbi5zZXJ2aWNlEiMSIWh0dHBiaW4uZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
    x-envoy-internal: true
    x-forwarded-for: 10.233.75.12
    content-length: 0


    05:47:50.166734 IP 10-233-75-11.httpbin.default.svc.cluster.local.80 > sleep-7b9f8bfcd-2djx5.38836: Flags [P.], seq 1:472, ack 796, win 276, options [nop,nop,TS val 77427925 ecr 77427918], length 471: HTTP: HTTP/1.1 200 OK
    E....3X.?...
    .K.
    .K..P...$....ZH...........
    ..t...t.HTTP/1.1 200 OK
    server: envoy
    date: Fri, 15 Feb 2019 05:47:50 GMT
    content-type: application/json
    content-length: 241
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3

    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "82f3e0a76dcebca2",
        "X-B3-Traceid": "82f3e0a76dcebca2"
      }
    }

    05:47:50.166789 IP sleep-7b9f8bfcd-2djx5.38836 > 10-233-75-11.httpbin.default.svc.cluster.local.80: Flags [.], ack 472, win 262, options [nop,nop,TS val 77427925 ecr 77427925], length 0
    E..42.X.X.\.
    .K.
    .K....P..ZH.$.............
    ..t...t.
    05:47:50.167234 IP 10-233-71-7.httpbin.default.svc.cluster.local.80 > sleep-7b9f8bfcd-2djx5.49560: Flags [P.], seq 1:512, ack 858, win 280, options [nop,nop,TS val 77429926 ecr 77427918], length 511: HTTP: HTTP/1.1 200 OK
    E..3..X.>...
    .G.
    .K..P....l....;...........
    ..|...t.HTTP/1.1 200 OK
    server: envoy
    date: Fri, 15 Feb 2019 05:47:49 GMT
    content-type: application/json
    content-length: 281
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3

    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin-shadow:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "82f3e0a76dcebca2",
        "X-B3-Traceid": "82f3e0a76dcebca2",
        "X-Envoy-Internal": "true"
      }
    }

    05:47:50.167253 IP sleep-7b9f8bfcd-2djx5.49560 > 10-233-71-7.httpbin.default.svc.cluster.local.80: Flags [.], ack 512, win 262, options [nop,nop,TS val 77427926 ecr 77429926], length 0
    E..4..X.X...
    .K.
    .G....P...;..n............
    ..t...|.
    {{< /text >}}

    You can see request and response contents of the traffic.

## Cleaning up

1.  Remove the rules:

    {{< text bash >}}
    $ kubectl delete virtualservice httpbin
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1.  Shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service and client:

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    {{< /text >}}
