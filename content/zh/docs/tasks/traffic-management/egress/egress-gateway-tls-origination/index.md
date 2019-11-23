---
title: Egress 网关的 TLS 发起过程
description: 描述如何配置一个 Egress 网关，来向外部服务发起 TLS 连接。
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway-tls-origination/
---

[为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)
示例中演示了如何配置 Istio 以对外部服务流量实施 {{< gloss >}}TLS origination{{< /gloss >}}。
[配置 Egress Gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/)
示例中演示了如何配置 Istio 来通过专门的 egress 网关服务引导 egress 流量。
本示例兼容以上两者，描述如何配置 egress 网关，为外部服务流量发起 TLS 连接。

## 开始之前{#before-you-begin}

*   遵照[安装指南](/zh/docs/setup/)中的指令，安装 Istio。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 样本应用，作为外部请求的测试源。

    若已开启 [自动 sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，执行

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，必须在部署 `sleep` 应用之前手动注入 sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    注意每一个可以执行 `exec` 和 `curl` 操作的 pod，都需要注入。

*   创建一个 shell 变量，来保存向外部服务发送请求的源 pod 的名称。
    若使用 [sleep]({{< github_tree >}}/samples/sleep) 样例，运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

*   [部署 Istio egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-i-s-t-i-o-egress-gateway)。

*   [开启 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## 通过 egress 网关发起 TLS 连接{#perform-t-ls-origination-with-an-egress-gateway}

本节描述如何使用 egress 网关发起与示例[为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/) 中一样的 TLS。
注意，这种情况下，TLS 的发起过程由 egress 网关完成，而不是像之前示例演示的那样由 sidecar 完成。

1.  为 `edition.cnn.com` 定义一个 `ServiceEntry`：

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

1.  发送一个请求至 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)，验证 `ServiceEntry` 已被正确应用。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    如果在输出中看到 _301 Moved Permanently_，说明 `ServiceEntry` 配置正确。

1.  为 _edition.cnn.com_ 创建一个 egress `Gateway`， 端口 443，以及一个 sidecar 请求的目标规则，sidecar 请求被直接导向 egress 网关。

    根据需要开启源 pod 与 egress 网关之间的[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，选择相应的命令。

    {{< idea >}}
    若开启双向 TLS ，则源 pod 与 egress 网关之间的流量为加密状态。
    此外，双向 TLS 将允许 egress 网关监控源 pods 的身份，并开启 Mixer 基于该身份标识的强制策略实施。
    {{< /idea >}}

    {{< tabset cookie-name="mtls" >}}

    {{< tab name="mutual TLS enabled" cookie-value="enabled" >}}

    {{< text_hack bash >}}
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
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
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
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" cookie-value="disabled" >}}

    {{< text_hack bash >}}
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
          name: http-port-for-tls-origination
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  定义一个 `VirtualService` 来引导流量流经 egress 网关，以及一个 `DestinationRule` 为访问 `edition.cnn.com` 的请求发起 TLS 连接：

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

1.  发送一个 HTTP 请求至 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    {{< /text >}}

    输出将与在示例 [为 Egress 流量发起 TLS 连接](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/) 中显示的一样，发起 TLS 连接后，不再显示 _301 Moved Permanently_ 消息。

1.  检查 `istio-egressgateway` pod 的日志，将看到一行与请求相关的记录。
    若 Istio 部署在 `istio-system` 命名空间中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    将看到类似如下一行：

    {{< text plain>}}
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    {{< /text >}}

### 清除 TLS 启动实例{#cleanup-the-t-ls-origination-example}

删除创建的 Istio 配置项：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 通过 egress 网关发起双向 TLS 连接{#perform-mutual-t-ls-origination-with-an-egress-gateway}

与前一章节类似，本章节描述如何配置一个 egress 网关，为外部服务发起 TLS 连接，只是这次服务要求双向 TLS。

本示例要求更高的参与性，首先需要：

1. 生成客户端和服务器证书
1. 部署一个支持双向 TLS 的外部服务
1. 使用所需的证书重新部署 egress 网关

然后才可以配置出口流量流经 egress 网关，egress 网关将发起 TLS 连接。

### 生成客户端和服务器的证书与密钥{#generate-client-and-server-certificates-and-keys}

1.  克隆示例代码库 <https://github.com/nicholasjackson/mtls-go-example>：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  进入克隆的代码库目录：

    {{< text bash >}}
    $ cd mtls-go-example
    {{< /text >}}

1.  为 `nginx.example.com` 生成证书。
    使用任意 password 执行如下命令：

    {{< text bash >}}
    $ ./generate.sh nginx.example.com <password>
    {{< /text >}}

    所有出现的提示，均选择 `y`。

1.  将证书迁移至 `nginx.example.com` 目录：

    {{< text bash >}}
    $ mkdir ../nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ../nginx.example.com
    {{< /text >}}

1.  返回至上一级目录：

    {{< text bash >}}
    $ cd ..
    {{< /text >}}

### 部署一个双向 TLS 服务器{#deploy-a-mutual-t-ls-server}

为了模拟一个真实的支持双向 TLS 协议的外部服务，
在 Kubernetes 集群中部署一个 [NGINX](https://www.nginx.com) 服务器，该服务器运行在 Istio 服务网格之外，譬如：运行在一个没有开启 Istio sidecar proxy 注入的命名空间中。

1.  创建一个命名空间，表示 Istio 网格之外的服务， `mesh-external`。注意在这个命名空间中，sidecar 自动注入是没有[开启](/zh/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) 的，不会在 pods 中自动注入 sidecar proxy。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1.  创建 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) ，保存服务器和 CA 的证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  生成 NGINX 服务器的配置文件：

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

1.  生成 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) 保存 NGINX 服务器的配置文件：

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

1.  为 `nginx.example.com` 定义一个 `ServiceEntry` 和一个 `VirtualService`，指示 Istio 引导目标为 `nginx.example.com` 的流量流向 NGINX 服务器：

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

#### 部署一个容器测试 nginx 部署{#deploy-a-container-to-test-the-nginx-deployment}

1.  生成 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) ，保存客户端和 CA 的证书：

    {{< text bash >}}
    $ kubectl create secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  基于挂载的客户端和 CA 证书，部署 [sleep]({{< github_tree >}}/samples/sleep) 样本应用，测试发送请求至 NGINX 服务器：

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
    apiVersion: apps/v1
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

1.  定义一个环境变量保存 `sleep` pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1.  使用部署的 [sleep]({{< github_tree >}}/samples/sleep) pod 向 NGINX 服务器发送请求。
    由于 `nginx.example.com` 不是真实存在的，DNS 无法解析，后面的 `curl` 命令使用 `--resolve` 选项手动解析主机名。
    --resolve 选项传递的 IP 值（下方所示，1.1.1.1）没有意义。除 127.0.0.1 之外的任意值都可以使用。
    一般情况下，目标主机名对应着一个 DNS 项，无需使用 `curl` 的 `--resolve` 选项。

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

1.  验证服务器要求客户端的证书：

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

### 使用客户端证书重新部署 egress 网关{#redeploy-the-egress-gateway-with-the-client-certificates}

1. 生成 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) 保存客户端和 CA 的证书。

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create -n istio-system secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  部署 `istio-egressgateway` 挂载新生成的 secrets 的 volume。使用的参数选项与生成 `istio.yaml` 中的一致：

    {{< text bash >}}
    $ istioctl manifest generate --set values.gateways.istio-ingressgateway.enabled=false \
    --set values.gateways.istio-egressgateway.enabled=true \
    --set 'values.gateways.istio-egressgateway.secretVolumes[0].name'=egressgateway-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[0].secretName'=istio-egressgateway-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[0].mountPath'=/etc/istio/egressgateway-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[1].name'=egressgateway-ca-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[1].secretName'=istio-egressgateway-ca-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[1].mountPath'=/etc/istio/egressgateway-ca-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[2].name'=nginx-client-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[2].secretName'=nginx-client-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[2].mountPath'=/etc/nginx-client-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[3].name'=nginx-ca-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[3].secretName'=nginx-ca-certs \
    --set 'values.gateways.istio-egressgateway.secretVolumes[3].mountPath'=/etc/nginx-ca-certs > \
    ./istio-egressgateway.yaml
    {{< /text >}}

