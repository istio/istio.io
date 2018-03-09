---
title: Troubleshooting Guide
overview: Practical advice on practical problems with Istio

order: 40

layout: help
type: markdown
redirect_from: /troubleshooting
---
{% include home.html %}

Oh no! You're having trouble? Below is a list of solutions to common problems.

## Verifying connectivity to Istio Pilot

Verifying connectivity to Pilot is a useful troubleshooting step. Every proxy container in the service mesh should be able to communicate with Pilot. This can be accomplished in a few simple steps:

1. Get the name of the Istio Ingress pod:
```bash
INGRESS_POD_NAME=$(kubectl get po -n istio-system | grep ingress | awk '{print$1}')
```

1. Exec into the Istio Ingress pod:
```bash
kubectl exec -it $INGRESS_POD_NAME -n istio-system /bin/bash
```

1. Unless you installed Istio using the debug proxy image (`istioctl kube-inject --debug=true`), you need to
install curl.
```bash
apt-get update && apt-get install -y curl
```

1. Test connectivity to Pilot using cURL. The following example cURL's the v1 registration API using default Pilot configuration parameters and mTLS enabled:
```bash
curl -k --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem --key /etc/certs/key.pem https://istio-pilot:15003/v1/registration
```

If mTLS is disabled:
```bash
curl http://istio-pilot:15003/v1/registration
```

You should receive a response listing the "service-key" and "hosts" for each service in the mesh.

## No traces appearing in Zipkin when running Istio locally on Mac
Istio is installed and everything seems to be working except there are no traces showing up in Zipkin when there
should be.

