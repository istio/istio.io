---
title: Istio Webhook 管理 [实验性]
description: 如何在 Istio 中使用 istioctl 工具管理 webhooks。
weight: 100
keywords: [security,webhook]
---

{{< boilerplate experimental-feature-warning >}}

Istio 有两个 webhooks：Galley 和 sidecar 注入器。
默认情况下，这些 webhooks 自己管理自己的配置。
从安全角度来看，不建议使用此默认行为，因为被侵入的 webhook 随后可能会进行提权攻击。

这个任务展示了如何使用新的 [{{< istioctl >}} x post-install webhook](/zh/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) 命令来安全的管理 webhooks 的配置。

## 开始{#getting-started}

* [配置 DNS 证书](/zh/docs/tasks/security/dns-cert)，并将 `global.operatorManageWebhooks` 设置为 `true`，以安装 Istio。

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          operatorManageWebhooks: true
          certificates:
            - secretName: dns.istio-galley-service-account
              dnsNames: [istio-galley.istio-system.svc, istio-galley.istio-system]
            - secretName: dns.istio-sidecar-injector-service-account
              dnsNames: [istio-sidecar-injector.istio-system.svc, istio-sidecar-injector.istio-system]
    EOF
    $ istioctl manifest apply -f ./istio.yaml
    {{< /text >}}

