---
title: Mutual TLS over HTTPS
description: Shows how to enable mTLS on HTTPS services.
weight: 80
---

This task shows how Istio Mutual TLS works with HTTPS services. It includes: 1)
Deploy an HTTPS service without Istio sidecar; 2) Deploy an HTTPS service with
Istio with mTLS disabled; 3) Deploy an HTTPS service with mTLS enabled. For each
deployment, connect to this service and verify it works.

When the Istio sidecar is deployed with an HTTPS service, the proxy automatically downgrades
from L7 to L4 (no matter mTLS is enabled or not), which means it does not terminate the
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
$ secret "nginxsecret" created
```

Create a configmap used for the HTTPS service

```command
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
$ configmap "nginxconfigmap" created
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
$ kubectl apply -f <(bin/istioctl kube-inject --debug -f @samples/sleep/sleep.yaml@)
```

Get the pods

```command
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    2/2       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
```

Ssh into the istio-proxy container of sleep pod.

```command
$ kubectl exec -it sleep-847544bbfc-d27jg -c istio-proxy /bin/bash
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

### Create an HTTPS service with the Istio sidecar and mTLS disabled

In "Before you begin" section, the Istio control plane is deployed with mTLS
disabled. So you only need to redeploy the NGINX HTTPS service with sidecar.

Delete the HTTPS service.

```command
$ kubectl delete -f nginx-app.yaml
```

Deploy it with a sidecar

```command
$ kubectl apply -f <(bin/istioctl kube-inject --debug -f @samples/https/nginx-app.yaml@)
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
$ kubectl exec sleep-847544bbfc-d27jg -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

> This example is borrowed from [kubernetes examples](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md).

### Create an HTTPS service with Istio sidecar with mTLS enabled

You need to deploy Istio control plane with mTLS enabled. If you have istio
control plane with mTLS disabled installed, please delete it:

```command
$ kubectl delete -f @install/kubernetes/istio.yaml@
```

And wait for everything is down, i.e., there is no pod in control plane namespace (istio-system).

```command
$ kubectl get pod -n istio-system
No resources found.
```

Then deploy the Istio control plane with mTLS enabled:

```command
$ kubectl apply -f @install/kubernetes/istio-auth.yaml@
```

Make sure everything is up and running:

```command
$ kubectl get po -n istio-system
NAME                             READY     STATUS    RESTARTS   AGE
istio-citadel-58c5856966-k6nm4   1/1       Running   0          2m
istio-ingress-5789d889bc-xzdg2   1/1       Running   0          2m
istio-mixer-65c55bc5bf-8n95w     3/3       Running   0          2m
istio-pilot-6954dcd96d-phh5z     2/2       Running   0          2m
```

Then redeploy the HTTPS service and sleep service

```command
$ kubectl delete -f <(bin/istioctl kube-inject --debug -f @samples/sleep/sleep.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject --debug -f @samples/sleep/sleep.yaml@)
$ kubectl delete -f <(bin/istioctl kube-inject --debug -f @samples/https/nginx-app.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject --debug -f @samples/https/nginx-app.yaml@)
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
$ kubectl exec sleep-77f457bfdd-hdknx -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
```

The reason is that for the workflow "sleep -> sleep-proxy -> nginx-proxy -> nginx",
the whole flow is L7 traffic, and there is a L4 mTLS encryption between sleep-proxy
and nginx-proxy. In this case, everything works fine.

However, if you run this command from istio-proxy container, it will not work.

```command
$ kubectl exec sleep-77f457bfdd-hdknx -c istio-proxy -- curl https://my-nginx -k
curl: (35) gnutls_handshake() failed: Handshake failed
command terminated with exit code 35
```

The reason is that for the workflow "sleep-proxy -> nginx-proxy -> nginx",
nginx-proxy is expected mTLS traffic from sleep-proxy. In the command above,
sleep-proxy does not provide client cert. As a result, it won't work. Moreover,
even sleep-proxy provides client cert in above command, it won't work either
since the traffic will be downgraded to http from nginx-proxy to nginx.
