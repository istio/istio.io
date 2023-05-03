---
title: 无 TLS 终止的 Ingress Gateway
description: 如何为一个 Ingress Gateway 配置 SNI 透传。
weight: 30
keywords: [traffic-management,ingress,https]
aliases:
  - /zh/docs/examples/advanced-gateways/ingress-sni-passthrough/
owner: istio/wg-networking-maintainers
test: yes
---

[安全网关](/zh/docs/tasks/traffic-management/ingress/secure-ingress/)说明了如何为 HTTP 服务配置 HTTPS 访问入口。而本示例将说明如何为 HTTPS 服务配置 HTTPS 访问入口，即配置 Ingress Gateway 以执行 SNI 透传，而不是对传入请求进行 TLS 终止。

本任务中的 HTTPS 示例服务是一个简单的 [NGINX](https://www.nginx.com) 服务。在接下来的步骤中，您首先在 Kubernetes 集群中创建一个 NGINX 服务。接着，通过网关给这个服务配置一个域名是 `nginx.example.com` 的访问入口。

{{< boilerplate gateway-api-support >}}

{{< boilerplate gateway-api-experimental >}}

## 准备工作 {#before-you-begin}

按照[安装指南](/zh/docs/setup/)部署 Istio。

## 生成客户端和服务端的证书和密钥{#generate-client-and-server-certificates-and-keys}

对于此任务，您可以使用自己喜欢的工具来生成证书和密钥。以下命令使用
[openssl](https://man.openbsd.org/openssl.1)：

1. 创建根证书和私钥来为您的服务签名证书：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1. 为 `nginx.example.com` 创建证书和私钥：

    {{< text bash >}}
    $ openssl req -out nginx.example.com.csr -newkey rsa:2048 -nodes -keyout nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in nginx.example.com.csr -out nginx.example.com.crt
    {{< /text >}}

## 部署一个 NGINX 服务{#deploy-an-nginx-server}

1. 创建一个 Kubernetes 的 [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/) 资源来保存服务的证书：

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com.key --cert nginx.example.com.crt
    {{< /text >}}

1. 为 NGINX 服务创建一个配置文件：

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

        server_name nginx.example.com;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
      }
    }
    EOF
    {{< /text >}}

1. 创建一个 Kubernetes 的 [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/) 资源来保存 NGINX 服务的配置：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1. 部署 NGINX 服务

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
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
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
    EOF
    {{< /text >}}

1. 要测试 NGINX 服务是否已成功部署，需要从其 Sidecar 代理发送请求，并忽略检查服务端的证书（使用 `curl` 的 `-k` 选项）。确保正确打印服务端的证书，即 `common name (CN)` 等于 `nginx.example.com`。

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name})" -c istio-proxy -- curl -sS -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
    ...
    SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
    ALPN, server accepted to use http/1.1
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: May 27 14:18:47 2020 GMT
      expire date: May 27 14:18:47 2021 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.

    > GET / HTTP/1.1
    > User-Agent: curl/7.58.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.17.10
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

## 配置 Ingress Gateway{#configure-an-ingress-gateway}

1. 定义一个 `server` 部分的端口为 443 的 `Gateway`。注意，`PASSTHROUGH tls` TLS 模式，该模式指示 Gateway 以 AS IS 方式传递入口流量，而不终止 TLS。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
        hosts:
        - nginx.example.com
    EOF
    {{< /text >}}

1. 为通过 `Gateway` 进入的流量配置路由：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: nginx
    spec:
      hosts:
      - nginx.example.com
      gateways:
      - mygateway
      tls:
      - match:
        - port: 443
          sniHosts:
          - nginx.example.com
        route:
        - destination:
            host: my-nginx
            port:
              number: 443
    EOF
    {{< /text >}}

1. 根据[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)中的指令来定义环境变量 `SECURE_INGRESS_PORT` 和 `INGRESS_HOST`。

1. 从集群外访问 NGINX 服务。注意，服务端返回了正确的证书，并且该证书已成功验证（输出了 _SSL certificate verify ok_）。

    {{< text bash >}}
    $ curl -v --resolve "nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" --cacert example.com.crt "https://nginx.example.com:$SECURE_INGRESS_PORT"
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify ok.

      < HTTP/1.1 200 OK
      < Server: nginx/1.15.2
      ...
      <html>
      <head>
      <title>Welcome to nginx!</title>
    {{< /text >}}

## 清除{#cleanup}

1. 删除已创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice nginx
    {{< /text >}}

1. 删除证书和密钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key nginx.example.com.crt nginx.example.com.key nginx.example.com.csr
    {{< /text >}}

1. 删除本示例中生成的配置文件：

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}
