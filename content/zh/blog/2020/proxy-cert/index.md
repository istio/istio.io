---
title: 为没有 sidecar 的应用程序提供证书和密钥
description: 通过挂载的文件获取和共享应用程序证书和密钥的机制。
publishdate: 2020-03-25
attribution: Lei Tang (Google)
keywords: [certificate,sidecar]
target_release: 1.5
---

{{< boilerplate experimental-feature-warning >}}

Istio sidecars 获取使用 secret 发现服务的证书。服务网格中的服务可能不需要（或不想要） Envoy sidecar 来处理其流量。在这种情况下，如果服务想要连接到其他 TLS 或共同 TLS 安全的服务，它将需要自己获得证书。

对于不需要 sidecar 来管理其流量的服务，sidecar 仍然可以被部署只为了通过来自 CA 的 CSR 流量提供私钥和证书，然后通过一个挂载到 `tmpfs` 中的文件来共享服务证书。我们使用 Prometheus 作为示例应用程序来配置使用此机制的证书。

在示例应用程序（即 Prometheus）中，通过设置标识 `.Values.prometheus.provisionPrometheusCert` 为 `true`（该标识在 Istio 安装中默认设置为 true）将 sidecar 添加到 Prometheus 部署。然后，这个部署的 sidecar 将请求与 Prometheus 共享一个证书。

为示例应用程序提供的密钥和证书都挂载在 `/etc/istio-certs/` 目录中。运行以下命令，我们可以列出为应用程序提供的密钥和证书：

{{< text bash >}}
$ kubectl exec -it `kubectl get pod -l app=prometheus -n istio-system -o jsonpath='{.items[0].metadata.name}'` -c prometheus -n istio-system -- ls -la /etc/istio-certs/
{{< /text >}}

上面命令的输出应该包含非空的密钥和证书文件，如下所示：

{{< text plain >}}
-rwxr-xr-x    1 root     root          2209 Feb 25 13:06 cert-chain.pem
-rwxr-xr-x    1 root     root          1679 Feb 25 13:06 key.pem
-rwxr-xr-x    1 root     root          1054 Feb 25 13:06 root-cert.pem
{{< /text >}}

如果您想使用此机制来为您自己的应用程序提供证书，请查看我们的 [Prometheus 示例应用程序]({{< github_blob >}}/manifests/charts/istio-telemetry/prometheus/templates/deployment.yaml)，并简单地遵循相同的模式。
