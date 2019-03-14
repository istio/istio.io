---
title: 没有 TLS 的 Ingress gateway
description: 介绍如何为入口网关配置 SNI 直通。
weight: 10
keywords: [traffic-management,ingress,https]
---

[使用 HTTPS 保护网关](/zh/docs/tasks/traffic-management/secure-ingress/)任务描述了如何配置 HTTPS
入口访问 HTTP 服务。此示例介绍如何配置对 HTTPS 服务的入口访问，即配置 Ingress Gateway 以执行 SNI 直通，而不是终止 TLS 请求的传入。

用于此任务的示例 HTTPS 服务是一个简单的 [NGINX](https://www.nginx.com) 服务器。
在以下步骤中，首先在 Kubernetes 集群中部署 NGINX 服务。
然后配置网关以通过主机 `nginx.example.com` 提供对此服务的入口访问。

## 生成客户端和服务器证书和密钥

以与[使用 HTTPS 保护网关](/zh/docs/tasks/traffic-management/secure-ingress/sds/#generate-client-and-server-certificates-and-keys)任务相同的方式生成证书和密钥。

1.  克隆 <https://github.com/nicholasjackson/mtls-go-example> 存储库：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  将目录更改为克隆的存储库：

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1.  为 `nginx.example.com` 生成证书。使用以下命令的任何密码：

    {{< text bash >}}
    $ ./generate.sh nginx.example.com password
    {{< /text >}}

    遇见所有的问题请输入 `y` 来回答。

1.  将证书移动到 `nginx.example.com` 目录：

    {{< text bash >}}
    $ mkdir ~+1/nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/nginx.example.com
    {{< /text >}}

1.  返回根目录：

    {{< text bash >}}
    $ popd
    {{< /text >}}

## 部署 NGINX 服务器

1. 创建一个 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/)来保存服务器的证书。

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    {{< /text >}}

1.  为 NGINX 服务器创建配置文件：

    {{< text bash >}}
    $ cat <<EOF > ./nginx.conf
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

1.  创建 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
    保持 NGINX 服务器的配置：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  部署 NGINX 服务器：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

1.  要测试 NGINX 服务器是否已成功部署，请从其 sidecar 代理向服务器发送请求，
而不检查服务器的证书（使用 `curl` 的 `-k` 选项）。确保正确打印服务器的证书，
即 `common name` 等于 `nginx.example.com`。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
    ...
    SSL connection using TLS1.2 / ECDHE_RSA_AES_128_GCM_SHA256
      server certificate verification SKIPPED
      server certificate status verification SKIPPED
      common name: nginx.example.com (matched)
      server certificate expiration date OK
      server certificate activation date OK
      certificate public key: RSA
      certificate version: #3
      subject: C=US,ST=Denial,L=Springfield,O=Dis,CN=nginx.example.com
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: C=US,ST=Denial,O=Dis,CN=nginx.example.com

    > GET / HTTP/1.1
    > User-Agent: curl/7.35.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.15.2
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

## 配置 Ingress Gateway

1.  为端口 443 定义一个带有 `server` 部分的 `Gateway` 。注意 `PASSTHROUGH` `tls` `mode` 指示网关按原样传递入口流量，
而不终止 TLS。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # 使用 istio 默认的 ingress gateway
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

1.  配置通过 `Gateway` 进入的流量路由：

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
          sni_hosts:
          - nginx.example.com
        route:
        - destination:
            host: my-nginx
            port:
              number: 443
    EOF
    {{< /text >}}

1.  按照[确定入口IP和端口](/zh/docs/tasks/traffic-management/ingress/#确定入口-ip-和端口)中的说明定义 `SECURE_INGRESS_PORT` 和 `INGRESS_HOST` 环境变量。

1.  从群集外部访问 NGINX 服务。请注意，服务器返回正确的证书并成功验证（打印 _SSL certificate verify ok_ ）。

    {{< text bash >}}
    $ curl -v --resolve nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert nginx.example.com/2_intermediate/certs/ca-chain.cert.pem https://nginx.example.com:$SECURE_INGRESS_PORT
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=nginx.example.com
      start date: Aug 15 07:29:07 2018 GMT
      expire date: Aug 25 07:29:07 2019 GMT
      common name: nginx.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=nginx.example.com
      SSL certificate verify ok.

      < HTTP/1.1 200 OK
      < Server: nginx/1.15.2
      ...
      <html>
      <head>
      <title>Welcome to nginx!</title>
    {{< /text >}}

## 清理

1.  删除创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice nginx
    {{< /text >}}

1.  删除包含证书的目录和用于生成证书的存储库：

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  删除此示例中使用的生成的配置文件：

    {{< text bash >}}
    $ rm -f ./nginx.conf
    {{< /text >}}
