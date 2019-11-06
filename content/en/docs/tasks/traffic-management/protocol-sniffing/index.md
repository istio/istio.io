---
title: Protocol Sniffing
description: Shows you how to define the new service without specifying port protocol.
weight: 30
keywords: [traffic-management,protocol-sniffing]
---

This task shows you how to define the new service without specifying the port protocol. For example, you 
can define service port as `foo` instead of `http-foo` and the protocol will be detected at runtime by sniffing packets. Using protocol 
sniffing will simplify the configuration of services.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Deploy services with unnamed ports

1. Deploy the service with unnamed ports:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - port: 8000
        targetPort: 80
      selector:
        app: httpbin
    EOF
    {{< /text >}}

1. Send some traffic to the service:

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {
        "headers": {
            "Accept": "*/*",
            "Content-Length": "0",
            "Host": "httpbin:8000",
            "User-Agent": "curl/7.64.0",
            "X-B3-Parentspanid": "8275e40953e5f646",
            "X-B3-Sampled": "0",
            "X-B3-Spanid": "b164613571570628",
            "X-B3-Traceid": "aa0235d4fc610a9c8275e40953e5f646"
        }
    }
    {{< /text >}}

1. Lock down to mutual TLS and apply destination rule to use strict mTLS between client and server

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "example-httpbin-strict"
    spec:
      targets:
      - name: httpbin
      peers:
      - mtls:
          mode: STRICT
    EOF
    $ kubectl apply -f - <<EOF
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF 
    {{< /text >}}

1. Send some traffic to the service.

    {{< text bash json >}}
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {
        "headers": {
            "Accept": "*/*",
            "Content-Length": "0",
            "Host": "httpbin:8000",
            "User-Agent": "curl/7.64.0",
            "X-B3-Parentspanid": "04595f99622ebad7",
            "X-B3-Sampled": "0",
            "X-B3-Spanid": "6447aac5207f8721",
            "X-B3-Traceid": "f1995acd49a8cd9304595f99622ebad7",
            "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=61ef4d48689a6ded74839118f612bf8af8639c8a11dbd28c3dd103669e5eeb31;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/sleep"
        }
    }
    {{< /text >}}


## Cleanup

1. Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.