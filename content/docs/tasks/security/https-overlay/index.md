---
title: Mutual TLS over HTTPS
description: Shows how to enable mutual TLS on HTTPS services.
weight: 80
keywords: [security,mutual-tls,https]
---

This task shows how mutual TLS works with HTTPS services. It includes:

* Deploying an HTTPS service without Istio sidecar

* Deploying an HTTPS service with Istio with mutual TLS disabled

* Deploying an HTTPS service with mutual TLS enabled. For each deployment, connect to this service and verify it works.

When the Istio sidecar is deployed with an HTTPS service, the proxy automatically downgrades
from L7 to L4 (no matter mutual TLS is enabled or not), which means it does not terminate the
original HTTPS traffic. And this is the reason Istio can work on HTTPS services.

## Before you begin

Set up Istio by following the instructions in the
[quick start](/docs/setup/kubernetes/quick-start/).
Note that default mutual TLS authentication should be **disabled** when installing Istio; e.g. option 1 in the
[quick start](/docs/setup/kubernetes/quick-start/#installation-steps).

The demo is also assumed to be running in a namespace where automatic sidecar injection is
disabled, and Istio sidecars are instead manually injected with `istioctl`.

### Generate certificates and configmap

The following examples consider an NGINX service pod which can encrypt traffic using HTTPS.
Before beginning, generate the TLS certificate and key that this service will use.

You need to have openssl installed to run these commands:

{{< text bash >}}
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
$ kubectl create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
secret "nginxsecret" created
{{< /text >}}

Create a configmap used for the HTTPS service

{{< text bash >}}
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
configmap "nginxconfigmap" created
{{< /text >}}

## Deploy an HTTPS service without the Istio sidecar

This section creates a NGINX-based HTTPS service.

{{< text bash >}}
$ kubectl apply -f @samples/https/nginx-app.yaml@
service "my-nginx" created
replicationcontroller "my-nginx" created
{{< /text >}}

Then, create another pod to call this service.

{{< text bash >}}
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
{{< /text >}}

Get the pods

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    1/1       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

Ssh into the `istio-proxy` container of sleep pod.

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy /bin/bash
{{< /text >}}

Call my-nginx

{{< text bash >}}
$ curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

You can actually combine the above three command into one:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

### Create an HTTPS service with the Istio sidecar and mutual TLS disabled

In "Before you begin" section, the Istio control plane is deployed with mutual TLS
disabled. So you only need to redeploy the NGINX HTTPS service with sidecar.

Delete the HTTPS service.

{{< text bash >}}
$ kubectl delete -f @samples/https/nginx-app.yaml@
{{< /text >}}

Deploy it with a sidecar

{{< text bash >}}
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

Make sure the pod is up and running

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-6svcc                    2/2       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

And run

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

If you run from the `istio-proxy` container, it should work as well:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

> This example is borrowed from [Kubernetes examples](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md).

### Create an HTTPS service with Istio sidecar with mutual TLS enabled

You need to deploy Istio control plane with mutual TLS enabled. If you have the Istio
control plane with mutual TLS disabled installed, please delete it. For example, if
you followed the quick start:

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}

And wait for everything to have been deleted, i.e., there is no pod in the control plane namespace (`istio-system`):

{{< text bash >}}
$ kubectl get pod -n istio-system
No resources found.
{{< /text >}}

Then deploy the Istio control plane with mutual TLS enabled:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

Make sure everything is up and running:

{{< text bash >}}
$ kubectl get po -n istio-system
NAME                                       READY     STATUS      RESTARTS   AGE
grafana-6f6dff9986-r6xnq                   1/1       Running     0          23h
istio-citadel-599f7cbd46-85mtq             1/1       Running     0          1h
istio-cleanup-old-ca-mcq94                 0/1       Completed   0          23h
istio-egressgateway-78dd788b6d-jfcq5       1/1       Running     0          23h
istio-ingressgateway-7dd84b68d6-dxf28      1/1       Running     0          23h
istio-mixer-post-install-g8n9d             0/1       Completed   0          23h
istio-pilot-d5bbc5c59-6lws4                2/2       Running     0          23h
istio-policy-64595c6fff-svs6v              2/2       Running     0          23h
istio-sidecar-injector-645c89bc64-h2dnx    1/1       Running     0          23h
istio-statsd-prom-bridge-949999c4c-mv8qt   1/1       Running     0          23h
istio-telemetry-cfb674b6c-rgdhb            2/2       Running     0          23h
istio-tracing-754cdfd695-wqwr4             1/1       Running     0          23h
prometheus-86cb6dd77c-ntw88                1/1       Running     0          23h
{{< /text >}}

Then redeploy the HTTPS service and sleep service

{{< text bash >}}
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

Make sure the pod is up and running

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-9dvet                    2/2       Running   0          1h
sleep-77f457bfdd-hdknx            2/2       Running   0          18h
{{< /text >}}

And run

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

The reason is that for the workflow "sleep -> `sleep-proxy` -> `nginx-proxy` -> nginx",
the whole flow is L7 traffic, and there is a L4 mutual TLS encryption between `sleep-proxy`
and `nginx-proxy`. In this case, everything works fine.

However, if you run this command from the `istio-proxy` container, it will not work:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
curl: (35) gnutls_handshake() failed: Handshake failed
command terminated with exit code 35
{{< /text >}}

The reason is that for the workflow "sleep-proxy -> nginx-proxy -> nginx",
nginx-proxy is expected mutual TLS traffic from sleep-proxy. In the command above,
sleep-proxy does not provide client cert. As a result, it won't work. Moreover,
even sleep-proxy provides client cert in above command, it won't work either
since the traffic will be downgraded to http from nginx-proxy to nginx.

## Cleanup

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/https/nginx-app.yaml@
$ kubectl delete configmap nginxconfigmap
$ kubectl delete secret nginxsecret
{{< /text >}}
