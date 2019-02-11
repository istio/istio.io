---
title: Control Egress Traffic
description: Describes how to configure Istio to route traffic from services in the mesh to external services.
weight: 40
aliases:
    - /docs/tasks/egress.html
keywords: [traffic-management,egress]
---

By default, Istio-enabled services are unable to access URLs outside of the cluster because the pod uses
iptables to transparently redirect all outbound traffic to the sidecar proxy,
which only handles intra-cluster destinations.

This task describes how to configure Istio to expose external services to Istio-enabled clients.
You'll learn how to enable access to external services by defining
[`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) configurations,
or alternatively, to bypass the Istio proxy for a specific range of IPs.

{{< boilerplate before-you-begin-egress >}}

## Configuring Istio external services

Using Istio `ServiceEntry` configurations, you can access any publicly accessible service
from within your Istio cluster. This task shows you how to access an external HTTP service,
[httpbin.org](http://httpbin.org), as well as an external HTTPS service,
[www.google.com](https://www.google.com).

### Configuring an external HTTP service

1.  Create a `ServiceEntry` to allow access to an external HTTP service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Make a request to the external HTTP service from `SOURCE_POD`:

    {{< text bash >}}
    $  kubectl exec -it $SOURCE_POD -c sleep -- curl http://httpbin.org/headers
    {
      "headers": {
      "Accept": "*/*",
      "Connection": "close",
      "Host": "httpbin.org",
      "User-Agent": "curl/7.60.0",
      ...
      "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
      "X-Istio-Attributes": ...
      }
    }
    {{< /text >}}

    Note the headers added by the Istio sidecar proxy: `X-Envoy-Decorator-Operation` and `X-Istio-Attributes`.

1.  Check the log of the sidecar proxy of `SOURCE_POD`:

    {{< text bash >}}
    $  kubectl logs $SOURCE_POD -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    Note the entry related to your HTTP request to `httpbin.org/headers`.

1.  Check the Mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'httpbin.org'
    {"level":"info","time":"2019-01-24T12:17:11.855496Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"unknown","destinationApp":"","destinationIp":"I60GXg==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"httpbin.org","destinationWorkload":"unknown","grpcMessage":"","grpcStatus":"","httpAuthority":"httpbin.org","latency":"214.661667ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":270,"referer":"","reporter":"source","requestId":"17fde8f7-fa62-9b39-8999-302324e6def2","requestSize":0,"requestedServerName":"","responseCode":200,"responseSize":599,"responseTimestamp":"2019-01-24T12:17:11.855521Z","sentBytes":806,"sourceApp":"sleep","sourceIp":"AAAAAAAAAAAAAP//rB5tUg==","sourceName":"sleep-88ddbcfdd-rgk77","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/sleep","sourcePrincipal":"","sourceWorkload":"sleep","url":"/headers","userAgent":"curl/7.60.0","xForwardedFor":"0.0.0.0"}
    {{< /text >}}

    Note that the `destinationServiceHost` attribute is equal to `httpbin.org`. Also note HTTP-related attributes:
    `method`, `url`, `responseCode` and others. Using Istio egress traffic control, you can monitor access to external
    HTTP services, including the HTTP-related information of each access.

### Configuring an external HTTPS service

1.  Create a `ServiceEntry` to allow access to an external HTTPS service.
    For TLS protocols, including HTTPS, a `VirtualService` is required in addition to the `ServiceEntry`.
    Without it, exactly what service or services are exposed by the `ServiceEntry` is undefined.
    The `VirtualService` must include a `tls` rule with `sni_hosts` in the `match` clause to enable SNI routing.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      tls:
      - match:
        - port: 443
          sni_hosts:
          - www.google.com
        route:
        - destination:
            host: www.google.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Make a request to the external HTTPS service from `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl https://www.google.com | grep -o "<title>.*</title>"
    <title>Google</title>
    {{< /text >}}

1.  Check the log of the sidecar proxy of `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    Note the entry related to your HTTPS request to `www.google.com`.

1.  Check the Mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'www.google.com'
    {"level":"info","time":"2019-01-24T12:48:56.266553Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"1.289085134s","connectionEvent":"close","connection_security_policy":"unknown","destinationApp":"","destinationIp":"rNmhJA==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"www.google.com","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":601,"reporter":"source","requestedServerName":"www.google.com","sentBytes":17766,"sourceApp":"sleep","sourceIp":"rB5tUg==","sourceName":"sleep-88ddbcfdd-rgk77","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/sleep","sourcePrincipal":"","sourceWorkload":"sleep","totalReceivedBytes":601,"totalSentBytes":17766}
    {{< /text >}}

    Note that the `requestedServerName` attribute is equal to `www.google.com`. Using Istio egress traffic control, you
    can monitor access to external HTTPS services, in particular the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) and the number of sent and received bytes. Note that in
    HTTPS all the HTTP-related information like method, URL path, response code, is encrypted so Istio cannot see and
    cannot monitor that information for HTTPS. If you need to monitor HTTP-related information in access to external
    HTTPS services, you may want to let your applications issue HTTP requests and
    [configure Istio to perform TLS origination](/docs/examples/advanced-gateways/egress-tls-origination/).

### Setting route rules on an external service

Similar to inter-cluster requests, Istio
[routing rules](/docs/concepts/traffic-management/#rule-configuration)
can also be set for external services that are accessed using `ServiceEntry` configurations.
In this example, you set a timeout rule on calls to the `httpbin.org` service.

1.  From inside the pod being used as the test source, make a _curl_ request to the `/delay` endpoint of the httpbin.org external service:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep sh
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    200

    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    The request should return 200 (OK) in approximately 5 seconds.

1.  Exit the source pod and use `kubectl` to set a 3s timeout on calls to the `httpbin.org` external service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin-ext
    spec:
      hosts:
        - httpbin.org
      http:
      - timeout: 3s
        route:
          - destination:
              host: httpbin.org
            weight: 100
    EOF
    {{< /text >}}

1.  Wait a few seconds, then make the _curl_ request again:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep sh
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    504

    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    This time a 504 (Gateway Timeout) appears after 3 seconds.
    Although httpbin.org was waiting 5 seconds, Istio cut off the request at 3 seconds.

## Calling external services directly

If you want to completely bypass Istio for a specific IP range,
you can configure the Envoy sidecars to prevent them from
[intercepting](/docs/concepts/traffic-management/#communication-between-services)
the external requests. This can be done by setting the `global.proxy.includeIPRanges` variable of
[Helm](/docs/reference/config/installation-options/) and updating the `istio-sidecar-injector` configmap by using `kubectl apply`. After `istio-sidecar-injector` is updated, the value of `global.proxy.includeIPRanges` will affect all the future deployments of the application pods.

The simplest way to use the `global.proxy.includeIPRanges` variable is to pass it the IP range(s)
used for internal cluster services, thereby excluding external IPs from being redirected
to the sidecar proxy.
The values used for internal IP range(s), however, depends on where your cluster is running.
For example, with Minikube the range is 10.0.0.1&#47;24, so you would update your `istio-sidecar-injector` configmap like this:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> --set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

Note that you should use the same Helm command you used [to install Istio](/docs/setup/kubernetes/helm-install),
in particular, the same value of the `--namespace` flag. In addition to the flags you used to install Istio, add `--set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml`.

Redeploy the `sleep` application as described in the [Before you begin](#before-you-begin) section.

{{< warning >}}
Make sure to remove the previously deployed `ServiceEntry` and `VirtualService`.
{{< /warning >}}

### Set the value of `global.proxy.includeIPRanges`

Set the value of `global.proxy.includeIPRanges` according to your cluster provider.

#### IBM Cloud Private

1.  Get your `service_cluster_ip_range` from IBM Cloud Private configuration file under `cluster/config.yaml`:

    {{< text bash >}}
    $ cat cluster/config.yaml | grep service_cluster_ip_range
    {{< /text >}}

    The following is a sample output:

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  Use `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

Use `--set global.proxy.includeIPRanges="172.30.0.0/16\,172.21.0.0/16\,10.10.10.0/24"`

#### Google Container Engine (GKE)

The ranges are not fixed, so you will need to run the `gcloud container clusters describe` command to determine the ranges to use. For example:

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

Use `--set global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Container Service(ACS)

Use `--set global.proxy.includeIPRanges="10.244.0.0/16\,10.240.0.0/16`

#### Minikube, Docker For Desktop, Bare Metal

The default value is `10.96.0.0/12`, but it's not fixed. Use the following command to determine your actual value:

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

Use `--set global.proxy.includeIPRanges="10.96.0.0/12"`

### Access the external services

After updating the `istio-sidecar-injector` configmap and redeploying the `sleep` application,
the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request bypasses the sidecar and goes straight to its intended destination. For example:

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Connection": "close",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.60.0"
  }
}
{{< /text >}}

