---
title: Egress 网关 TLS 连接 发起的过程 (SDS)
description: 描述了如何配置 Egress 网关，使用 Secret Discovery Service 执行 TLS 链接外部服务。
weight: 40
keywords: [traffic-management,egress,sds]
owner: istio/wg-security-maintainers
test: yes
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway-tls-origination-sds/
---

[TLS 连接流量 Egress](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)的例子展示了如何配置 Istio 来执行{{< gloss >}}TLS origination{{< /gloss >}}把流量导入至外部服务，并为通往外部服务的流量进行 TLS 连接。[配置 Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/)的示例显示了如何配置 Istio 以引导 Egress 流量通过一个专门的 Egress 网关服务。这个例子结合了之前的两个例子描述了如何配置一个 Egress 网关，来执行把 TLS 发起的流量连接到外部服务。

TLS 所需的私钥、服务器证书和 root 证书是通过以下方式配置的[Secret Discovery Service (SDS)](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#secret-discovery-service-sds).

## 开始之前{#before-you-begin}

*   按照[安装指南](/zh/docs/setup/)中的说明设置 Istio。

*   启动[sleep]({{< github_tree >}}/samples/sleep)样例这将被用作外部调用的测试源。

    如果您已经启用了[自动 Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，请执行

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，您必须在部署"sleep"应用程序之前手动注入 Sidecar。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    注意，任何您可以`exec`和`curl`的 Pod 都可以。

*   对于macOS用户，请确认您使用的是1.1或更高版本的`openssl`。

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g 2020年4月21日
    {{< /text >}}

    如果前面的命令输出的是"1.1"或更高版本，如图所示，您的"openssl"命令应该可以按照本任务的说明正常工作。否则，请升级您的`openssl`或尝试不同的`openssl`实现，例如在 Linux 机器上

*   [部署 Istio Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway)。

*   [启用 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)。

{{<tip>}}}
 如果您使用[基于文件挂载的方法](/zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination)配置了一个egress网关。
 而您想把您的 Egress 网关迁移到使用SDS方法，则不需要额外的步骤。
{{</tip >}}

## 使用SDS在 Egress 网关上执行 TLS 连接{#perform-TLS-origination-with-an-egress-gateway-using-SDS}

本节描述了如何执行[TLS 连接流量 Egress](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)
的例子。只是这次使用了一个 Egress 网关。请注意，在这种情况下，TLS初始化将由 Egress 网关完成。是由 Egress 网关完成的，而不是前一个例子中的挎包。Egress 网关将使用 SDS 而不是文件挂载来提供客户证书。

### 生成 CA 及证书密钥{#generate-CA-and-server-certificates-and-keys}

对于这项任务，您可以使用您喜欢的工具来生成证书和钥匙。下面的命令使用[openssl](https://man.openbsd.org/openssl.1).

1.  创建一个根证书和私钥，为您的服务签署证书：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  为`my-nginx.mesh-external.svc.cluster.local`创建一个证书和私钥：

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

### 部署一个简单的 TLS 服务器{#deploy-a-simple-TLS-server}

为了模拟一个支持简单 TLS 协议的实际外部服务。在您的Kubernetes集群中部署一个[NGINX](https://www.nginx.com)服务器，但在 Istio 服务网外运行，即在没有启用 Istio sidecar 代理注入的命名空间中。

1.  创建一个命名空间来代表 Istio 网状结构之外的服务，即`mesh-external`。请注意，Sidecar 代理将不会被自动注入到这个命名空间的 Pod 中，因为自动注入 Sidecar 的功能没有被[启用](/zh/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) 上。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. 创建 Kubernetes [Secrets](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/) 来保存服务器的和 CA 的证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  为 NGINX 服务器创建一个配置文件：

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
        ssl_verify_client off; # In simple TLS, server doesn't verify client's certificate
      }
    }
    EOF
    {{< /text >}}

1.  创建一个 Kubernetes [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/)
来保存 NGINX 服务器的配置。

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

### 为 Egress 流量配置简单的 TLS 连接{#configure-simple-TLS-origination-for-egress-traffic}

1. 创建一个 Kubernetes Secret 来保存 Egress 网关用来发起 TLS 连接的CA证书。

    {{< text bash >}}
    $ kubectl create secret generic client-credential-cacert --from-file=ca.crt=example.com.crt -n istio-system
    {{< /text >}}

    请注意，Istio 的纯 CA 证书的 Secret 名称必须以`-cacert`结尾，并且秘密**必须**在与 Istio 相同的命名空间中创建。Secret 必须与 Istio 部署的命名空间相同，本例中为 "istio-system"。

1.  为`my-nginx.mesh-external.svc.cluster.local`创建一个 Egress `gateway`，端口443，以及目标规则和虚拟服务，以引导流量通过 Egress 网关并从 Egress 网关到外部服务

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

1.  定义一个`VirtualService`来引导流量通过 Egress 网关：

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

1.  添加一个`DestinationRule`来执行一个简单的 TLS 连接

    {{< text bash >}}
    $ kubectl apply -n istio-system -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-tls-for-nginx
    spec:
      host: my-nginx.mesh-external.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE
            credentialName: client-credential # this must match the secret created earlier without the "-cacert" suffix
            sni: my-nginx.mesh-external.svc.cluster.local
    EOF
    {{< /text >}}

1.  发送一个 HTTP 请求到`http://my-nginx.mesh-external.svc.cluster.local`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  检查`istio-egressgateway`Pod 的日志，看看有没有与我们的请求相对应的日志。如果 Istio 被部署在`istio-system`命名空间，打印日志的命令是:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
    {{< /text >}}

    您应该看到与下面类似的一行:

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
    {{< /text >}}

### 清理 TLS 连接的示例{#cleanup-the-TLS-origination example}

1.   删除您创建的 Istio 配置项：

    {{< text bash >}}
    $ kubectl delete destinationrule originate-tls-for-nginx -n istio-system
    $ kubectl delete virtualservice direct-nginx-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-nginx
    $ kubectl delete gateway istio-egressgateway
    $ kubectl delete secret client-credential-cacert -n istio-system
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr
    {{< /text >}}

1.  删除本例中生成的配置文件。

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## 通过 Egress 网关发起 双向TLS 连接{#perform-mutual-TLS-origination-with-an-egress-gateway}

与上一节类似，这一节描述了如何配置一个 Egress 网关来执行为外部服务进行 TLS 连接，只是这次使用的是一个需要双向 TLS 连接的服务。

Egress 网关将使用 SDS 而不是文件挂载来提供客户端证书。

### 生成客户端和服务端的证书和钥匙{#generate-client-and-server-certificates-and-keys}

对于这项任务，您可以使用您喜欢的工具来生成证书和钥匙。也可以参考下面命令：[openssl](https://man.openbsd.org/openssl.1).

1.  创建一个 root 证书和私钥，为您的服务端签署证书：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  为`my-nginx.mesh-external.svc.cluster.local`创建一个证书和私钥:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

1.  生成客户端的证书和私钥:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### 部署一个双向TLS服务器{deploy-a-mutual-TLS-server}

为了模拟一个支持双向 TLS 连接的实际外部服务。在您的 Kubernetes 集群中部署一个[NGINX](https://www.nginx.com)服务器，但在 Istio 服务网外运行，即在没有启用 Istio Sidecar 代理注入的命名空间中运行。

1.  创建一个命名空间来代表 Istio 网状结构之外的服务，即`mesh-external`。请注意，Sidecar 代理将不会被自动注入到这个命名空间的 Pod 中，因为自动注入 Sidecar 的功能没有被[启用](/zh/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) 上。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. 创建 Kubernetes [Secrets](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/) 来保存服务器的证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  为 NGINX 服务器创建一个配置文件：

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
        ssl_verify_client on; # In mutual TLS, server verifies client's certificate
      }
    }
    EOF
    {{< /text >}}

1.  创建一个 Kubernetes [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/)
来保存 NGINX 服务器的配置。

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  部署 NGINX 服务器。

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

### 使用 SDS 给 Egress 流量配置双向 TSL 连接{#configure-mutual-TLS-origination-for-egress-traffic-using- SDS}

1.  创建 Kubernetes [Secrets](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)来保存客户的证书。

    {{< text bash >}}
    $ kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

    The secret **must** be created in the same namespace as Istio is deployed in, `istio-system` in this case.

    To support integration with various tools, Istio supports a few different Secret formats.

    In this example. a single generic Secret with keys `tls.key`, `tls.crt`, and `ca.crt` is used.

1.  为`my-nginx.mesh-external.svc.cluster.local`创建一个 Egress `Gateway`，端口443，以及目标规则和虚拟服务，以引导流量通过 Egress 网关并从 Egress 网关到外部服务。

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

1.  定义一个 `VirtualService` 来引导流量通过 Egress 网关:

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

1.  添加一个 `DestinationRule` 来执行双向 TLS 连接

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
            credentialName: client-credential # this must match the secret created earlier to hold client certs
            sni: my-nginx.mesh-external.svc.cluster.local
    EOF
    {{< /text >}}

1.  发送一个 HTTP 请求到 `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  检查`istio-egressgateway`Pod 的日志，看看有没有与我们的请求相对应的日志。如果 Istio 被部署在`istio-system`命名空间，打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
    {{< /text >}}

    您应该看到与下面类似的一行。

    {{< text plain>}}
    [2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
    {{< /text >}}

### 清理双向TLS连接的示例{cleanup-the mutual-TLS-origination-example}

1.  移除创建的 Kubernetes 资源:

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

1.  删除证书和私钥:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1.  删除本例中生成的配置文件:

    {{< text bash >}}
    $ rm ./nginx.conf
    $ rm ./gateway-patch.json
    {{< /text >}}

## 清理{#cleanup}

删除`sleep`服务和部署。

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
