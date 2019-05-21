---
title: Egress 网关的 TLS 发起过程
description: 描述了配置 Egress 网关来发起对外部服务进行 TLS 通信的过程。
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway-tls-origination/
---

[Egress 流量 TLS 示例](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/)中展示了如何配置 Istio 来[发起 TLS](/zh/docs/reference/glossary/)，用于和外部进行通信。[配置 Egress 网关](/zh/docs/tasks/traffic-management/edge-traffic/egress-gateway/)示例中展示了如何使用独立的 **egress 网关服务**来对 Egress 流量进行转发。这个例子中结合了前面的两个，描述了如何配置 Egress 网关，来发起对外的 TLS 访问。

## 开始之前 {#before-you-begin}

* 依照[安装指南](/zh/docs/setup/)的介绍，部署 Istio。

* 启动 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，这一应用将作为后续步骤中的测试工具，用于发起对外连接。

    如果启用了 [Sidecar 的自动注入功能](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入)，使用下面的命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则就只能用手工注入的方式来部署 `sleep` 应用了：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    记录一下 Pod 名称，后面的步骤中会使用 `exec` 进入 Pod 执行 `curl` 命令。

* 创建一个环境变量，保存用于向外部服务发送流量的 Pod 名称。

    如果使用的是 [sleep]({{<github_tree>}}/samples/sleep) 应用，运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

* [部署 Istio egress 网关](/docs/tasks/traffic-management/edge-traffic/egress-gateway/#deploy-istio-egress-gateway)

## 使用 Egress 网关发起 TLS

本节描述了如何执行和[在 Egress 流量中发起 TLS](/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 示例中一样的过程，只不过这次使用的是 Egress 网关，而不是 Sidecar。

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

1. 发送请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)，确认一下新建的 `ServiceEntry` 已经正常工作。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    如果输出内容中看到了 `301 Moved Permanently`，表示 `ServiceEntry` 已经成功配置。

1. 为 `edition.cnn.com` 创建一个 Egress 网关，端口为 `443`，然后创建一个 `DestinationRule`，将 Sidecar 的请求重定向到 Egress 网关。

    {{< idea >}}
    你可能会想启用双向 TLS，这样源 Pod 和 Egress 网关之间的流量就会被加密了。另外双向 TLS 启用之后，Egress 网关就能够监控到源 Pod 的身份，并根据这一身份执行 Mixer 策略了。
    {{< /idea >}}

    {{< tabset cookie-name="mtls" >}}

    {{< tab name="启用双向 TLS" cookie-value="enabled" >}}

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
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="禁用双向 TLS" cookie-value="disabled" >}}

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
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 定义一个 `VirtualService` 把流量传递给 Egress 网关，然后创建一个 `DestinationRule` 来为发往 `edition.cnn.com` 的流量发起 TLS：

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