This may be caused by a known [Docker issue](https://github.com/docker/for-mac/issues/1260) where the time inside
containers may skew significantly from the time on the host machine. If this is the case,
when you select a very long date range in Zipkin you will see the traces appearing as much as several days too early.

You can also confirm this problem by comparing the date inside a docker container to outside:

```bash
docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
date -u
Thu Jun 15 02:25:42 UTC 2017
```

To fix the problem, you'll need to shutdown and then restart Docker before reinstalling Istio.

## Envoy won't connect to my HTTP/1.0 service

Envoy requires HTTP/1.1 or HTTP/2 traffic for upstream services. For example, when using [NGINX](https://www.nginx.com/) for serving traffic behind Envoy, you will need to set the [proxy_http_version](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) directive in your NGINX config to be "1.1", since the NGINX default is 1.0

Example config:

```
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
```

## No grafana output when connecting from a local web client to Istio remotely hosted

Validate the client and server date and time match.

The time of the web client (e.g. Chrome) affects the output from Grafana. A simple solution
to this problem is to verify a time synchronization service is running correctly within the
Kubernetes cluster and the web client machine also is correctly using a time synchronization
service. Some common time synchronization systems are NTP and Chrony. This is especially
problematic is engineering labs with firewalls. In these scenarios, NTP may not be configured
properly to point at the lab-based NTP services.

## Where are the metrics for my service?

The expected flow of metrics is:

1. Envoy reports attributes to Mixer in batch (asynchronously from requests)
1. Mixer translates the attributes from Mixer into instances based on
   operator-provided configuration.
1. The instances are handed to Mixer adapters for processing and backend storage.
1. The backend storage systems record metrics data.

The default installations of Mixer ship with a [Prometheus](http://prometheus.io/)
adapter, as well as configuration for generating a basic set of metric
values and sending them to the Prometheus adapter. The
[Prometheus add-on]({{home}}/docs/tasks/telemetry/querying-metrics.html#about-the-prometheus-add-on)
also supplies configuration for an instance of Prometheus to scrape
Mixer for metrics.

If you do not see the expected metrics in the Istio Dashboard and/or via
Prometheus queries, there may be an issue at any of the steps in the flow
listed above. Below is a set of instructions to troubleshoot each of
those steps.

### Verify Mixer is receiving Report calls

Mixer generates metrics for monitoring the behavior of Mixer itself.
Check these metrics.

1. Establish a connection to the Mixer self-monitoring endpoint.

   In Kubernetes environments, execute the following command:

   ```bash
   kubectl -n istio-system port-forward <mixer pod> 9093 &
   ```

1. Verify successful report calls.

   On the [Mixer self-monitoring endpoint](http://localhost:9093/metrics),
   search for `grpc_server_handled_total`.

   You should see something like:

   ```
   grpc_server_handled_total{grpc_code="OK",grpc_method="Report",grpc_service="istio.mixer.v1.Mixer",grpc_type="unary"} 68
   ```

If you do not see any data for `grpc_server_handled_total` with a
`grpc_method="Report"`, then Mixer is not being called by Envoy to report
telemetry. In this case, ensure that the services have been properly
integrated into the mesh (either by via
[automatic]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection)
or [manual]({{home}}/docs/setup/kubernetes/sidecar-injection.html#manual-sidecar-injection) sidecar injection).

### Verify Mixer metrics configuration exists

1. Verify Mixer rules exist.

   In Kubernetes environments, issue the following command:

   ```bash
   kubectl get rules --all-namespaces
   ```

   With the default configuration, you should see something like:

   ```
   NAMESPACE      NAME        KIND
   istio-system   promhttp    rule.v1alpha2.config.istio.io
   istio-system   promtcp     rule.v1alpha2.config.istio.io
   istio-system   stdio       rule.v1alpha2.config.istio.io
   ```

   If you do not see anything named `promhttp` or `promtcp`, then there is
   no Mixer configuration for sending metric instances to a Prometheus adapter.
   You will need to supply configuration for rules that connect Mixer metric
   instances to a Prometheus handler.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L892)). -->

1. Verify Prometheus handler config exists.

   In Kubernetes environments, issue the following command:

   ```bash
   kubectl get prometheuses.config.istio.io --all-namespaces
   ```

   The expected output is:

   ```
   NAMESPACE      NAME           KIND
   istio-system   handler        prometheus.v1alpha2.config.istio.io
   ```

   If there are no prometheus handlers configured, you will need to reconfigure
   Mixer with the appropriate handler configuration.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L819)) -->

1. Verify Mixer metric instances config exists.

   In Kubernetes environments, issue the following command:

   ```bash
   kubectl get metrics.config.istio.io --all-namespaces
   ```

   The expected output is:

   ```
   NAMESPACE      NAME                         KIND
   istio-system   requestcount                 metric.v1alpha2.config.istio.io
   istio-system   requestduration              metric.v1alpha2.config.istio.io
   istio-system   requestsize                  metric.v1alpha2.config.istio.io
   istio-system   responsesize                 metric.v1alpha2.config.istio.io
   istio-system   stackdriverrequestcount      metric.v1alpha2.config.istio.io
   istio-system   stackdriverrequestduration   metric.v1alpha2.config.istio.io
   istio-system   stackdriverrequestsize       metric.v1alpha2.config.istio.io
   istio-system   stackdriverresponsesize      metric.v1alpha2.config.istio.io
   istio-system   tcpbytereceived              metric.v1alpha2.config.istio.io
   istio-system   tcpbytesent                  metric.v1alpha2.config.istio.io
   ```

   If there are no metric instances configured, you will need to reconfigure
   Mixer with the appropriate instance configuration.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L727)) -->

