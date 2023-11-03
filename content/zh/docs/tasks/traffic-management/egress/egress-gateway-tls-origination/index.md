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

[为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)
示例中演示了如何配置 Istio 以对外部服务流量实施 {{< gloss >}}TLS origination{{< /gloss >}}。
[配置 Egress Gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/)
示例中演示了如何配置 Istio 来通过专门的 egress 网关服务引导 egress 流量。
本示例兼容以上两者，描述如何配置 egress 网关，为外部服务流量发起 TLS 连接。

## 开始之前{#before-you-begin}

* 遵照[安装指南](/zh/docs/setup/)中的指令，安装 Istio。

* 启动 [sleep]({{< github_tree >}}/samples/sleep) 样本应用，作为外部请求的测试源。

    若已开启[自动 Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，执行

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，必须在部署 `sleep` 应用之前手动注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    注意每一个可以执行 `exec` 和 `curl` 操作的 Pod，都需要注入。

* 创建一个 shell 变量，来保存向外部服务发送请求的源 Pod 的名称。
    若使用 [sleep]({{< github_tree >}}/samples/sleep) 样例，运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

* 对于 macOS 用户，确认您使用的是 `openssl` 版本 1.1 或更高版本：

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g  21 Apr 2020
    {{< /text >}}

    如果前面的命令输出的是版本 `1.1` 或更高版本，如图所示，则您的 `openssl`
    命令应该正确执行此任务中的指示。否则，升级您的 `openssl` 或尝试 `openssl`
    的不同实现，像在 Linux 机器上一样。

* [部署 Istio egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway)。

* [开启 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## 通过 egress 网关发起 TLS 连接 {#perform-TLS-origination-with-an-egress-gateway}

本节描述如何使用 egress 网关发起与示例[为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)中一样的
TLS。注意，这种情况下，TLS 的发起过程由 egress 网关完成，而不是像之前示例演示的那样由
Sidecar 完成。

1. 为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    如果在输出中看到 `301 Moved Permanently`，说明 `ServiceEntry` 配置正确。

1. 为 `edition.cnn.com` 创建一个 egress `Gateway`，端口 443，以及一个 Sidecar
   请求的目标规则，Sidecar 请求被直接导向 egress 网关。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    apiVersion: networking.istio.io/v1alpha3
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

1. 定义一个 `VirtualService` 来引导流量流经 egress 网关，
   以及一个 `DestinationRule` 为访问 `edition.cnn.com`
   的请求发起 TLS 连接：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    ---
    apiVersion: networking.istio.io/v1alpha3
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

1. 发送一个 HTTP 请求至 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    输出将与在示例[为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)中显示的一样，发起 TLS 连接后，不再显示 _301 Moved Permanently_ 消息。

1. 检查 `istio-egressgateway` Pod 的日志，将看到一行与请求相关的记录。
    若 Istio 部署在 `istio-system` 命名空间中，可以通过下面的命令打印日志：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    将看到类似如下一行的输出：

    {{< text plain>}}
    [2020-06-30T16:17:56.763Z] "GET /politics HTTP/2" 200 - "-" "-" 0 1295938 529 89 "10.244.0.171" "curl/7.64.0" "cf76518d-3209-9ab7-a1d0-e6002728ef5b" "edition.cnn.com" "151.101.129.67:443" outbound|443||edition.cnn.com 10.244.0.170:54280 10.244.0.170:8080 10.244.0.171:35628 - -
    {{< /text >}}

### 清除 TLS 启动实例 {#cleanup-the-TLS-origination-example}

删除创建的 Istio 配置项：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 通过 egress 网关发起双向 TLS 连接 {#perform-mutual-TLS-origination-with-an-egress-gateway}

与前一章节类似，本章节描述如何配置一个 egress 网关，为外部服务发起 TLS 连接，
只是这次服务要求双向 TLS。

本示例要求更高的参与性，首先需要：

1. 生成客户端和服务器证书
1. 部署一个支持双向 TLS 的外部服务
1. 使用所需的证书重新部署 egress 网关

然后才可以配置出口流量流经 egress 网关，egress 网关将发起 TLS 连接。

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
   不会在 Pod 中自动注入 Sidecar proxy。

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
    apiVersion: networking.istio.io/v1alpha3
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
    apiVersion: networking.istio.io/v1alpha3
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

### 为 egress 流量配置双向 TLS {#configure-mutual-TLS-origination-for-egress-traffic}

1. 创建 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
   保存客户端证书：

    {{< text bash >}}
    $ kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

   Secret 所在的命名空间**必须**与出口网关部署的位置一只，在本例中为 `istio-system` 命名空间。

   为了支持与各种工具的集成，Istio 支持多种 Secret 格式。

   在本例中，使用了一个具有关键字 `tls.key`、`tls.crt` 和 `ca.crt` 的通用 Secret。

1. 为 `my-nginx.mesh-external.svc.cluster.local` 创建一个 egress `Gateway`
   端口为 443，以及目标规则和虚拟服务来引导流量流经 egress 网关并从 egress
   网关流向外部服务。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    apiVersion: networking.istio.io/v1alpha3
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

1. 定义一个 `VirtualService` 引导流量流经 egress 网关：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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

1.  添加 `DestinationRule` 执行双向 TLS

    {{< text bash >}}
    $ kubectl apply -n istio-system -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    EOF
    {{< /text >}}

1. 发送一个 HTTP 请求至 `http://my-nginx.mesh-external.svc.cluster.local`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1. 检查 `istio-egressgateway` Pod 日志，有一行与请求相关的日志记录。
    如果 Istio 部署在命名空间 `istio-system` 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
    {{< /text >}}

    将显示类似如下的一行：

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
    {{< /text >}}

### 清除双向 TLS 连接示例 {#cleanup-the-mutual-TLS-origination-example}

1. 删除创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret client-credential -n istio-system
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete gateway istio-egressgateway
    $ kubectl delete virtualservice direct-nginx-through-egress-gateway
    $ kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
    $ kubectl delete destinationrule egressgateway-for-nginx
    {{< /text >}}

1. 删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1. 删除生成并应用于示例中的配置文件

    {{< text bash >}}
    $ rm ./nginx.conf
    $ rm ./gateway-patch.json
    {{< /text >}}

## 清除 {#cleanup}

删除 `sleep` 的 Service 和 Deployment：

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
