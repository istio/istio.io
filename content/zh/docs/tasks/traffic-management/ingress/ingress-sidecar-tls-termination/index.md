---
title: Ingress Sidecar TLS 终止
description: 描述了如何在不使用 Ingress Gateway 的情况下，在一个 Sidecar 上终止 TLS 流量。
weight: 30
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

在常规的 Istio 网格部署中，下游请求的 TLS 终止是在 Ingress Gateway 处执行的。
虽然这可以满足大多数使用场景，但对于某些场景（如网格中的 API 网关），Ingress Gateway
并不是必需的。此任务展示了如何消除 Istio Ingress Gateway 引入的额外跃点，
并让与应用程序一起运行的 Envoy Sidecar 对来自服务网格外部的请求执行 TLS 终止。

用于此任务的示例 HTTPS 服务是一个简单的 [httpbin](https://httpbin.org/) 服务。
在以下步骤中，您将在服务网格中部署 httpbin 服务并对其进行配置。

{{< boilerplate experimental-feature-warning >}}

## 准备工作 {#before-you-begin}

*   按照[安装指南](/zh/docs/setup/)中的说明设置 Istio ，启用实验功能 `ENABLE_TLS_ON_SIDECAR_INGRESS`。

    {{< text bash >}}
    $ istioctl install --set profile=default --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
    {{< /text >}}

*   创建一个 test 命名空间，在其中部署目标 `httpbin` 服务。确保为该命名空间启用 Sidecar 注入。

    {{< text bash >}}
    $ kubectl create ns test
    $ kubectl label namespace test istio-injection=enabled
    {{< /text >}}

## 启用全局 mTLS {#enable-global-mtls}

应用以下 `PeerAuthentication` 策略，对网格中的所有工作负载实现 mTLS 流量。

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

## 为外部暴露的 httpbin 端口禁用 PeerAuthentication {#disable-peerauthentication-for-the-externally-exposed-httpbin-port}

在 httpbin 服务的端口处禁用 `PeerAuthentication`，在 sidecar 处执行入口
TLS 终止。请注意，这里是 httpbin 服务的 `targetPort`，专门用于与外部通信。

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: disable-peer-auth-for-external-mtls-port
  namespace: test
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    9080:
      mode: DISABLE
EOF
{{< /text >}}

## 生成 CA 证书、服务器证书/密钥和客户端证书/密钥 {#generate-ca-cert-server-certkey-and-client-certkey}

对于此任务，您可以使用自己喜欢的工具来生成证书和密钥。下面的命令使用
[openssl](https://man.openbsd.org/openssl.1)：

{{< text bash >}}
$ #CA is example.com
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
$ #Server is httpbin.test.svc.cluster.local
$ openssl req -out httpbin.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout httpbin.test.svc.cluster.local.key -subj "/CN=httpbin.test.svc.cluster.local/O=httpbin organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in httpbin.test.svc.cluster.local.csr -out httpbin.test.svc.cluster.local.crt
$ #client is client.test.svc.cluster.local
$ openssl req -out client.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout client.test.svc.cluster.local.key -subj "/CN=client.test.svc.cluster.local/O=client organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.test.svc.cluster.local.csr -out client.test.svc.cluster.local.crt
{{< /text >}}

## 为证书和密钥创建 Kubernetes secret {#create-k8s-secrets-for-the-certificates-and-keys}

{{< text bash >}}
$ kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
$ kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
{{< /text >}}

## 部署测试服务 httpbin {#deploy-the-httpbin-test-service}

当创建 httpbin Deployment 时，我们需要在该 Deployment 中使用 `userVolumeMount`
注解来为 istio-proxy Sidecar 挂载证书。请注意，之所以需要此步骤是因为 Istio Sidecar
目前不支持 `credentialName` 配置。

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

使用以下命令部署带有 `userVolumeMount` 配置的 `httpbin` 服务：

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:

  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - port: 8443
    name: https
    targetPort: 9080
  - port: 8080
    name: http
    targetPort: 9081
    selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
      annotations:
        sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
        sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
        EOF
        {{< /text >}}

## 配置 httpbin 以启用外部 mTLS {#configure-httpbin-to-enable-external-mtls}

这是此功能的核心步骤。使用 `Sidecar` API 配置入口 TLS 设置。TLS 模式可以是
`SIMPLE` 或 `MUTUAL`，本示例使用 `MUTUAL`。

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: ingress-sidecar
  namespace: test
spec:
  workloadSelector:
    labels:
      app: httpbin
      version: v1
  ingress:
  - port:
      number: 9080
      protocol: HTTPS
      name: external
    defaultEndpoint: 0.0.0.0:80
    tls:
      mode: MUTUAL
      privateKey: "/etc/istio/tls-certs/tls.key"
      serverCertificate: "/etc/istio/tls-certs/tls.crt"
      caCertificates: "/etc/istio/tls-ca-certs/ca.crt"
  - port:
      number: 9081
      protocol: HTTP
      name: internal
    defaultEndpoint: 0.0.0.0:80
      EOF
      {{< /text >}}

## 验证 {#verification}

现在已经部署和配置了 httpbin 服务器，启动两个客户端来测试网格内部和外部的端到端连接：

1. 在与 httpbin 服务相同的命名空间（test）中的内部客户端（sleep），已注入 Sidecar。
2. 在 default 命名空间（即服务网格外部）中的外部客户端（sleep）。

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl -n test apply -f samples/sleep/sleep.yaml
{{< /text >}}

运行以下命令以验证一切都已启动并正在运行，并且配置正确。

{{< text bash >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-557747455f-xx88g   1/1     Running   0          4m14s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n test
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
sleep-557747455f-brzf6     2/2     Running   0          6m57s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n test
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
sleep     ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
{{< /text >}}

在以下命令中，将 `httpbin-5bbdbd6588-z9vbs` 替换为 httpbin Pod 的名称。

{{< text bash >}}
$ istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
{{< /text >}}

### 在 8080 端口上验证内部网格连通性 {#verify-internal-mesh-connectivity-on-port-8080}

{{< text bash >}}
$ export INTERNAL_CLIENT=$(kubectl -n test get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl -n test exec "${INTERNAL_CLIENT}" -c sleep -- curl -IsS "http://httpbin:8080/status/200"
HTTP/1.1 200 OK
server: envoy
date: Mon, 24 Oct 2022 09:04:52 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 5
{{< /text >}}

### 在 8443 端口上验证外部到内部网格的连通性 {#verify-external-to-internal-mesh-connectivity-on-port-8443}

要验证来自外部客户端的 mTLS 流量，首先将 CA 证书和客户端证书/密钥复制到在 default
命名空间中运行的 sleep 客户端。

{{< text bash >}}
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

现在证书可用于外部 sleep 客户端，您可以使用以下命令验证该客户端到内部 httpbin 服务的连通性。

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
server: istio-envoy
date: Mon, 24 Oct 2022 09:05:31 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 4
x-envoy-decorator-operation: ingress-sidecar.test:9080/*
{{< /text >}}

除了通过入口端口 8443 验证外部 mTLS 连通性之外，验证端口 8080 不接受任何外部 mTLS 流量也很重要。

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
{{< /text >}}

## 清理双向 TLS 终止示例 {#cleanup-the-mutual-tls-termination-example}

1.  移除创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret httpbin-mtls-termination httpbin-mtls-termination-cacert -n test
    $ kubectl delete service httpbin sleep -n test
    $ kubectl delete deployment httpbin sleep -n test
    $ kubectl delete namespace test
    $ kubectl delete service sleep
    $ kubectl delete deployment sleep
    {{< /text >}}

1.  删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr \
        client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
    {{< /text >}}

1.  将 Istio 从集群内卸载：

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
