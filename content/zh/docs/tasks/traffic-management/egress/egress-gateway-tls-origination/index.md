---
title: Egress 网关的 TLS 发起过程
description: 描述如何配置一个 Egress 网关，来向外部服务发起 TLS 连接。
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway-tls-origination/
  - /zh/docs/examples/advanced-gateways/egress-gateway-tls-origination-sds/
  - /zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination-sds/
owner: istio/wg-networking-maintainers
test: yes
---

[为出口流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)
示例中演示了如何配置 Istio 以对外部服务流量实施 {{< gloss >}}TLS origination{{< /gloss >}}。
[配置 Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/)示例中演示了如何配置
Istio 来通过专门的 Egress 网关服务引导出口流量。
本示例兼容以上两者，描述如何配置 Egress 网关，为外部服务流量发起 TLS 连接。

{{< boilerplate gateway-api-support >}}

## 开始之前{#before-you-begin}

* 遵照[安装指南](/zh/docs/setup/)中的指令，安装 Istio。

* 启动 [curl]({{< github_tree >}}/samples/curl) 样本应用，作为外部请求的测试源。

    若已开启[自动 Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，执行

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    否则，必须在部署 `curl` 应用之前手动注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    注意每一个可以执行 `exec` 和 `curl` 操作的 Pod，都需要注入。

* 创建一个 shell 变量，来保存向外部服务发送请求的源 Pod 的名称。
    若使用 [curl]({{< github_tree >}}/samples/curl) 样例，运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

* 对于 macOS 用户，确认您使用的是 `openssl` 版本 1.1 或更高版本：

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g  21 Apr 2020
    {{< /text >}}

    如果前面的命令输出的是版本 `1.1` 或更高版本，如图所示，则您的 `openssl`
    命令应该正确执行此任务中的指示。否则，升级您的 `openssl` 或尝试 `openssl`
    的不同实现，像在 Linux 机器上一样。

* [开启 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)，
    如果尚未启用。例如，使用 `istioctl`：

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

*   如果您不使用 `Gateway API` 指令，
    请确保[部署 Istio Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway)。

## 通过 Egress 网关发起 TLS 连接 {#perform-TLS-origination-with-an-egress-gateway}

本节描述如何使用 Egress 网关发起与示例[为出口流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)中一样的
TLS。注意，这种情况下，TLS 的发起过程由 Egress 网关完成，而不是像之前示例演示的那样由
Sidecar 完成。

1. 为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1. 发送一个请求至 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)，
   验证 `ServiceEntry` 已被正确应用。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    如果在输出中看到 `301 Moved Permanently`，说明 `ServiceEntry` 配置正确。

1. 为 `edition.cnn.com` 创建一个 Egress `Gateway`，端口 443，以及一个 Sidecar
   请求的目标规则，Sidecar 请求被直接导向 Egress 网关。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: https-port-for-tls-origination
      protocol: HTTPS
    hosts:
    - edition.cnn.com
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 80
        tls:
          mode: ISTIO_MUTUAL
          sni: edition.cnn.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https-listener-for-tls-origination
    hostname: edition.cnn.com
    port: 80
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: cnn-egress-gateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: ISTIO_MUTUAL
        sni: edition.cnn.com
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) 配置路由规则以引导流量通过 Egress 网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  定义一个 `DestinationRule` 来为 `edition.cnn.com` 的请求执行 TLS 发起：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
    EOF
    {{< /text >}}

6)  发送一个 HTTP 请求至 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    输出将与在示例[为出口流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)中显示的一样，发起 TLS 连接后，不再显示 _301 Moved Permanently_ 消息。

7)  检查 Egress 网关代理的日志。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令为：

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

您应该看到一行类似于以下的内容：

{{< text plain>}}
[2020-06-30T16:17:56.763Z] "GET /politics HTTP/2" 200 - "-" "-" 0 1295938 529 89 "10.244.0.171" "curl/7.64.0" "cf76518d-3209-9ab7-a1d0-e6002728ef5b" "edition.cnn.com" "151.101.129.67:443" outbound|443||edition.cnn.com 10.244.0.170:54280 10.244.0.170:8080 10.244.0.171:35628 - -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用 Istio 生成的 Pod 标签访问 Egress 网关对应的日志：

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

