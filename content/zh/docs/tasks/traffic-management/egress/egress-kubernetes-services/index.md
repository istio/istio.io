---
title: Kubernetes Services for Egress Traffic
description: Shows how to configure Istio  Kubernetes External Services.
keywords: [traffic-management,egress]
weight: 60
---

Kubernetes [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname)
services and Kubernetes services with
[Endpoints](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors)
let you create a local DNS _alias_ to an external service.
This DNS alias has the same form as the DNS entries for local services, namely
`<service name>.<namespace name>.svc.cluster.local`. DNS aliases provide _location transparency_ for your workloads:
the workloads can call local and external services in the same way. If at some point in time you decide to deploy the
external service inside your cluster, you can just update its Kubernetes service to reference the local version. The workloads will continue to operate without any change.

This task shows that these Kubernetes mechanisms for accessing external services continue to work with Istio.
The only configuration step you must perform is to use a TLS mode other than Istio's
[mutual TLS](/docs/concepts/security/#mutual-tls-authentication). The external services are not part of an Istio service
mesh so they cannot perform the mutual TLS of Istio. You must set the TLS mode according to the TLS requirements of the
external service and according to the way your workload accesses the external service. If your workload issues plain
HTTP requests and the external service requires TLS, you may want to perform TLS origination by Istio. If your workload
already uses TLS, the traffic is already encrypted and you can just disable Istio's mutual TLS.

While the examples in this task use HTTP protocols,
Kubernetes Services for egress traffic work with other protocols as well.

{{< boilerplate before-you-begin-egress >}}

*  Create a namespace for a source pod without Istio control:

    {{< text bash >}}
    $ kubectl create namespace without-istio
    {{< /text >}}

*  Start the [sleep]({{< github_tree >}}/samples/sleep) sample in the `without-istio` namespace.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

*   To send requests, create the `SOURCE_POD_WITHOUT_ISTIO` environment variable to store the name of the source
    pod:

    {{< text bash >}}
    $ export SOURCE_POD_WITHOUT_ISTIO=$(kubectl get pod -n without-istio -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

*   Verify that the Istio sidecar was not injected, that is the pod has one container:

    {{< text bash >}}
    $ kubectl get pod $SOURCE_POD_WITHOUT_ISTIO -n without-istio
    NAME                     READY   STATUS    RESTARTS   AGE
    sleep-66c8d79ff5-8tqrl   1/1     Running   0          32s
    {{< /text >}}

## Kubernetes ExternalName service to access an external service

1.  Create a Kubernetes
    [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) service
    for `httpbin.org`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-httpbin
    spec:
      type: ExternalName
      externalName: httpbin.org
      ports:
      - name: http
        protocol: TCP
        port: 80
    EOF
    {{< /text >}}

1.  Observe your service. Note that it does not have a cluster IP.

    {{< text bash >}}
    $ kubectl get svc my-httpbin
    NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    my-httpbin   ExternalName   <none>       httpbin.org   80/TCP    4s
    {{< /text >}}

1.  Access `httpbin.org` via the Kubernetes service's hostname from the source pod without Istio sidecar:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD_WITHOUT_ISTIO -n without-istio -c sleep -- curl my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.55.0"
      }
    }
    {{< /text >}}