1. Verify Mixer configuration resolution is working for your service.

   1. Establish a connection to the Mixer self-monitoring endpoint.

      Setup a `port-forward` to the Mixer self-monitoring port as described in
      [Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

   1. On the [Mixer self-monitoring port](http://localhost:9093/metrics), search
      for `mixer_config_resolve_count`.

      You should find something like:

      ```
      mixer_config_resolve_count{error="false",target="details.default.svc.cluster.local"} 56
      mixer_config_resolve_count{error="false",target="ingress.istio-system.svc.cluster.local"} 67
      mixer_config_resolve_count{error="false",target="mongodb.default.svc.cluster.local"} 18
      mixer_config_resolve_count{error="false",target="productpage.default.svc.cluster.local"} 59
      mixer_config_resolve_count{error="false",target="ratings.default.svc.cluster.local"} 26
      mixer_config_resolve_count{error="false",target="reviews.default.svc.cluster.local"} 54
      ```

   1. Validate that there are values for `mixer_config_resolve_count` where
      `target="<your service>"` and `error="false"`.

      If there are only instances where `error="true"` where `target=<your service>`,
      there is likely an issue with Mixer configuration for your service. Logs
      information is needed to further debug.

      In Kubernetes environments, retrieve the Mixer logs via:

      ```bash
      kubectl -n istio-system logs <mixer pod> mixer
      ```

      Look for errors related to your configuration or your service in the
      returned logs.

More on viewing Mixer configuration can be found [here]({{home}}/help/faq/mixer.html#mixer-self-monitoring)

### Verify Mixer is sending metric instances to the Prometheus adapter

1. Establish a connection to the Mixer self-monitoring endpoint.

   Setup a `port-forward` to the Mixer self-monitoring port as described in
   [Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

1. On the [Mixer self-monitoring port](http://localhost:9093/metrics), search
   for `mixer_adapter_dispatch_count`.

   You should find something like:

   ```
   mixer_adapter_dispatch_count{adapter="prometheus",error="false",handler="handler.prometheus.istio-system",meshFunction="metric",response_code="OK"} 114
   mixer_adapter_dispatch_count{adapter="prometheus",error="true",handler="handler.prometheus.default",meshFunction="metric",response_code="INTERNAL"} 4
   mixer_adapter_dispatch_count{adapter="stdio",error="false",handler="handler.stdio.istio-system",meshFunction="logentry",response_code="OK"} 104
   ```

1. Validate that there are values for `mixer_adapter_dispatch_count` where
   `adapter="prometheus"` and `error="false"`.

   If there are are no recorded dispatches to the Prometheus adapter, there
   is likely a configuration issue. Please see
   [Verify Mixer metrics configuration exists](#verify-mixer-metrics-configuration-exists).

   If dispatches to the Prometheus adapter are reporting errors, check the
   Mixer logs to determine the source of the error. Most likely, there is a
   configuration issue for the handler listed in `mixer_adapter_dispatch_count`.

   In Kubernetes environment, check the Mixer logs via:

   ```bash
   kubectl -n istio-system logs <mixer pod> mixer
   ```

   Filter for lines including something like `Report 0 returned with: INTERNAL
   (1 error occurred:` (with some surrounding context) to find more information
   regarding Report dispatch failures.

### Verify Prometheus configuration

1. Connect to the Prometheus UI and verify that it can successfully
   scrape Mixer.

   In Kubernetes environments, setup port-forwarding as follows:

   ```bash
   kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
   ```

1. Visit [http://localhost:9090/config](http://localhost:9090/config).

   Confirm that an entry exists that looks like:

   ```yaml
   - job_name: 'istio-mesh'
     # Override the global default and scrape targets from this job every 5 seconds.
     scrape_interval: 5s
     # metrics_path defaults to '/metrics'
     # scheme defaults to 'http'.
     static_configs:
     - targets: ['istio-mixer.istio-system:42422']
   ```

1. Visit [http://localhost:9090/targets](http://localhost:9090/targets).

   Confirm that target `istio-mesh` has a status of **UP**.

## How can I debug issues with the service mesh?

### With [GDB](https://www.gnu.org/software/gdb/)

To debug Istio with `gdb`, you will need to run the debug images of Envoy / Mixer / Pilot. A recent `gdb` and the golang extensions (for Mixer/Pilot or other golang components) is required.

1.  `kubectl exec -it PODNAME -c [proxy | mixer | pilot]`
1.  Find process ID: ps ax
1.  gdb -p PID binary
1.  For go: info goroutines, goroutine x bt

### With [Tcpdump](http://www.tcpdump.org/tcpdump_man.html)

Tcpdump doesn't work in the sidecar pod - the container doesn't run as root. However any other container in the same pod will see all the packets, since the network namespace is shared. `iptables` will also see the pod-wide config.

Communication between Envoy and the app happens on 127.0.0.1, and is not encrypted.

## Envoy is crashing under load

Check your `ulimit -a`. Many systems have a 1024 open file descriptor limit by default which will cause Envoy to assert and crash with:

```bash
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
```

Make sure to raise your ulimit. Example: `ulimit -n 16384`

## Headless TCP Services Losing Connection from Istiofied Containers

If `istio-ca` is deployed, Envoy is restarted every 15 minutes to refresh certificates.
This causes the disconnection of TCP streams or long-running connections between services.

You should build resilience into your application for this type of
disconnect, but if you still want to prevent the disconnects from
happening, you will need to disable mTLS and the `istio-ca` deployment.

First, edit your istio config to disable mTLS

```
# comment out or uncomment out authPolicy: MUTUAL_TLS to toggle mTLS and then
kubectl edit configmap -n istio-system istio

# restart pilot and wait a few minutes
kubectl delete pods -n istio-system -l istio=pilot
```

Next, scale down the `istio-ca` deployment to disable Envoy restarts.

```
kubectl scale --replicas=0 deploy/istio-ca -n istio-system
```

This should stop istio from restarting Envoy and disconnecting TCP connections.

## Envoy Process High CPU Usage

For larger clusters, the default configuration that comes with Istio
refreshes the Envoy configuration every 1 second. This can cause high
CPU usage, even when Envoy isn't doing anything. In order to bring the
CPU usage down for larger deployments, increase the refresh interval for
Envoy to something higher, like 30 seconds.

```
# increase the field rdsRefreshDelay in the mesh and defaultConfig section
# set the refresh interval to 30s
kubectl edit configmap -n istio-system istio

# restart pilot and wait a few minutes
kubectl delete pods -n istio-system -l istio=pilot
```

Also make sure to reinject the sidecar into all of your pods, as
their configuration needs to be updated as well.

Afterwards, you should see CPU usage fall back to 0-1% while idling.
Make sure to tune these values for your specific deployment.

*Warning:*: Changes created by routing rules will take up to 2x refresh interval to propagate to the sidecars. 
While the larger refresh interval will reduce CPU usage, updates caused by routing rules may cause a period 
of HTTP 404s (upto 2x the refresh interval) until the Envoy sidecars get all relevant configuration. 

## Kubernetes webhook setup script files are missing from 0.5 release package

NOTE: The 0.5.0 and 0.5.1 releases are missing scripts to provision webhook certificates. Download the missing files from [here](https://raw.githubusercontent.com/istio/istio/master/install/kubernetes/webhook-create-signed-cert.sh) and [here](https://raw.githubusercontent.com/istio/istio/master/install/kubernetes/webhook-patch-ca-bundle.sh). Subsqeuent releases (> 0.5.1) should include these missing files.

## Automatic sidecar injection will fail if the kube-apiserver has proxy settings

This was tested on 0.5.0 with the additional files required as referenced in the above issue.   When the Kube-apiserver included 
proxy settings such as:
```yaml
env:
  - name: http_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
  value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
```
The sidecar injection would fail.   The only related failure logs was in the kube-apiserver log:
```bash
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
```
Make sure both pod and service CIDRs are not proxied according to *_proxy variables.  Check the kube-apiserver files and logs to verify the configuration and whether any requests are being proxied.

A workaround is to remove the proxy settings from the kube-apiserver manifest and restart the server or use a later version of kubernetes. 

An issue was filed in kubernetes related to this and has since been closed.   [https://github.com/kubernetes/kubeadm/issues/666](https://github.com/kubernetes/kubeadm/issues/666)
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
