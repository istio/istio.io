---
title:  Egress Gateway 的双向 TLS。
description: 描述出口网关如何配置对外部服务发起双向 TLS。
weight: 45
keywords: [流量管理,egress]
---

[配置出口网关](/zh/docs/examples/advanced-gateways/egress-gateway)示例描述了如何配置 Istio 以通过名为 _egress gateway_ 的专用服务引导出口流量。
此示例展示如何配置出口网关以启用到外部服务的流量的双向 TLS。

要模拟支持 mutual TLS 协议的实际外部服务，首先在 Kubernetes 集群中部署 [NGINX](https://www.nginx.com) 服务器，但在 Istio 服务网格之外运行，即在命名空间中运行没有启用 Istio 的代理注入 sidecar 。
接下来，配置出口网关以与外部 NGINX 服务器执行双向 TLS。
最后，通过出口网关将流量从网格内的应用程序 pod 引导到网格外的 NGINX 服务器。

## 生成客户端和服务器证书和密钥

1.  克隆 <https://github.com/nicholasjackson/mtls-go-example> 存储库：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  进入克隆存储库的目录：

    {{< text bash >}}
    $ cd mtls-go-example
    {{< /text >}}

1.  为 `nginx.example.com` 生成证书。
    使用以下命令（密码任意指定）：

    {{< text bash >}}
    $ ./generate.sh nginx.example.com <password>
    {{< /text >}}

    为所有出现的提示选择 `y`。

1.  将证书移动到 `nginx.example.com` 目录：

    {{< text bash >}}
    $ mkdir ../nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ../nginx.example.com
    {{< /text >}}

1.  返回上级目录：

    {{< text bash >}}
    $ cd ..
    {{< /text >}}

## 部署 NGINX 服务器

1.  创建一个命名空间来表示 Istio 网格之外的服务，即 `mesh-external`。请注意，由于自动注入 sidecar 没有[启用](/zh/docs/setup/kubernetes/sidecar-injection/#应用部署)，因此 sidecar 代理不会自动注入此命名空间中的 pod。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. 创建 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) 用来保存服务器端证书和 CA 证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
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
        ssl_client_certificate /etc/nginx-ca-certs/ca-chain.cert.pem;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) 用来保存 NGINX 服务器的配置：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  部署 NGINX 服务器：

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

1.  为 `nginx.example.com` 定义一个 `ServiceEntry` 和 `VirtualService`，用来指示 Istio 将指向 `nginx.example.com` 的流量定向到你的 NGINX 服务器：

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

## 部署容器以测试 NGINX 部署

1.  创建 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) 来保存客户端证书和 CA 证书：

    {{< text bash >}}
    $ kubectl create secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  使用已安装的客户端和 CA 证书部署 [sleep]({{< github_tree >}}/samples/sleep) 示例，以测试向 NGINX 服务器发送请求：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    # Copyright 2017 Istio Authors
    #
    #   Licensed under the Apache License, Version 2.0 (the "License");
    #   you may not use this file except in compliance with the License.
    #   You may obtain a copy of the License at
    #
    #       http://www.apache.org/licenses/LICENSE-2.0
    #
    #   Unless required by applicable law or agreed to in writing, software
    #   distributed under the License is distributed on an "AS IS" BASIS,
    #   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #   See the License for the specific language governing permissions and
    #   limitations under the License.

    ##################################################################################################
    # Sleep service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: sleep
      labels:
        app: sleep
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: sleep
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: tutum/curl
            command: ["/bin/sleep","infinity"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: nginx-client-certs
              mountPath: /etc/nginx-client-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-client-certs
            secret:
              secretName: nginx-client-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

1.  定义一个环境变量来保存 `sleep` pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1.  使用部署的 [sleep]({{< github_tree >}}/samples/sleep) pod 将请求发送到 NGINX 服务器。
    由于 `nginx.example.com` 实际上并不存在，因此 DNS 无法解析它，以下 `curl` 命令使用 `--resolve` 选项手动解析主机名。在 --resolve 选项（下面的1.1.1.1）中传递的 IP 值并不重要。可以使用 127.0.0.1 以外的任何值。
    通常，目标主机名存在 DNS 条目，您不会使用 `curl` 的 `--resolve` 选项。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -v --resolve nginx.example.com:443:1.1.1.1 --cacert /etc/nginx-ca-certs/ca-chain.cert.pem --cert /etc/nginx-client-certs/tls.crt --key /etc/nginx-client-certs/tls.key https://nginx.example.com
    ...
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=nginx.example.com
      start date: 2018-08-16 04:31:20 GMT
      expire date: 2019-08-26 04:31:20 GMT
      common name: nginx.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=nginx.example.com
      SSL certificate verify ok.
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

1.  验证服务器是否需要客户端证书：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -k --resolve nginx.example.com:443:1.1.1.1 https://nginx.example.com
    <html>
    <head><title>400 No required SSL certificate was sent</title></head>
    <body bgcolor="white">
    <center><h1>400 Bad Request</h1></center>
    <center>No required SSL certificate was sent</center>
    <hr><center>nginx/1.15.2</center>
    </body>
    </html>
    {{< /text >}}

## 使用客户端证书重新部署 Egress 网关

1. 创建 Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) 以保存客户端证书和 CA 证书。

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create -n istio-system secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  生成 `istio-egressgateway` deployment，其中包含要从新 Secret 安装的 volume。用生成 `istio.yaml` 相同的选项：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio-egressgateway --namespace istio-system -x charts/gateways/templates/deployment.yaml --set gateways.istio-ingressgateway.enabled=false \
    --set gateways.istio-egressgateway.secretVolumes[0].name=egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[0].secretName=istio-egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[0].mountPath=/etc/istio/egressgateway-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].name=egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].secretName=istio-egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[1].mountPath=/etc/istio/egressgateway-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].name=nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].secretName=nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[2].mountPath=/etc/nginx-client-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].name=nginx-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].secretName=nginx-ca-certs \
    --set gateways.istio-egressgateway.secretVolumes[3].mountPath=/etc/nginx-ca-certs > \
    ./istio-egressgateway.yaml
    {{< /text >}}

