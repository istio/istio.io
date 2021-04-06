---
title: TCP 流量
description: 展示如何设置 TCP 流量的访问控制。
weight: 20
keywords: [security,access-control,rbac,tcp,authorization]
aliases:
    - /zh/docs/tasks/security/authz-tcp/
owner: istio/wg-security-maintainers
test: yes
---

该任务向您展示了在 Istio 网格中如何为 TCP 流量设置 Istio 授权策略。

## 开始之前{#before-you-begin}

在您开始之前，请先完成以下内容：

* 阅读[Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 按照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 在命名空间例如 `foo` 中部署两个工作负载，`sleep` 和 `tcp-echo`。
这两个工作负载每个前面都会运行一个 Envoy 代理。
`tcp-echo` 工作负载会监听端口 9000、9001 和 9002，并以前缀 `hello` 输出它收到的所有流量。
例如，如果你发送 "world" 给 `tcp-echo`，那么它将会回复 `hello world`。
`tcp-echo` 的 Kubernetes 服务对象只声明了端口 9000 和 9001，而省略了端口 9002。直通过滤器链将处理端口 9002 的流量。
使用以下命令部署示例命名空间和工作负载：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* 使用以下命令确认 `sleep` 可以成功与 `tcp-echo` 的端口 9000 和 9001 交互：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

* 确认 `sleep` 可以成功与 `tcp-echo` 的端口 9002 交互。
您需要将流量直接发送到 `tcp-echo` 的 pod IP，因为在 `tcp-echo` 的 Kubernetes 服务对象中未定义端口 9002。
使用以下命令获取 pod IP 地址并发送请求：

    {{< text bash >}}
    $ TCP_ECHO_IP=$(kubectl get pod "$(kubectl get pod -l app=tcp-echo -n foo -o jsonpath={.items..metadata.name})" -n foo -o jsonpath="{.status.podIP}")
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9002
    connection succeeded
    {{< /text >}}

{{< warning >}}
如果看不到预期的输出，请在几秒钟后重试，因为缓存和其他传播开销可能会导致有些延迟。
{{< /warning >}}

## 配置 TCP 工作负载的访问控制{#configure-access-control-for-a-TCP-workload}

1. 在 `foo` 命名空间中为 `tcp-echo` 工作负载创建 `tcp-policy` 授权策略。
运行以下命令来应用策略以允许请求到端口 9000 和 9001：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
           ports: ["9000", "9001"]
    EOF
    {{< /text >}}

1. 使用以下命令验证是否允许请求端口 9000：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

1. 使用以下命令验证是否允许请求端口 9001：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

1. 验证对端口 9002 的请求是否被拒绝。即使未在 `tcp-echo` Kubernetes 服务对象中显式声明的端口，授权策略也将其应用于直通过滤器链。 运行以下命令并验证输出：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. 使用以下命令为端口 9000 添加一个名为 `methods` 的 HTTP-only 字段来更新策略：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. 验证对端口 9000 的请求是否被拒绝。发生这种情况是因为该规则在对 TCP 流量使用了 HTTP-only 字段（`methods`），这会导致规则无效。Istio 会忽略无效的 ALLOW 规则。
最终结果是该请求被拒绝，因为它与任何 ALLOW 规则都不匹配。
运行以下命令并验证输出：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. 验证对端口 9001 的请求是否被拒绝。 发生这种情况是因为请求与任何 ALLOW 规则都不匹配。 运行以下命令并验证输出：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. 使用以下命令将策略更新为 DENY 策略：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. 验证对端口 9000 的请求是否被拒绝。发生这种情况是因为 Istio 忽略了无效的 DENY 规则中的 HTTP-only 字段。这与无效的 ALLOW 规则不同，ALLOW 规则会导致 Istio 忽略整个规则。这里最终的结果是 Istio 仅使用 `ports` 字段来判断，请求会被拒绝正是因为它们与 `ports` 匹配：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. 验证是否允许对端口 9001 的请求。发生这种情况是因为请求与 DENY 策略中的 `ports` 不匹配：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

## 清理{#cleanup}

1. 删除命名空间 foo：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}
