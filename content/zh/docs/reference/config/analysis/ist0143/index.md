---
title: LocalhostListener
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当工作负载在监听 `localhost` 网络接口，但该端口在 Service 中已暴露时，会出现此消息。
当出现这种情况时，其他 Pod 将无法访问该端口。

增加此项检查主要是为了检测旧版 Istio 上的工作负载在升级到 Istio 1.10 或更高版本时可能会出现问题。
这种行为与未安装 Istio 的标准 Kubernetes 集群中会发生的情况相匹配，但旧版本的 Istio 会暴露这些端口。

{{< warning >}}
由于此项检查依赖于特权运行时检查，因此它不包含在标准的 `istioctl analyze` 中。
此项检查包含在 `istioctl experimental precheck` 的安装和升级检查中。
{{< /warning >}}

## 示例 {#example}

以一个 `Service` 为例，执行 `nc localhost 8080 -l` 命令选择 `Pod`：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: netcat
spec:
  ports:
  - port: 8080
    protocol: TCP
  selector:
    app: netcat
{{< /text >}}

因为应用程序正在通过 `localhost` 提供流量，所以不能从其他 Pod 进行访问。

以上例子演示了如何使用简单的 `nc` 工具。其他编程语言中可以使用的等效例子为：

- Go：`net.Listen("tcp", "localhost:8080")`
- Node.js：`http.createServer().listen(8080, "localhost");`
- Python：`socket.socket().bind(("localhost", 8083))`

## 如何修复 {#how-to-resolve}

如果您不打算将应用程序暴露给其他 Pod，请从 `Service` 中移除该端口。

如果要将应用程序暴露给其他 Pod，有两个选项：

- 修改应用程序以绑定到对其他 Pod 暴露的网络接口。
  通常，这意味着绑定到 `0.0.0.0` 或 `::`，例如 `nc 0.0.0.0 8080 -l`。
- 创建 [`Sidecar` 配置](/zh/docs/reference/config/networking/sidecar/#IstioIngressListener)
  来自定义 Pod 的入站网络配置。例如，对于上述应用程序：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ratings
spec:
  workloadSelector:
    labels:
      app: netcat
  ingress:
  - port:
      number: 8080
      protocol: TCP
      name: tcp
    defaultEndpoint: 127.0.0.1:8080
{{< /text >}}