1. 发送请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    {{< /text >}}

    输出内容应该和[出口流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 一文中的描述一致，消除了 `301 Moved Permanently` 消息。

1. 检查 `istio-egressgateway` Pod 的日志，会看到跟我们请求相关的内容。
    如果 Istio 部署在 `istio-system` 命名空间，输出日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    应该会看到类似的内容：

    {{< text plain>}}
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    {{< /text >}}

### 清理 TLS 发起示例的内容  {#cleanup-origination-example}

删除前面创建的配置对象：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 使用 Egress 网关执行双向 TLS 的发起

和前面一节内容类似，这一节中讲述的是配置一个 Egress 网关来为外部服务进行 TLS 发起，不同的是，这次发起的是双向 TLS。

这个例子相对复杂一些，需要一些特定的准备工作：

1. 生成客户端和服务端证书。
1. 部署一个支持双向 TLS 的外部服务。
1. 重新部署包含双向 TLS 证书的 Egress 网关。

然后就可以配置外发流量，通过 Egress 网关来执行 TLS 的发起。

### 生成客户端和服务端的证书及私钥 {#generate-client-and-server-certificates-and-keys}

1. 克隆 <https://github.com/nicholasjackson/mtls-go-example> 仓库：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1. 进入源码目录：

    {{< text bash >}}
    $ cd mtls-go-example
    {{< /text >}}

1. 为 `nginx.example.com` 生成证书，注意用密码替换下面的 `password`：

    {{< text bash >}}
    $ ./generate.sh nginx.example.com password
    {{< /text >}}

    所有提示都输入 `y`。

1. 把证书移动到 `nginx.example.com` 目录：

    {{< text bash >}}
    $ mkdir ../nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ../nginx.example.com
    {{< /text >}}

1. 回到前面的目录：

    {{< text bash >}}
    $ cd ..
    {{< /text >}}

### 部署一个双向 TLS 服务器 {#deploy-a-mutual-server}

要模拟一个支持双向 TLS 协议的外部服务，可以在 Kubernetes 集群上部署一个 [NGINX](https://www.nginx.com)，但这个服务要排除在服务网格之外，例如部署到一个没有进行 Istio 自动注入的命名空间里。

1. 创建一个 Istio 服务网格范围之外的命名空间，命名为 `mesh-external`。注意不要在这个命名空间里[启用自动注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#应用部署)。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. 创建一个 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)，用于保存服务和 CA 的证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1. 为 NGINX 服务器创建一个配置文件：

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

1. 创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)，用于保存 NGINX 服务器的配置：

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

1. 为 `nginx.example.com` 定义一个 `ServiceEntry` 和 `VirtualService`，让 Istio 把流向 `nginx.example.com` 的流量转发到你的 NGINX 服务器：

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

#### 部署一个容器来测试 NGINX Deployment {#deploy-a-container-to-test-the-nginx-deployment}

1. 创建 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) 来保存客户端和 CA 的证书：

    {{< text bash >}}
    $ kubectl create secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1. 部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，加载客户端和 CA 证书，用于测试向 NGINX 服务器发送流量：

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

1. 定义一个环境变量来保存 `sleep` Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. 使用 [sleep]({{< github_tree >}}/samples/sleep) Pod 向 NGINX 服务器发送流量。
    因为 `nginx.example.com` 并不存在，DNS 也无法解析，所以在 `curl` 命令中使用了 `--resolve` 参数来手工完成解析。传递给 `--resolve` 的 IP（1.1.1.1）无关紧要，只要不是 127.0.0.1 即可。而正常情况下，目标主机的解析是靠 DNS 完成的，就无需这种参数了。

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

1. 检查服务器，看它是不是需要客户端证书：

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

### 重新部署带有客户端证书的 Egress 网关 {#redeploy-the-egress-gateway-with-the- client-certificates}

1. 创建 Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) 来保存客户端和 CA 证书：

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create -n istio-system secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1. 生成 `istio-egressgateway`，加载新的 Secret，参数和生成 `istio.yaml` 时候一致：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio --namespace istio-system -x charts/gateways/templates/deployment.yaml --set gateways.istio-ingressgateway.enabled=false \
    --set gateways.istio-egressgateway.enabled=true \
    --set 'gateways.istio-egressgateway.secretVolumes[0].name'=egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[0].secretName'=istio-egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[0].mountPath'=/etc/istio/egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].name'=egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].secretName'=istio-egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].mountPath'=/etc/istio/egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].name'=nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].secretName'=nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].mountPath'=/etc/nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].name'=nginx-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].secretName'=nginx-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].mountPath'=/etc/nginx-ca-certs > \
    ./istio-egressgateway.yaml
    {{< /text >}}

1. 重新部署 `istio-egressgateway`：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway.yaml
    deployment "istio-egressgateway" configured
    {{< /text >}}

1. 校验证书和私钥，是否被成功加载到 `istio-egressgateway` Pod 之中：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/nginx-client-certs /etc/nginx-ca-certs
    {{< /text >}}

    在 `/etc/istio/nginx-client-certs` 中应该存在 `tls.crt` 和 `tls.key`，`ca-chain.cert.pem` 则应该存在于 `/etc/istio/nginx-ca-certs`。

### 为 Egress 流量配置双向 TLS 的发起

1. 为 `nginx.example.com` 创建 Egress 网关，端口为 443，使用 `DestinationRule` 和 `VirtualService` 将流量引入 Egress 网关，并从 Egress 网关发到外部服务。

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

1. 定义一个 `VirtualService` 来把流量转发到 Egress 网关，`DestinationRule` 用于执行双向 TLS 的发起：

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

1. 发送 HTTP 请求到 `http://nginx.example.com`：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -s --resolve nginx.example.com:80:1.1.1.1 http://nginx.example.com
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1. 输出 `istio-egressgateway` Pod 的日志，查看和我们发出的请求相关的内容。
    如果 Istio 部署在  `istio-system` 命名空间里，输出日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'nginx.example.com' | grep HTTP
    {{< /text >}}

    应该会看到类似的内容：

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "nginx.example.com" "172.21.72.197:443"
    {{< /text >}}

### 清理双向 TLS 发起的例子 {#clean-example-2}

1. 删除创建的 Kubernetes 资源：

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

1. 删除证书目录，以及克隆到本地的代码仓库：

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1. 删除用在这个例子中生成的配置文件：

    {{< text bash >}}
    $ rm -f ./nginx.conf ./istio-egressgateway.yaml
    {{< /text >}}

## 清理 {#cleanup}

删除 `sleep` 的 `Service` 和 `Deployment`：

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
