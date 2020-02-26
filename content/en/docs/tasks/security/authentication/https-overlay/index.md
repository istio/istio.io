---
title: Mutual TLS over HTTPS
description: Shows how to enable mutual TLS on HTTPS services.
weight: 30
keywords: [security,mutual-tls,https]
aliases:
    - /docs/tasks/security/https-overlay/
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
[quick start](/docs/setup/getting-started/).
Note that default mutual TLS authentication should be **disabled** when installing Istio using the `demo` profile.

The demo is also assumed to be running in a namespace where automatic sidecar injection is
disabled, and Istio sidecars are instead manually injected with [`istioctl`](/docs/reference/commands/istioctl).

### Generate certificates and configmap

The following examples consider an NGINX service pod which can encrypt traffic using HTTPS.
Before beginning, generate the TLS certificate and key that this service will use.

You need to have openssl installed to run these commands:

{{< text bash >}}
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
$ kubectl create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
secret/nginxsecret created
{{< /text >}}

Create a configmap used for the HTTPS service

{{< text bash >}}
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
configmap/nginxconfigmap created
{{< /text >}}

## Deploy an HTTPS service without the Istio sidecar

This section creates a NGINX-based HTTPS service.

{{< text bash >}}
$ kubectl apply -f @samples/https/nginx-app.yaml@
service/my-nginx created
replicationcontroller/my-nginx created
{{< /text >}}

Then, create another pod to call this service.

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
{{< /text >}}

Get the pods

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    1/1       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

From the `istio-proxy` container of the sleep pod, we will make a request to the my-nginx pod.

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
service "my-nginx" deleted
replicationcontroller "my-nginx" deleted
{{< /text >}}

Deploy it with a sidecar

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
service/my-nginx created
replicationcontroller/my-nginx created
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

{{< tip >}}
This example is borrowed from [Kubernetes examples](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md).
{{< /tip >}}

### Create an HTTPS service with Istio sidecar with mutual TLS enabled

You need to deploy Istio control plane with mutual TLS enabled. If you have the Istio
control plane with mutual TLS disabled installed, please delete it. For example, if
you followed the quick start:

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

And wait for everything to have been deleted, i.e., there is no pod in the control plane namespace (`istio-system`):

{{< text bash >}}
$ kubectl get pod -n istio-system
No resources found.
{{< /text >}}

Install Istio with the **strict mutual TLS mode** enabled:

{{< text bash >}}
$ istioctl manifest apply --set profile=demo --set values.global.mtls.enabled=true
{{< /text >}}

Make sure everything is up and running:

{{< text bash >}}
$ kubectl get po -n istio-system
NAME                                       READY     STATUS      RESTARTS   AGE
istio-ingressgateway-6cdb79b5d7-xsz8m      1/1       Running     0          123m
istiod-5b5b57486-fxz2c                     1/1       Running     0          123m
prometheus-5bdcdc85f6-8l752                2/2       Running     0          123m
{{< /text >}}

Then delete the HTTPS service

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
service "my-nginx" deleted
replicationcontroller "my-nginx" deleted
{{< /text >}}

followed by the sleep service

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
serviceaccount "sleep" deleted
service "sleep" deleted
deployment.apps "sleep" deleted
{{< /text >}}

And then re-deploy the HTTP service

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
service/my-nginx created
replicationcontroller/my-nginx created
{{< /text >}}

followed by the sleep service

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
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
curl: (56) OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
command terminated with exit code 56
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
