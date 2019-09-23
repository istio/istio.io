---
title: Accessing External Services
description: Describes how to configure Istio to route traffic from services in the mesh to external services.
weight: 10
aliases:
    - /docs/tasks/egress.html
    - /docs/tasks/egress
keywords: [traffic-management,egress]
---

Because all outbound traffic from an Istio-enabled pod is redirected to its sidecar proxy by default,
accessibility of URLs outside of the cluster depends on the configuration of the proxy.
By default, Istio configures the Envoy proxy to passthrough requests for unknown services.
Although this provides a convenient way to get started with Istio, configuring
stricter control is usually preferable.

This task shows you how to access external services in three different ways:

1. Allow the Envoy proxy to pass requests through to services that are not configured inside the mesh.
1. Configure [service entries](/docs/reference/config/networking/v1alpha3/service-entry/) to provide controlled access to external services.
1. Completely bypass the Envoy proxy for a specific range of IPs.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for sending requests.
    If you have
    [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    enabled, run the following command to deploy the sample app:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, manually inject the sidecar before deploying the `sleep` application with the following command:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Set the `SOURCE_POD` environment variable to the name of your source pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Envoy passthrough to external services

Istio has an [installation option](/docs/reference/config/installation-options/),
`global.outboundTrafficPolicy.mode`, that configures the sidecar handling
of external services, that is, those services that are not defined in Istio's internal service registry.
If this option is set to `ALLOW_ANY`, the Istio proxy lets calls to unknown services pass through.
If the option is set to `REGISTRY_ONLY`, then the Istio proxy blocks any host without an HTTP service or
service entry defined within the mesh.
`ALLOW_ANY` is the default value, allowing you to start evaluating Istio quickly,
without controlling access to external services.
You can then decide to [configure access to external services](#controlled-access-to-external-services) later.

1. To see this approach in action you need to ensure that your Istio installation is configured
    with the `global.outboundTrafficPolicy.mode` option set to `ALLOW_ANY`. Unless you explicitly
    set it to `REGISTRY_ONLY` mode when you installed Istio, it is probably enabled by default.

    Run the following command to confirm it is configured correctly:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY"
    mode: ALLOW_ANY
    {{< /text >}}

    The string `mode: ALLOW_ANY` should appear in the output if it is enabled.

    {{< tip >}}
    If you have explicitly configured `REGISTRY_ONLY` mode, you can run the following command to change it:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

    {{< /tip >}}

1.  Make a couple of requests to external HTTPS services from the `SOURCE_POD` to confirm
    successful `200` responses:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

Congratulations! You successfully sent egress traffic from your mesh.

This simple approach to access external services, has the drawback that you lose Istio monitoring and control
for traffic to external services; calls to external services will not appear in the Mixer log, for example.
The next section shows you how to monitor and control your mesh's access to external services.

## Controlled access to external services

Using Istio `ServiceEntry` configurations, you can access any publicly accessible service
from within your Istio cluster. This section shows you how to configure access to an external HTTP service,
[httpbin.org](http://httpbin.org), as well as an external HTTPS service,
[www.google.com](https://www.google.com) without losing Istio's traffic monitoring and control features.

### Change to the blocking-by-default policy

To demonstrate the controlled way of enabling access to external services, you need to change the
`global.outboundTrafficPolicy.mode` option from the `ALLOW_ANY` mode to the `REGISTRY_ONLY` mode.

{{< tip >}}
You can add controlled access to services that are already accessible in `ALLOW_ANY` mode.
This way, you can start using Istio features on some external services without blocking any others.
Once you've configured all of your services, you can then switch the mode to `REGISTRY_ONLY` to block
any other unintentional accesses.
{{< /tip >}}

1.  Run the following command to change the `global.outboundTrafficPolicy.mode` option to `REGISTRY_ONLY`:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

1.  Make a couple of requests to external HTTPS services from `SOURCE_POD` to verify that they are now blocked:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    It may take a while for the configuration change to propagate, so you might still get successful connections.
    Wait for several seconds and then retry the last command.
    {{< /warning >}}

### Access an external HTTP service

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
      }
    }
    {{< /text >}}

    Note the headers added by the Istio sidecar proxy: `X-Envoy-Decorator-Operation`.

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

    Note that the `destinationServiceHost` attribute is equal to `httpbin.org`. Also notice the HTTP-related attributes:
    `method`, `url`, `responseCode` and others. Using Istio egress traffic control, you can monitor access to external
    HTTP services, including the HTTP-related information of each access.

### Access an external HTTPS service

1.  Create a `ServiceEntry` to allow access to an external HTTPS service.

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
    EOF
    {{< /text >}}

1.  Make a request to the external HTTPS service from `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"
    HTTP/2 200
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
    [configure Istio to perform TLS origination](/docs/tasks/traffic-management/egress/egress-tls-origination/).

### Manage traffic to external services

Similar to inter-cluster requests, Istio
[routing rules](/docs/concepts/traffic-management/)
can also be set for external services that are accessed using `ServiceEntry` configurations.
In this example, you set a timeout rule on calls to the `httpbin.org` service.

1.  From inside the pod being used as the test source, make a _curl_ request to the `/delay` endpoint of the
    httpbin.org external service:

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

### Cleanup the controlled access to external services

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

## Direct access to external services

If you want to completely bypass Istio for a specific IP range,
you can configure the Envoy sidecars to prevent them from
[intercepting](/docs/concepts/traffic-management/)
external requests. To set up the bypass, change either the `global.proxy.includeIPRanges`
or the `global.proxy.excludeIPRanges` [configuration option](/docs/reference/config/installation-options/) and
update the `istio-sidecar-injector` configuration map using the `kubectl apply` command.
After updating the `istio-sidecar-injector` configuration, it affects all
future application pod deployments.

{{< warning >}}
Unlike [Envoy passthrough to external services](#envoy-passthrough-to-external-services),
which uses the `ALLOW_ANY` traffic policy to instruct the Istio sidecar proxy to
passthrough calls to unknown services,
this approach completely bypasses the sidecar, essentially disabling all of Istio's features
for the specified IPs. You cannot incrementally add service entries for specific
destinations, as you can with the `ALLOW_ANY` approach.
Therefore, this configuration approach is only recommended as a last resort
when, for performance or other reasons, external access cannot be configured using the sidecar.
{{< /warning >}}

A simple way to exclude all external IPs from being redirected to the sidecar proxy is
to set the `global.proxy.includeIPRanges` configuration option to the IP range or ranges
used for internal cluster services.
These IP range values depend on the platform where your cluster runs.

### Determine the internal IP ranges for your platform

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

The ranges are not fixed, so you will need to run the `gcloud container clusters describe` command to determine the
ranges to use. For example:

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

### Configuring the proxy bypass

{{< warning >}}
Remove the service entry and virtual service previously deployed in this guide.
{{< /warning >}}

Update your `istio-sidecar-injector` configuration map using the IP ranges specific to your platform.
For example, if the range is 10.0.0.1&#47;24, use the following command:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> --set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

Use the same Helm command that you used to [install Istio](/docs/setup/install/helm),
specifically, ensure you use the same value for the `--namespace` flag and
add these flags: `--set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml`.

### Access the external services

Because the bypass configuration only affects new deployments, you need to redeploy the `sleep`
application as described in the [Before you begin](#before-you-begin) section.

After updating the `istio-sidecar-injector` configmap and redeploying the `sleep` application,
the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request bypasses the sidecar and goes straight to its intended destination.
For example:

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

Unlike accessing external services through HTTP or HTTPS, you don't see any headers related to the Istio sidecar and the
requests sent to external services appear neither in the log of the sidecar nor in the Mixer log.
Bypassing the Istio sidecars means you can no longer monitor the access to external services.

### Cleanup the direct access to external services

Update the `istio-sidecar-injector.configmap.yaml` configuration map to redirect all outbound traffic to the sidecar
proxies:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

## Understanding what happened

In this task you looked at three ways to call external services from an Istio mesh:

1. Configuring Envoy to allow access to any external service.

1. Use a service entry to register an accessible external service inside the mesh. This is the
   recommended approach.

1. Configuring the Istio sidecar to exclude external IPs from its remapped IP table.

The first approach directs traffic through the Istio sidecar proxy, including calls to services
that are unknown inside the mesh. When using this approach,
you can't monitor access to external services or take advantage of Istio's traffic control features for them.
To easily switch to the second approach for specific services, simply create service entries for those external services.
This process allows you to initially access any external service and then later
decide whether or not to control access, enable traffic monitoring, and use traffic control features as needed.

The second approach lets you use all of the same Istio service mesh features for calls to services inside or
outside of the cluster. In this task, you learned how to monitor access to external services and set a timeout
rule for calls to an external service.

The third approach bypasses the Istio sidecar proxy, giving your services direct access to any external server.
However, configuring the proxy this way does require cluster-provider specific knowledge and configuration.
Similar to the first approach, you also lose monitoring of access to external services and you can't apply
Istio features on traffic to external services.

## Security note

{{< warning >}}
Note that configuration examples in this task **do not enable secure egress traffic control** in Istio.
A malicious application can bypass the Istio sidecar proxy and access any external service without Istio control.
{{< /warning >}}

To implement egress traffic control in a more secure way, you must
[direct egress traffic through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/)
and review the security concerns described in the
[additional security considerations](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)
section.

## Cleanup

Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
