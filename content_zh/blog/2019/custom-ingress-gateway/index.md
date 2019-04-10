---
title: 使用 Cert-Manager 部署一个自定义 Ingress 网关
description: 如何使用 cert-manager 手工部署一个自定义 Ingress 网关。
subtitle: 自定义 Ingress 网关
publishdate: 2019-01-10
keywords: [ingress,traffic-management]
attribution: Julien Senon
---

本文介绍了手工创建自定义 Ingress [Gateway](/docs/reference/config/networking/v1alpha3/gateway/) 的过程，其中使用 cert-manager 完成了证书的自动管理。

自定义 Ingress 网关在使用不同负载均衡器来隔离通信的情况下很有帮助。

## 开始之前 {#before you begin}

* 根据[安装指南](/zh/docs/setup/)完成 Istio 的部署。
* 用 Helm [Chart](https://github.com/helm/charts/tree/master/stable/cert-manager#installing-the-chart) 部署 `cert-manager`。
* 我们会使用 `demo.mydemo.com` 进行演示，因此你的 DNS 解析要能够解析这个域名。

## 配置自定义 Ingress 网关 {#configuring-the-custom-ingress-gateway}

1. 用下面的 `helm` 命令检查 [cert-manager](https://github.com/helm/charts/tree/master/stable/cert-manager) 是否已经完成部署：

    {{< text bash >}}
    $ helm ls
    {{< /text >}}

    该命令的输出大概如下所示，其中的 `cert-manager` 的 `STATUS` 字段应该是 `DEPLOYED`

    {{< text plain >}}
    NAME   REVISION UPDATED                  STATUS   CHART                     APP VERSION   NAMESPACE
    istio     1     Thu Oct 11 13:34:24 2018 DEPLOYED istio-1.0.X               1.0.X         istio-system
    cert      1     Wed Oct 24 14:08:36 2018 DEPLOYED cert-manager-v0.6.0-dev.2 v0.6.0-dev.2  istio-system
    {{< /text >}}

1. 要创建集群的证书签发者，可以使用如下的配置：

    {{< tip >}}
    用自己的配置修改集群的[证书签发者](https://cert-manager.readthedocs.io/en/latest/reference/issuers.html#issuers)。例子中使用的是 `route53`。
    {{< /tip >}}

    {{< text yaml >}}
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-demo
      namespace: kube-system
    spec:
      acme:
        # ACME 服务器地址
        server: https://acme-v02.api.letsencrypt.org/directory
        # ACME 注册的 Email 地址
        email: <REDACTED>
        # Secret 的名字，用于保存 ACME 账号的私钥
        privateKeySecretRef:
          name: letsencrypt-demo
        dns01:
          # 这里定义了一个列表，包含了 DNS-01 的相关内容，用于应对 DNS Challenge。
          providers:
          - name: your-dns
            route53:
              accessKeyID: <REDACTED>
              region: eu-central-1
              secretAccessKeySecretRef:
                name: prod-route53-credentials-secret
                key: secret-access-key
    {{< /text >}}

1. 如果使用的是 `route53` [provider](https://cert-manager.readthedocs.io/en/latest/tasks/acme/configuring-dns01/route53.html)，必须提供一个 Secret 来进行 DNS 的 ACME 验证。可以使用下面的配置来创建需要的 Secret：

    {{< text yaml >}}
    apiVersion: v1
    kind: Secret
    metadata:
      name: prod-route53-credentials-secret
    type: Opaque
    data:
      secret-access-key: <REDACTED BASE64>
    {{< /text >}}

1. 创建自己的证书：

    {{< text yaml >}}
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: Certificate
    metadata:
      name: demo-certificate
      namespace: istio-system
    spec:
      acme:
        config:
        - dns01:
            provider: your-dns
          domains:
          - '*.mydemo.com'
      commonName: '*.mydemo.com'
      dnsNames:
      - '*.mydemo.com'
      issuerRef:
        kind: ClusterIssuer
        name: letsencrypt-demo
      secretName: istio-customingressgateway-certs
    {{< /text >}}

    记录一下 `secretName` 的值，后面会使用它。

1. 要进行自动扩容，可以新建一个 HPA 对象：

    {{< text yaml >}}
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
      name: my-ingressgateway
      namespace: istio-system
    spec:
      maxReplicas: 5
      minReplicas: 1
      scaleTargetRef:
        apiVersion: apps/v1beta1
        kind: Deployment
        name: my-ingressgateway
      targetCPUUtilizationPercentage: 80
    status:
      currentCPUUtilizationPercentage: 0
      currentReplicas: 1
      desiredReplicas: 1
    {{< /text >}}

1. 使用[附件 YAML 中的定义](/blog/2019/custom-ingress-gateway/deployment-custom-ingress.yaml)进行部署。

    {{< tip >}}
    其中类似 `aws-load-balancer-type` 这样的注解，只对 AWS 生效。
    {{< /tip >}}

1. 创建你的服务：

    {{< warning >}}
    `NodePort` 需要是一个可用端口。
    {{< /warning >}}

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: my-ingressgateway
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
      labels:
        app: my-ingressgateway
        istio: my-ingressgateway
    spec:
      type: LoadBalancer
      selector:
        app: my-ingressgateway
        istio: my-ingressgateway
      ports:
        -
          name: http2
          nodePort: 32380
          port: 80
          targetPort: 80
        -
          name: https
          nodePort: 32390
          port: 443
        -
          name: tcp
          nodePort: 32400
          port: 31400
    {{< /text >}}

1. 创建你的自定义 Ingress 网关配置对象：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      annotations:
      name: istio-custom-gateway
      namespace: default
    spec:
      selector:
        istio: my-ingressgateway
      servers:
      - hosts:
        - '*.mydemo.com'
        port:
          name: http
          number: 80
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.mydemo.com'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    {{< /text >}}

1. 使用 `VirtualService` 连接 `istio-custom-gateway`：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: my-virtualservice
    spec:
      hosts:
      - "demo.mydemo.com"
      gateways:
      - istio-custom-gateway
      http:
      - route:
        - destination:
            host: my-demoapp
    {{< /text >}}

1. 服务器返回了正确的证书，并成功完成验证（`SSL certificate verify ok`）：

    {{< text bash >}}
    $ curl -v `https://demo.mydemo.com`
    Server certificate:
      SSL certificate verify ok.
    {{< /text >}}

**恭喜你！** 现在你可以使用自定义的 `istio-custom-gateway` [网关](/docs/reference/config/networking/v1alpha3/gateway/)对象了。