---
title: How can I verify Istio mTLS indeed encrypt the traffic?
weight: 40
---

Once you turned on the mutual TLS, traffic is encrypted. We will show that through `tcpdump` in the
sidecar container.

To enable tcpdump, you need to install Istio with proxy priviledged enabled

{{< text bash >}}
$ istioctl manifest apply --set values.global.proxy.privileged=true
{{< /text >}}

{{< warning >}}
This installation is only for demo purpose, please revert the change after you are done for better security!
{{< /warning>}}

Deploy httpbin, sleep workloads, and a sleep-legacy deployment which does not have sidecar injected.

{{< text bash >}}
$ kubectl label ns default istio-injection=enabled
$ kubectl apply -f ./samples/httpbin/httpbin.yaml
$ kubectl apply -f ./samples/sleep/sleep.yaml
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep-legacy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep-legacy
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
      labels:
        app: sleep-legacy
    spec:
      containers:
      - name: sleep
        image: governmentpaas/curl-ssl
        command: ["/bin/sleep", "3650d"]
        imagePullPolicy: IfNotPresent
EOF
serviceaccount/httpbin unchanged
service/httpbin created
deployment.apps/httpbin created
serviceaccount/sleep unchanged
service/sleep created
deployment.apps/sleep created
deployment.apps/sleep-legacy created
{{< /text >}}

Configuring peer authentication as `STRICT`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
peerauthentication.security.istio.io/default created
{{< /text >}}

Now httpbin is protected under mutual TLS. We execute tcpdump in httpbin pod sidecar container.

{{< text bash >}}
$ kubectl exec $(kubectl get pod  -lapp=sleep -ojsonpath={.items..metadata.name}) -c istio-proxy -it -- sudo tcpdump dst port 80  -A
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
{{< /text >}}

In a separate terminal, we let sleep send some request to httpbin service.

{{< text bash >}}
$ kubectl exec $(kubectl get pod  -lapp=sleep -ojsonpath={.items..metadata.name})  -c sleep -- curl httpbin:8000/ip
{
  "origin": "127.0.0.1"
}
{{< /text >}}

Request succeeds also the tcpdump terminal prints out the encrypted text.

Now we let sleep-legacy send some request to httpbin service.

{{< text bash >}}
$ kubectl exec $(kubectl get pod  -lapp=sleep-legacy -ojsonpath={.items..metadata.name})  -c sleep -- curl httpbin:8000/ip
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
{{< /text >}}

Request fails because legacy client can't establish mutual TLS connection. The tcpdump terminal also prints out
plaintext `Host: httpbin:8000` as part of HTTP request payload.
