---
title: 无 TLS 终止的 Ingress Gateway
description: 说明了如何为一个 ingress gateway 配置 SNI 直通。
weight: 30
keywords: [traffic-management,ingress,https]
aliases:
  - /zh/docs/examples/advanced-gateways/ingress-sni-passthrough/
---

[安全网关](/zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/)说明了如何为 HTTP 服务配置 HTTPS 访问入口。
而本示例将说明如何为 HTTPS 服务配置 HTTPS 访问入口，即配置 Ingress Gateway 以执行 SNI 直通，而不是对传入请求进行 TLS 终止。

本任务中的 HTTPS 示例服务是一个简单的 [NGINX](https://www.nginx.com) 服务。
在接下来的步骤中，你会先在你的 Kubernetes 集群中创建一个 NGINX 服务。
然后，通过网关给这个服务配置一个域名是 `nginx.example.com` 的访问入口。

## 生成客户端和服务端的证书和密钥{#generate-client-and-server-certificates-and-keys}

1. 克隆仓库 <https://github.com/nicholasjackson/mtls-go-example>:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1. 进入仓库的目录：

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1. 使用 password 为 `nginx.example.com` 生成证书：

    {{< text bash >}}
    $ ./generate.sh nginx.example.com <password>
    {{< /text >}}

    出现提示时，为所有问题选择 `y`。

1.  将证书移动到目录 `nginx.example.com`:

    {{< text bash >}}
    $ mkdir ../nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ../nginx.example.com
    {{< /text >}}

1.  回到根目录：

    {{< text bash >}}
    $ popd
    {{< /text >}}

## 部署一个 NGINX 服务{#deploy-an-nginx-server}

1.  创建一个 Kubernetes 的 [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) 资源来保存服务的证书：

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    {{< /text >}}

1.  为 NGINX 服务创建一个配置文件：

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

1.  创建一个 Kubernetes 的 [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) 资源来保存 NGINX 服务的配置：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  部署 NGINX 服务

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

1.  要测试 NGINX 服务是否已成功部署，需要从其 sidecar 代理发送请求，并忽略检查服务端的证书（使用 curl 的 -k 选项）。确保正确打印服务端的证书，即 `common name` 等于 `nginx.example.com`。

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

## 配置 ingress gateway{#configure-an-ingress-gateway}

1.  定义一个 `server` 部分的端口为 443 的 `Gateway`。 注意，`PASSTHROUGH tls mode` 指示 gateway 按原样通过入口流量，而不终止 TLS。

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

1.  配置通过 `Gateway` 进入的流量的路由：

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

1.  根据 [确定 ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports) 中的指令来定义环境变量  `SECURE_INGRESS_PORT` 和 `INGRESS_HOST`。

1.  从集群外访问 NGINX 服务。注意，服务端返回了正确的证书，并且该证书已成功验证（输出了 _SSL certificate verify ok_ ）。

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

## 清除{#cleanup}

1.  删除已创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice nginx
    {{< /text >}}

1.  删除含有证书的目录以及用于生成证书的仓库

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  删除本示例中生成的配置文件：

    {{< text bash >}}
    $ rm -f ./nginx.conf
    {{< /text >}}