* 安装 [`jq`](https://stedolan.github.io/jq/) 以解析 JSON。

## 检查 webhook 证书{#check-webhook-certificates}

为了显示 Galley 和 sidecar 注入器的 webhook 证书的 DNS 名字，您需要用以下命令获取 Kubernetes 的 secret，解析它，解码它，并查看输出的文本：

{{< text bash >}}
$ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
$ kubectl get secret dns.istio-sidecar-injector-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
{{< /text >}}

上述命令的输出会分别包含 Galley 和 sidecar 注入器的 DNS 名字：

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-sidecar-injector.istio-system.svc, DNS:istio-sidecar-injector.istio-system
{{< /text >}}

## 启用 webhook 配置{#enable-webhook-configurations}

1. 运行以下命令生成 `MutatingWebhookConfiguration` 和 `ValidatingWebhookConfiguration` 配置文件。

    {{< text bash >}}
    $ istioctl manifest generate > istio.yaml
    {{< /text >}}

1. 打开 `istio.yaml` 配置文件，搜索 `kind: MutatingWebhookConfiguration`，将 sidecar 注入器的 `MutatingWebhookConfiguration` 部分另存为 `sidecar-injector-webhook.yaml` 文件。下面是示例 `istio.yaml` 中的 `MutatingWebhookConfiguration`。

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: MutatingWebhookConfiguration
    metadata:
      name: istio-sidecar-injector
      labels:
        app: sidecarInjectorWebhook
        release: istio
    webhooks:
      - name: sidecar-injector.istio.io
        clientConfig:
          service:
            name: istio-sidecar-injector
            namespace: istio-system
            path: "/inject"
          caBundle: ""
        rules:
          - operations: [ "CREATE" ]
            apiGroups: [""]
            apiVersions: ["v1"]
            resources: ["pods"]
        failurePolicy: Fail
        namespaceSelector:
          matchLabels:
            istio-injection: enabled
    {{< /text >}}

1. 打开 `istio.yaml` 配置文件，搜索 `kind: ValidatingWebhookConfiguration`，将 Galley 的 `ValidatingWebhookConfiguration` 部分另存为 `galley-webhook.yaml` 文件。下面是示例 `istio.yaml` 中的 `ValidatingWebhookConfiguration`（为节省空间只摘抄了一部分）。

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: ValidatingWebhookConfiguration
    metadata:
      name: istio-galley
      labels:
        app: galley
        release: istio
        istio: galley
    webhooks:
      - name: pilot.validation.istio.io
        clientConfig:
          service:
            name: istio-galley
            namespace: istio-system
            path: "/admitpilot"
          caBundle: ""
        rules:
          - operations:
            - CREATE
            - UPDATE
            apiGroups:
            - config.istio.io
            ... SKIPPED
        failurePolicy: Fail
        sideEffects: None
    {{< /text >}}

1. 验证目前不存在 Galley 和 sidecar 注入器的 webhook 配置。下面两条命令的输出应该不包含 Galley 和 sidecar 注入器的任何配置。

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration
    $ kubectl get validatingwebhookconfiguration
    {{< /text >}}

    如果已经存在 Galley 和 sidecar 注入器的 webhook 配置（例如，上一次 Istio 部署所遗留的），使用下列命令删除它们。在运行这些命令之前，将命令中的 webhook 配置的名字换成您的集群中的 Galley 和 sidecar 注入器的实际 webhook 配置的名字。

    {{< text bash >}}
    $ kubectl delete mutatingwebhookconfiguration SIDECAR-INJECTOR-WEBHOOK-CONFIGURATION-NAME
    $ kubectl delete validatingwebhookconfiguration GALLEY-WEBHOOK-CONFIGURATION-NAME
    {{< /text >}}

1. 使用 `istioctl` 启用 webhook 配置：

    {{< text bash >}}
    $ istioctl experimental post-install webhook enable --webhook-secret dns.istio-galley-service-account \
        --namespace istio-system --validation-path galley-webhook.yaml \
        --injection-path sidecar-injector-webhook.yaml
    {{< /text >}}

1. 用以下命令验证 sidecar 注入器的 webhook 是否会将 sidecar 容器注入到示例 pod，以检查该 webhook 是否运行正常：

    {{< text bash >}}
    $ kubectl create namespace test-injection
    $ kubectl label namespaces test-injection istio-injection=enabled
    $ kubectl run --generator=run-pod/v1 --image=nginx nginx-app --port=80 -n test-injection
    $ kubectl get pod -n test-injection
    {{< /text >}}

    `get pod` 命令应该会显示如下输出。`2/2` 表示 webhook 将一个 sidecar 注入到了示例 pod 中：

    {{< text plain >}}
    NAME        READY   STATUS    RESTARTS   AGE
    nginx-app   2/2     Running   0          10s
    {{< /text >}}

1. 检查用于验证的 webhook 是否运行正常：

    {{< text bash >}}
    $ kubectl create namespace test-validation
    $ kubectl apply -n test-validation -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: invalid-gateway
    spec:
      selector:
        # DO NOT CHANGE THESE LABELS
        # The ingressgateway is defined in install/kubernetes/helm/istio/values.yaml
        # with these labels
        istio: ingressgateway
    EOF
    {{< /text >}}

    创建网关的命令应该会显示如下输出。输出中的错误表示了验证 webhook 检查了网关的配置 YAML 文件：

    {{< text plain >}}
    Error from server: error when creating "invalid-gateway.yaml": admission webhook "pilot.validation.istio.io" denied the request: configuration is invalid: gateway must have at least one server
    {{< /text >}}

## 显示 webhook 配置{#show-webhook-configurations}

1. 如果您将 sidecar 注入器的配置命名为 `istio-sidecar-injector`，将 Galley 的配置命名为 `istio-galley-istio-system`，使用下列命令来显示这两个 webhooks 的配置：

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --validation-config=istio-galley-istio-system  --injection-config=istio-sidecar-injector
    {{< /text >}}

1. 如果您将 sidecar 注入器的配置命名为 `istio-sidecar-injector`，使用下列命令来显示它的配置：

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1. 如果您将 Galley 的配置命名为 `istio-galley-istio-system`，使用下列命令来显示它的配置：

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --injection=false --validation-config=istio-galley-istio-system
    {{< /text >}}

## 禁用 webhook 配置{#disable-webhook-configurations}

1. 如果您将 sidecar 注入器的配置命名为 `istio-sidecar-injector`，将 Galley 的配置命名为 `istio-galley-istio-system`，使用下列命令来禁用这两个 webhooks 的配置：

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --validation-config=istio-galley-istio-system  --injection-config=istio-sidecar-injector
    {{< /text >}}

1. 如果您将 sidecar 注入器的配置命名为 `istio-sidecar-injector`，使用下列命令来禁用它：

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1. 如果您将 Galley 的配置命名为 `istio-galley-istio-system`，使用下列命令来禁用它：

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --injection=false --validation-config=istio-galley-istio-system
    {{< /text >}}

## 清理{#cleanup}

您可以运行下列命令来删除本教程中创建的资源。

{{< text bash >}}
$ kubectl delete ns test-injection test-validation
$ kubectl delete -f galley-webhook.yaml
$ kubectl delete -f sidecar-injector-webhook.yaml
{{< /text >}}