1.  重新部署 `istio-egressgateway`：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway.yaml
    deployment "istio-egressgateway" configured
    {{< /text >}}

1.  验证密钥和证书是否已成功加载到 `istio-egressgateway` pod 中：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/nginx-client-certs /etc/nginx-ca-certs
    {{< /text >}}

    `/etc/istio/nginx-client-certs` 中应该存在 `tls.crt` 和 `tls.key`，而 `/etc/istio/nginx-ca-certs` 中应该存在 `ca-chain.cert.pem` 。

## 为出口流量配置双向 TLS

1.  给 `nginx.example.com` 在 443 端口上创建出口 `Gateway`，以及目的地规则和虚拟服务，以通过出口网关和出口网关将流量引导到外部服务。

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
        - nginx.example.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
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
              sni: nginx.example.com
    EOF
    {{< /text >}}

1.  定义一个 `VirtualService` 来引导流量通过出口网关，一个 `DestinationRule` 来执行双向的 TLS 的发起：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-nginx-through-egress-gateway
    spec:
      hosts:
      - nginx.example.com
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
            host: nginx.example.com
            port:
              number: 443
          weight: 100
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-mtls-for-nginx
    spec:
      host: nginx.example.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: MUTUAL
            clientCertificate: /etc/nginx-client-certs/tls.crt
            privateKey: /etc/nginx-client-certs/tls.key
            caCertificates: /etc/nginx-ca-certs/ca-chain.cert.pem
            sni: nginx.example.com
    EOF
    {{< /text >}}

1.  发送 HTTP 请求到 `http://nginx.example.com`：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s --resolve nginx.example.com:80:1.1.1.1 http://nginx.example.com
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  检查 `istio-egressgateway` pod 的日志，看看与我们的请求相对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'nginx.example.com' | grep HTTP
    {{< /text >}}

    您应该看到与您的请求相关的行，类似于以下内容：

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "nginx.example.com" "172.21.72.197:443"
    {{< /text >}}

## 清理

1.  按照[配置出口网关](/zh/docs/examples/advanced-gateways/egress-gateway)示例的[清理](/zh/docs/examples/advanced-gateways/egress-gateway/#清理)部分中的说明执行。

1.  删除创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret nginx-client-certs nginx-ca-certs
    $ kubectl delete secret nginx-client-certs nginx-ca-certs -n istio-system
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete gateway istio-egressgateway
    $ kubectl delete serviceentry nginx
    $ kubectl delete virtualservice direct-nginx-through-egress-gateway
    $ kubectl delete destinationrule originate-mtls-for-nginx
    $ kubectl delete destinationrule egressgateway-for-nginx
    {{< /text >}}

1.  删除证书的目录和用于生成它们的存储库：

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  删除此示例中使用的生成的配置文件：

    {{< text bash >}}
    $ rm -f ./nginx.conf ./istio-egressgateway.yaml
    {{< /text >}}

1.  删除 `sleep` service 和 deployment：

    {{< text bash >}}
    $ kubectl delete service sleep
    $ kubectl delete deployment sleep
    {{< /text >}}