1.  重新部署 `istio-egressgateway`：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway.yaml
    deployment "istio-egressgateway" configured
    {{< /text >}}

1.  验证密钥和证书被成功装载入 `istio-egressgateway` pod：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/nginx-client-certs /etc/nginx-ca-certs
    {{< /text >}}

    `tls.crt` 与 `tls.key` 在 `/etc/istio/nginx-client-certs` 中， 而 `ca-chain.cert.pem` 在 `/etc/istio/nginx-ca-certs` 中。

### 为 egress 流量配置双向 TLS{#configure-mutual-t-ls-origination-for-egress-traffic}

1.  为 `nginx.example.com` 创建一个 egress `Gateway` 端口为 443，以及目标规则和虚拟服务来引导流量流经 egress 网关并从 egress 网关流向外部服务。

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

1.  定义一个 `VirtualService` 引导流量流经 egress 网关，一个 `DestinationRule` 发起双向 TLS 连接：

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

1.  发送一个 HTTP 请求至 `http://nginx.example.com`：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s --resolve nginx.example.com:80:1.1.1.1 http://nginx.example.com
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  检查 `istio-egressgateway` pod 日志，有一行与请求相关的日志记录。
    如果 Istio 部署在命名空间 `istio-system` 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'nginx.example.com' | grep HTTP
    {{< /text >}}

    将显示类似如下的一行：

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "nginx.example.com" "172.21.72.197:443"
    {{< /text >}}

### 清除双向 TLS 连接示例{#cleanup-the-mutual-t-ls-origination-example}

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

1.  删除用于生成证书和仓库的路径：

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  删除生成并应用于示例中的配置文件

    {{< text bash >}}
    $ rm -f ./nginx.conf ./istio-egressgateway.yaml
    {{< /text >}}

## 清除{#cleanup}

删除 `sleep` 服务和部署：

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