1.  In this example, unencrypted HTTP requests are sent to `httpbin.org`. For the sake of the example only, you disable
    the TLS mode and allow the unencrypted traffic to the external service. In the real life scenarios, we recommend
    to perform [Egress TLS origination](/docs/tasks/traffic-management/egress/egress-tls-origination/) by Istio.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: my-httpbin
    spec:
      host: my-httpbin.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Access `httpbin.org` via the Kubernetes service's hostname from the source pod with Istio sidecar. Notice the
    headers added by Istio sidecar, for example, `X-Istio-Attributes` and `X-Envoy-Decorator-Operation`. Also note that
    the `Host` header equals to your service's hostname.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.55.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "5b68b3f953945a08",
        "X-B3-Traceid": "0847ba2513aa0ffc5b68b3f953945a08",
        "X-Envoy-Decorator-Operation": "my-httpbin.default.svc.cluster.local:80/*",
        "X-Istio-Attributes": "CigKGGRlc3RpbmF0aW9uLnNlcnZpY2UubmFtZRIMEgpteS1odHRwYmluCioKHWRlc3RpbmF0aW9uLnNlcnZpY2UubmFtZXNwYWNlEgkSB2RlZmF1bHQKOwoKc291cmNlLnVpZBItEitrdWJlcm5ldGVzOi8vc2xlZXAtNjZjOGQ3OWZmNS04aG1neC5kZWZhdWx0CkAKF2Rlc3RpbmF0aW9uLnNlcnZpY2UudWlkEiUSI2lzdGlvOi8vZGVmYXVsdC9zZXJ2aWNlcy9teS1odHRwYmluCkIKGGRlc3RpbmF0aW9uLnNlcnZpY2UuaG9zdBImEiRteS1odHRwYmluLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWw="
      }
    }
    {{< /text >}}

### Cleanup of Kubernetes ExternalName service

{{< text bash >}}
$ kubectl delete destinationrule my-httpbin
$ kubectl delete service my-httpbin
{{< /text >}}

## Use a Kubernetes service with endpoints to access an external service

1.  Create a Kubernetes service without selector for Wikipedia:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-wikipedia
    spec:
      ports:
      - protocol: TCP
        port: 443
        name: tls
    EOF
    {{< /text >}}

1.  Create endpoints for your service. Pick a couple of IPs from the [Wikipedia ranges list](https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses).

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Endpoints
    apiVersion: v1
    metadata:
      name: my-wikipedia
    subsets:
      - addresses:
          - ip: 91.198.174.192
          - ip: 198.35.26.96
        ports:
          - port: 443
            name: tls
    EOF
    {{< /text >}}

1.  Observe your service. Note that it has a cluster IP which you can use to access `wikipedia.org`.

    {{< text bash >}}
    $ kubectl get svc my-wikipedia
    NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    my-wikipedia   ClusterIP   172.21.156.230   <none>        443/TCP   21h
    {{< /text >}}

1.  Send HTTPS requests to `wikipedia.org` by your Kubernetes service's cluster IP from the source pod without Istio
    sidecar.
    Use the `--resolve` option of `curl` to access `wikipedia.org` by the cluster IP:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD_WITHOUT_ISTIO -n without-istio -c sleep -- curl -s --resolve en.wikipedia.org:443:$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}') https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  In this case, the workload send HTTPS requests (open TLS connection) to the `wikipedia.org`. The traffic is already
    encrypted by the workload so you can safely disable Istio's mutual TLS:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: my-wikipedia
    spec:
      host: my-wikipedia.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Access `wikipedia.org` by your Kubernetes service's cluster IP from the source pod with Istio sidecar:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s --resolve en.wikipedia.org:443:$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}') https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Check that the access is indeed performed by the cluster IP. Notice the sentence
    `Connected to en.wikipedia.org   (172.21.156.230)` in the output of `curl -v`, it mentions the IP that was printed
    in the output of your service as the cluster IP.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -v --resolve en.wikipedia.org:443:$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}') https://en.wikipedia.org/wiki/Main_Page -o /dev/null
    * Added en.wikipedia.org:443:172.21.156.230 to DNS cache
    * Hostname en.wikipedia.org was found in DNS cache
    *   Trying 172.21.156.230...
    * TCP_NODELAY set
    * Connected to en.wikipedia.org (172.21.156.230) port 443 (#0)
    ...
    {{< /text >}}

### Cleanup of Kubernetes service with endpoints

{{< text bash >}}
$ kubectl delete destinationrule my-wikipedia
$ kubectl delete endpoints my-wikipedia
$ kubectl delete service my-wikipedia
{{< /text >}}

## Cleanup

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service in the `without-istio` namespace:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

1.  Delete `without-istio` namespace:

    {{< text bash >}}
    $ kubectl delete namespace without-istio
    {{< /text >}}

1. Unset the environment variables:

    {{< text bash >}}
    $ unset SOURCE_POD SOURCE_POD_WITHOUT_ISTIO
    {{< /text >}}