Note that this time you do not see any headers related to Istio sidecar. Also note that the requests sent to external
services appear neither in the log of the sidecar nor in the Mixer log: by bypassing Istio sidecars you lost monitoring
of access to external services.

## Install Istio with access to all external services by default

An alternative to calling external services directly is to instruct the Istio proxy to pass through the calls to all the
external services. This option allows you to start evaluating Istio quickly, without controlling access to external
services, and decide to [configure access to external services](#configuring-istio-external-services) later.

Istio has an installation option that allows access to all external services for which no HTTP service exists inside
the mesh and no HTTP/TCP `ServiceEntry` is defined. For example, if your mesh does not have an HTTP service on port 443,
and you did not define a `ServiceEntry` on port 443, you can access any external service on port 443. Note, however,
that once you create an HTTP service on port 443 or define any `ServiceEntry` for any host on
port 443, all accesses to port 443 is blocked: Istio will fall back to the blocking-by-default behavior for that
port only. (Defining an HTTP service on port 443 is not recommended anyway, since using the same port for TCP/HTTPS and
for HTTP traffic in Istio is discouraged.)

1.  To allow access to all the external services, install or update Istio by using
[Helm](https://preliminary.istio.io/docs/setup/kubernetes/helm-install/) while setting the value of
`global.outboundTrafficPolicy.mode` to `ALLOW_ANY`: `--set global.outboundTrafficPolicy.mode=ALLOW_ANY`.

    Alternatively, if you followed the instructions in
    [Quick Start with Kubernetes](https://preliminary.istio.io/docs/setup/kubernetes/quick-start/#installation-steps)
    and used `install/kubernetes/istio-demo.yaml` or `install/kubernetes/istio-demo-auth.yaml` files to install Istio,
    just edit the files. Look for the following YAML part:

    {{< text yaml >}}
    # Set the default behavior of the sidecar for handling outbound traffic from the application:
    # REGISTRY_ONLY - restrict outbound traffic to services defined in the service registry as well
    #   as those defined through ServiceEntries
    # ALLOW_ANY - outbound traffic to unknown destinations will be allowed, in case there are no
    #   services or ServiceEntries for the destination port
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
    {{< /text >}}

    Change `mode` of `outboundTrafficPolicy` from `REGISTRY_ONLY` to `ALLOW_ANY`. Then run `kubectl apply` with the
    edited file.

    Yet another option is to use `kubectl edit` to edit the relevant configuration map directly:
    `kubectl edit configmap istio -n istio-system`.

    For demonstration purposes, let's use `kubectl get --export`, `kubectl replace` and `sed`:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system --export -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

1.  Make a couple of requests to external HTTPS services from `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s https://www.google.com | grep -o "<title>.*</title>"; kubectl exec -it $SOURCE_POD -c sleep -- curl -s https://edition.cnn.com | grep -o "<title>.*</title>"
    <title>Google</title>
    <title>CNN International - Breaking News, US News, World News and Video</title>
    {{< /text >}}

    {{< warning >}}
    It might take time for the configuration change to propagate so you might still get connection errors.
    Wait for several seconds and then retry the last command.
    {{< /warning >}}

Note that the requests to port 80 are blocked for all the external services since Istio by default has HTTP services
that run on port 80. Also note that if you install Istio with allowed access to all the external services you loose
Istio monitoring on traffic to external services: the calls to external services will not appear in the Mixer log, for
example. To start monitoring access to external services, follow the steps in
[configure access to external services](#configuring-istio-external-services) (no need to update Istio).

### Change back to the blocking-by-default policy

To cancel your policy change for external services, undo the changes you performed in the previous section and update
Istio.

1.  For demonstration purposes, run:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system --export -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

1.  Make a couple of requests to external HTTPS services from `SOURCE_POD` to verify that they are now blocked:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s https://www.google.com | grep -o "<title>.*</title>"; kubectl exec -it $SOURCE_POD -c sleep -- curl -s https://edition.cnn.com | grep -o "<title>.*</title>"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    > It might take time for the configuration change to propagate so you might still get successful connections.
    Wait for several seconds and then retry the last command.

## Understanding what happened

In this task you looked at two ways to call external services from an Istio mesh:

1. Using a `ServiceEntry` for HTTP and a combination of `ServiceEntry` and `VirtualService` for HTTPS. This is the
   recommended way.

1. Configuring the Istio sidecar to exclude external IPs from its remapped IP table.

The first approach lets you use all of the same Istio service mesh features for calls to services inside or outside of
the cluster. You saw that you can monitor access to external services and set a timeout rule for calls to an external
service.

The second approach bypasses the Istio sidecar proxy, giving your services direct access to any external server.
However, configuring the proxy this way does require cluster provider specific knowledge and configuration.
In addition to that, you loose monitoring of access to external services and cannot apply Istio features on traffic to
external services.

## Security note

{{< warning >}}
Note that configuration examples in this task **do not enable secure egress traffic control** in
Istio.
A malicious application can bypass the Istio sidecar proxy and access any external service without Istio control.
{{< /warning >}}

To implement egress traffic control in a secure way, you must [direct egress traffic through an egress gateway](/docs/examples/advanced-gateways/egress-gateway) and address the security concerns expressed in
[Configure an Egress Gateway example, Additional Security Considerations](/docs/examples/advanced-gateways/egress-gateway#additional-security-considerations).

## Cleanup

1.  Remove the rules:

    {{< text bash >}}
    $ kubectl delete serviceentry httpbin-ext google
    $ kubectl delete virtualservice httpbin-ext google
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Update the `istio-sidecar-injector` configmap to redirect all outbound traffic to the sidecar proxies:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio <the flags you used to install Istio> -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
    {{< /text >}}
