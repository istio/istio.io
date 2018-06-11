---
title: Mutual TLS over HTTPS
description: Shows how to enable mutual TLS on HTTPS services.
weight: 80
keywords: [security,mutual-tls,https]
---

This task shows how Istio Mutual TLS works with HTTPS services. It includes:

* Deploying an HTTPS service without Istio sidecar

* Deploying an HTTPS service with Istio with mutual TLS disabled

* Deploying an HTTPS service with mutual TLS enabled. For each deployment, connect to this service and verify it works.

When the Istio sidecar is deployed with an HTTPS service, the proxy automatically downgrades
from L7 to L4 (no matter mutual TLS is enabled or not), which means it does not terminate the
original HTTPS traffic. And this is the reason Istio can work on HTTPS services.

## Before you begin

Set up Istio by following the instructions in the
[quick start](/docs/setup/kubernetes/quick-start/).
Note that authentication should be **disabled** at step 5 in the
[installation steps](/docs/setup/kubernetes/quick-start/#installation-steps).

### Generate certificates and configmap

You need to have openssl installed to run these commands:

```command
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
$ kubectl create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
secret "nginxsecret" created
```

Create a configmap used for the HTTPS service

```command
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
configmap "nginxconfigmap" created
```

## Deploy an HTTPS service without Istio sidecar

This section creates a NGINX-based HTTPS service.

```command
$ kubectl apply -f @samples/https/nginx-app.yaml@
service "my-nginx" created
replicationcontroller "my-nginx" created
```

Then, create another pod to call this service.

```command
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
```

Get the pods

```command
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    1/1       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
```

Ssh into the istio-proxy container of sleep pod.

```command
$ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy /bin/bash
```

Call my-nginx

```command
$ curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

You can actually combine the above three command into one:

```command
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

### Create an HTTPS service with the Istio sidecar and mutual TLS disabled

In "Before you begin" section, the Istio control plane is deployed with mutual TLS
disabled. So you only need to redeploy the NGINX HTTPS service with sidecar.

Delete the HTTPS service.

```command
$ kubectl delete -f @samples/https/nginx-app.yaml@
```

Deploy it with a sidecar

```command
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
```

Make sure the pod is up and running

```command
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-6svcc                    2/2       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
```

And run

```command
$ kubectl exec sleep-847544bbfc-d27jg -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

If you run from istio-proxy container, it should work as well

```command
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

> This example is borrowed from [kubernetes examples](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md).

### Create an HTTPS service with Istio sidecar with mutual TLS enabled

You need to deploy Istio control plane with mutual TLS enabled. If you have istio
control plane with mutual TLS disabled installed, please delete it:

```command
$ kubectl delete -f @install/kubernetes/istio.yaml@
```

And wait for everything is down, i.e., there is no pod in control plane namespace (istio-system).

```command
$ kubectl get pod -n istio-system
No resources found.
```

Then deploy the Istio control plane with mutual TLS enabled:

```command
$ kubectl apply -f @install/kubernetes/istio-demo-auth.yaml@
```

Make sure everything is up and running:

```command
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
servicegraph-5849b7d696-jrk8h              1/1       Running     0          23h
```

Then redeploy the HTTPS service and sleep service

```command
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
```

Make sure the pod is up and running

```command
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-9dvet                    2/2       Running   0          1h
sleep-77f457bfdd-hdknx            2/2       Running   0          18h
```

And run

```command
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

The reason is that for the workflow "sleep -> sleep-proxy -> nginx-proxy -> nginx",
the whole flow is L7 traffic, and there is a L4 mutual TLS encryption between sleep-proxy
and nginx-proxy. In this case, everything works fine.

However, if you run this command from istio-proxy container, it will not work.

```command
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
curl: (35) gnutls_handshake() failed: Handshake failed
command terminated with exit code 35
```

The reason is that for the workflow "sleep-proxy -> nginx-proxy -> nginx",
nginx-proxy is expected mutual TLS traffic from sleep-proxy. In the command above,
sleep-proxy does not provide client cert. As a result, it won't work. Moreover,
even sleep-proxy provides client cert in above command, it won't work either
since the traffic will be downgraded to http from nginx-proxy to nginx.

## Cleanup

```command
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/https/nginx-app.yaml@
$ kubectl delete configmap nginxconfigmap
$ kubectl delete secret nginxsecret
```
