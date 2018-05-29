---
title: Mirroring
description: This task demonstrates the traffic shadowing/mirroring capabilities of Istio
weight: 60
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.6/docs/tasks/).

This task demonstrates the traffic shadowing/mirroring capabilities of Istio. Traffic mirroring is a powerful concept that allows feature teams to bring changes to production with as little risk as possible. Mirroring brings a copy of live traffic to a mirrored service and happens out of band of the critical request path for the primary service.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start two versions of the `httpbin` service that have access logging enabled

    httpbin-v1:

    ```bash
        cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
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
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
                ports:
                - containerPort: 8080
        EOF
    ```

    httpbin-v2:

    ```bash
        cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
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
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
                ports:
                - containerPort: 8080
        EOF
    ```

    httpbin Kubernetes service:

    ```bash
        cat <<EOF | kubectl create -f -
        apiVersion: v1
        kind: Service
        metadata:
          name: httpbin
          labels:
            app: httpbin
        spec:
          ports:
          - name: http
            port: 8080
          selector:
            app: httpbin
        EOF
    ```

*   Start the `sleep` service so we can use `curl` to provide load

    sleep service:

    ```bash
        cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
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
    ```

## Mirroring

Let's set up a scenario to demonstrate the traffic-mirroring capabilities of Istio. We have two versions of our `httpbin` service. By default Kubernetes will load balance across both versions of the service. We'll use Istio to force all traffic to v1 of the `httpbin` service.

### Creating default routing policy

1.  Create a default route rule to route all traffic to `v1` of our `httpbin` service:

    ```bash
        cat <<EOF | istioctl create -f -
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
    ```

    Now all traffic should go to `httpbin v1` service. Let's try sending in some traffic:

    ```command-output-as-json
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8080",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "eca3d7ed8f2e6a0a",
        "X-B3-Traceid": "eca3d7ed8f2e6a0a",
        "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
      }
    }
    ```

    If we check the logs for `v1` and `v2` of our `httpbin` pods, we should see access log entries for only `v1`:

    ```command
    $ export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    ```

    ```command
    $ export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V2_POD -c httpbin
    <none>
    ```

1.  Change the route rule to mirror traffic to v2

    ```bash
        cat <<EOF | istioctl replace -f -
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
    ```

    This route rule specifies we route 100% of the traffic to v1. The last stanza specifies we want to mirror to the `httpbin v2` service. When traffic gets mirrored, the requests are sent to the mirrored service with its Host/Authority header appended with *-shadow*. For example, *cluster-1* becomes *cluster-1-shadow*. Also important to realize is that these requests are mirrored as "fire and forget", i.e., the responses are discarded.

    Now if we send in traffic:

    ```command
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'
    ```

    We should see access logging for both `v1` and `v2`. The access logs created in `v2` is the mirrored requests that are actually going to `v1`.

    ```command
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    ```

    ```command
    $ kubectl logs -f $V2_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    ```

## Cleaning up

1.  Remove the rules.

    ```command
    $ istioctl delete virtualservice httpbin
    $ istioctl delete destinationrule httpbin
    ```

1.  Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service and client.

    ```command
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    ```

## What's next

Check out the [Mirroring configuration](/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute.mirror) reference documentation.