您应该看到一行类似于以下的内容：

{{< text plain >}}
[2024-03-14T18:37:01.451Z] "GET /politics HTTP/1.1" 200 - via_upstream - "-" 0 2484998 59 37 "172.30.239.26" "curl/7.87.0-DEV" "b80c8732-8b10-4916-9a73-c3e1c848ed1e" "edition.cnn.com" "151.101.131.5:443" outbound|443||edition.cnn.com 172.30.239.33:51270 172.30.239.33:80 172.30.239.26:35192 edition.cnn.com default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清除 TLS 启动实例 {#cleanup-the-TLS-origination-example}

删除创建的 Istio 配置项：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gw istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 通过 Egress 网关发起双向 TLS 连接 {#perform-mutual-TLS-origination-with-an-egress-gateway}

与前一章节类似，本章节描述如何配置一个 Egress 网关，为外部服务发起 TLS 连接，
只是这次服务要求双向 TLS。

本示例要求更高的参与性，首先需要：

1. 生成客户端和服务器证书
1. 部署一个支持双向 TLS 的外部服务
1. 使用所需的证书重新部署 Egress 网关

然后才可以配置出口流量流经 Egress 网关，Egress 网关将发起 TLS 连接。

### 生成客户端和服务器的证书与密钥 {#generate-client-and-server-certificates-and-keys}

对于此任务，您可以使用自己喜欢的工具来生成证书和密钥。以下命令使用
[openssl](https://man.openbsd.org/openssl.1)。

1. 为您的服务签名证书创建根证书和私钥：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1. 为 `my-nginx.mesh-external.svc.cluster.local` 创建证书和私钥：

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    或者，如果您想要为目标启用 SAN 验证，您可以将 `SubjectAltNames` 添加到证书中。例如：

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1. 生成客户端证书和私钥：

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### 部署一个双向 TLS 服务器 {#deploy-a-mutual-TLS-server}

为了模拟一个真实的支持双向 TLS 协议的外部服务，在 Kubernetes 集群中部署一个
[NGINX](https://www.nginx.com) 服务器，
该服务器运行在 Istio 服务网格之外，譬如：运行在一个没有开启 Istio Sidecar proxy
注入的命名空间中。

1. 创建一个命名空间，表示 Istio 网格之外的服务，`mesh-external`。
   注意在这个命名空间中，Sidecar 自动注入是没有[开启](/zh/docs/setup/additional-setup/sidecar-injection/#deploying-an-app)的，
   不会在 Pod 中自动注入 Sidecar 代理。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. 创建 Kubernetes [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)，
   保存服务器和 CA 的证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1. 生成 NGINX 服务器的配置文件：

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1. 生成 Kubernetes [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/)
   保存 NGINX 服务器的配置文件：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1. 部署 NGINX 服务器：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

1. 为 `nginx.example.com` 定义一个 `ServiceEntry` 和一个 `VirtualService`，
   指示 Istio 引导目标为 `nginx.example.com` 的流量流向 NGINX 服务器：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: nginx
    spec:
      hosts:
      - nginx.example.com
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      endpoints:
      - address: my-nginx.mesh-external.svc.cluster.local
        ports:
          https: 443
    ---
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: nginx
    spec:
      hosts:
      - nginx.example.com
      tls:
      - match:
        - port: 443
          sni_hosts:
          - nginx.example.com
        route:
        - destination:
            host: nginx.example.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

### 为出口流量配置双向 TLS {#configure-mutual-TLS-origination-for-egress-traffic}

1)  在部署 Egress 网关的**同一命名空间**中创建一个
    Kubernetes [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)，
    以保存客户端的证书：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

为了支持与各种工具的集成，Istio 支持几种不同的 Secret 格式。
在此示例中，使用具有关键字 `tls.key`、`tls.crt` 和 `ca.crt` 的通用 Secret。

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl create secret -n default generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

为了支持与各种工具的集成，Istio 支持几种不同的 Secret 格式。
在此示例中，使用具有关键字 `tls.key`、`tls.crt` 和 `ca.crt` 的通用 Secret。

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

2)  为 `my-nginx.mesh-external.svc.cluster.local`、端口 443 创建 Egress `Gateway`，
    并为将定向到 Egress 网关的 Sidecar 请求创建目标规则：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - my-nginx.mesh-external.svc.cluster.local
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: nginx
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: ISTIO_MUTUAL
          sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-egressgateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: my-nginx.mesh-external.svc.cluster.local
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nginx-egressgateway-istio-sds
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - watch
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nginx-egressgateway-istio-sds
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-egressgateway-istio-sds
subjects:
- kind: ServiceAccount
  name: nginx-egressgateway-istio
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: nginx-egressgateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: ISTIO_MUTUAL
        sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  配置路由规则以引导流量通过 Egress 网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-through-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: nginx
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
    route:
    - destination:
        host: my-nginx.mesh-external.svc.cluster.local
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-to-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  gateways:
  - mesh
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: nginx-egressgateway-istio.default.svc.cluster.local
        port:
          number: 443
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-nginx-from-egress-gateway
spec:
  parentRefs:
  - name: nginx-egressgateway
  hostnames:
  - my-nginx.mesh-external.svc.cluster.local
  rules:
  - backendRefs:
    - name: my-nginx
      namespace: mesh-external
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: my-nginx-reference-grant
  namespace: mesh-external
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: default
  to:
    - group: ""
      kind: Service
      name: my-nginx
EOF
{{< /text >}}

TODO：弄清楚为什么使用 `HTTPRoute` 而不是上面不起作用的 `VirtualService`。
它完全忽略 `HTTPRoute` 并尝试传递到目标服务，但超时。
与上面的 `VirtualService` 唯一的区别是生成的 `VirtualService`
包含注解：`internal.istio.io/route-semantics": "gateway"`。

{{< /tab >}}

{{< /tabset >}}

4)  添加 `DestinationRule` 来执行双向 TLS 发起：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # 这必须与之前创建的用于保存客户端证书的 Secret 相匹配
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # 如果证书是随着上一节中指定的 SAN 生成的，则可以被启用
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # 这必须与之前创建的用于保存客户端证书的 Secret 相匹配
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # 如果证书是随着上一节中指定的 SAN 生成的，则可以被启用
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  验证凭证是否已提供给 Egress 网关并且处于活动状态：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl -n istio-system proxy-config secret deploy/istio-egressgateway | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl proxy-config secret deploy/nginx-egressgateway-istio | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  发送一个 HTTP 请求到 `http://my-nginx.mesh-external.svc.cluster.local`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

7)  检查 Egress 网关代理的日志：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

You should see a line similar to the following:

{{< text plain>}}
[2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用 Istio 生成的 Pod 标签访问 Egress 网关对应的日志：

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=nginx-egressgateway | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

您应该看到一行类似于以下的内容：

{{< text plain >}}
[2024-04-08T20:08:18.451Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 5 5 "172.30.239.41" "curl/7.87.0-DEV" "86e54df0-6dc3-46b3-a8b8-139474c32a4d" "my-nginx.mesh-external.svc.cluster.local" "172.30.239.57:443" outbound|443||my-nginx.mesh-external.svc.cluster.local 172.30.239.53:48530 172.30.239.53:443 172.30.239.41:53694 my-nginx.mesh-external.svc.cluster.local default.forward-nginx-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清除双向 TLS 连接示例 {#cleanup-the-mutual-TLS-origination-example}

1.  删除 NGINX 双向 TLS 服务器资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  删除网关配置资源：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete secret client-credential -n istio-system
$ kubectl delete gw istio-egressgateway
$ kubectl delete virtualservice direct-nginx-through-egress-gateway
$ kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete secret client-credential
$ kubectl delete gtw nginx-egressgateway
$ kubectl delete role nginx-egressgateway-istio-sds
$ kubectl delete rolebinding nginx-egressgateway-istio-sds
$ kubectl delete virtualservice direct-nginx-to-egress-gateway
$ kubectl delete httproute forward-nginx-from-egress-gateway
$ kubectl delete destinationrule originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
$ kubectl delete referencegrant my-nginx-reference-grant -n mesh-external
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

4)  删除生成并应用于示例中的配置文件

    {{< text bash >}}
    $ rm ./nginx.conf
    $ rm ./gateway-patch.json
    {{< /text >}}

## 清除 {#cleanup}

删除 `curl` 的 Service 和 Deployment：

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
