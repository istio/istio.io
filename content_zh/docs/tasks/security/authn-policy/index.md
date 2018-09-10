---
title: 基础认证策略
description: 介绍如何使用 Istio 认证策略设置双向 TLS 和基本的终端用户认证。
weight: 10
keywords: [安全,认证]
---

通过这项任务，你将学习:

* 使用认证策略设置双向 TLS。

* 使用认证策略进行终端用户认证。

## 开始之前

* 理解 Istio [认证策略](/zh/docs/concepts/security/#认证策略)和相关的[双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)概念。

* 拥有一个安装好 Istio 的 Kubernetes 集群，并且全局双向 TLS 处于禁用状态(可使用[安装步骤](/zh/docs/setup/kubernetes/quick-start/#安装步骤)中提供的示例配置 `install/kubernetes/istio.yaml`，或者使用 [Helm](/zh/docs/setup/kubernetes/helm-install/) 设置 `global.mtls.enabled` 为 false)。

* 为了演示，需要创建两个命名空间 `foo` 和 `bar`，并且在两个空间中都部署带有 sidecar 的 [httpbin]({{< github_tree >}}/samples/httpbin) 应用和带 sidecar 的 [sleep]({{< github_tree >}}/samples/sleep) 应用。同时，运行另外一份不带有 sidecar 的 httpbin 和 sleep 应用(为了保证独立性，在 `legacy` 命名空间中运行它们)。在一个常规系统中，一个服务可以是其它服务的 *服务端* (接收流量)，同时也可以是另外一些服务的 *客户端* 。为了简单起见，在这个演示中，我们只使用 `sleep` 作为客户端，使用 `httpbin` 作为服务端。

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    {{< /text >}}

* 通过从任意客户端(例如 `sleep.foo`、`sleep.bar` 和 `sleep.legacy`) 向任意服务端 (`httpbin.foo`、 `httpbin.bar` 或 `httpbin.legacy`) 发送 HTTP 请求(可以使用 curl 命令)来验证以上设置。所有请求都应该成功进行并且返回的 HTTP 状态码为 200。

    以下是一个检查从 `sleep.bar` 到 `httpbin.foo` 可达性的命令示例：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    以下单行命令可以方便对所有客户端服务端组合进行检查：

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
    sleep.foo to httpbin.foo: 200
    sleep.foo to httpbin.bar: 200
    sleep.foo to httpbin.legacy: 200
    sleep.bar to httpbin.foo: 200
    sleep.bar to httpbin.bar: 200
    sleep.bar to httpbin.legacy: 200
    sleep.legacy to httpbin.foo: 200
    sleep.legacy to httpbin.bar: 200
    sleep.legacy to httpbin.legacy: 200
    {{< /text >}}

    > 如果你在 istio-proxy 容器中安装了 `curl` ，你也可以验证从 proxy 到 `httpbin` 服务的可达性：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c istio-proxy -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* 最后且重要的是，验证系统目前不存在认证策略:

    {{< text bash >}}
    $ kubectl get meshpolicies.authentication.istio.io
    No resources found.
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    No resources found.
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrules.networking.istio.io --all-namespaces
    {{< /text >}}

    > 你可能看到一些策略和/或由 Istio 安装时自动添加的目的地规则，具体取决于所选的安装模式。但是在 `foo` 、`bar` 和 `legacy` 命名空间中不应该有任何的策略或规则。

## 为网格中的所有服务启用双向 TLS 认证

你可以提交如下 *网格认证策略* 和目的地规则为网格中所有服务启用双向 TLS 认证：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

* 网格范围内的认证策略名称必须是 `default`；所有其它名字的策略都会被拒绝和忽视。另外注意 CRD 类型是 `MeshPolicy`，它不同于命名空间范围内或服务范围内的策略类型 (`Policy`)。
* 另一方面，目的地规则可以是任意名字，也可以存在于任意命名空间。为了保持一致性，我们在本示例中也将其命名为 `default` 并且使其仅存在于 `default` 命名空间中。
* 目的地规则中形如 `*.local` 的宿主名称只匹配网格中以 `local` 结尾的服务。
* 当处于 `ISTIO_MUTUAL` TLS 模式， Istio 会依据内部实现机制设置密钥和证书的路径(例如 `clientCertificate` 、 `privateKey` 和 `caCertificates`)。
* 如果你想要为某一特定服务定义目的地规则，那么 TLS 相关的设置也必须被复制到新规则中。

这些认证策略和目的地规则有效地配置了所有服务的 sidecars，使服务在双向 TLS 模式下分别进行接收和发送请求。但是这对于没有 sidecar 的服务并不适用，例如上文中创建的 `httpbin.legacy` 和 `sleep.legacy` 服务。如果你运行上文中提供的测试命令，你会发现从 `sleep.legacy` 到 `httpbin.foo` 和 `httpbin.bar` 的请求开始出现失败现象，这是由于虽然在服务端启用了双向 TLS 认证，但 `sleep.legacy` 并没有 sidecar 来支持认证。类似的，从 `sleep.foo` (或 `sleep.bar`) 到 `httpbin.legacy` 的请求也会失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 503
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 503
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> 返回的 HTTP 错误码还没有统一。如果 HTTP 请求是在双向 TLS 模式下发送并且服务端只接受 HTTP 请求，则返回的错误码为 503。相反，如果请求是以纯文本的格式发送到使用双向 TLS 的服务端，则返回的错误码是 000 (同时 `curl` 退出码为 56，错误信息是 "failure with receiving network data")。

为了修复从带有 sidecar 的客户端到不带 sidecar 的服务端的连接，你可以专门为这些服务端添加目的地规则来覆盖 TLS 设置。

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
  namespace: "legacy"
spec:
  host: "httpbin.legacy.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

重新尝试发送请求到 `httpbin.legacy`，一切都应该正常工作了。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> 当启用全局双向 TLS 认证时，这种方法也可以用来配置 Kubernetes 的 API 服务器。如下是一个示例配置：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "api-server"
  namespace: "default"
spec:
  host: "kubernetes.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

对于第二个问题，从不带 sidecar 的客户端到带有 sidecar 的服务端(工作在双向 TLS 模式)的连接，唯一的选择是从双向 TLS 模式切换到 `PERMISSIVE` 模式，该模式允许服务端接收 HTTP 或（双向） TLS 流量。显然，这种模式会降低安全等级，推荐只在迁移过程中使用。为了这样做，你可以更改 *网格策略* (在 `mtls` 域下增加 `mode: PERMISSIVE`)。推荐一种更保守的方法：仅在必要的情况下才为个别服务创建专属策略。下面的例子演示了这种保守的方法：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
  namespace: "foo"
spec:
  targets:
  - name: "httpbin"
  peers:
  - mtls:
      mode: PERMISSIVE
EOF
{{< /text >}}

从 `sleep.legacy` 到 `httpbin.foo` 的请求应当是成功的，但是到 `httpbin.bar` 的请求依然会失败。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
000
{{< /text >}}

在进入下一小节之前，我们需要将在本小节创建的认证策略和目的地规则移除掉。

{{< text bash >}}
$ kubectl delete meshpolicy.authentication.istio.io default
$ kubectl delete policy.authentication.istio.io -n foo --all
$ kubectl delete destinationrules.networking.istio.io default
$ kubectl delete destinationrules.networking.istio.io -n legacy --all
{{< /text >}}

## 为一个命名空间中的所有服务启用双向 TLS

你可以为每一个命名空间单独启用双向 TLS 而不必启用全局双向 TLS。启用的步骤是类似的，只是相关的策略只在命名空间范围内有效（类型为  `Policy`）。

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "default"
  namespace: "foo"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

> 类似于 *网格范围内的策略* ，命名空间范围内的策略必须命名为 `default`，并且不限定任何特定的服务（没有 `targets` 设置域）

添加相应的目的地规则：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "foo"
spec:
  host: "*.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

> 宿主名称 `*.foo.svc.cluster.local` 限制了只能匹配命名空间 `foo` 中的服务。

由于这些策略和目的地规则只对命名空间 `foo` 中的服务有效，你应该看到只有从不带 sidecar 的客户端 (`sleep.legacy`) 到 `httpbin.foo` 的请求会出现失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

## 为单个服务 `httpbin.bar` 启用双向 TLS

你也可以为某个特定的服务设置认证策略和目的地规则。执行以下命令只为 `httpbin.bar` 服务新增一项策略。

{{< text bash >}}
$ cat <<EOF | istioctl create -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
EOF
{{< /text >}}

同时增加目的地规则：

{{< text bash >}}
$ cat <<EOF | istioctl create -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: "httpbin.bar.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

> 在这个例子中，我们 **不** 在 metadata 中指定命名空间而是放在命令行 (`-n bar`) 中。它们的效果是一样的。
> 对于认证策略和目的地规则的名称并没有任何限定。在本例中为了简单，使用服务本身的名称为策略和规则命名。

同样地，运行上文中提供的测试命令。和预期一致，从 `sleep.legacy` 到 `httpbin.bar` 的请求因为同样的原因开始出现失败。

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

如果在命名空间 `bar` 中还存在其他服务，我们会发现目标为这些服务的流量不会受到影响。验证这一行为有两种方法：一种是加入更多服务；另一种是把这一策略限制到某个端口。这里我们展示第二种方法：

{{< text bash >}}
$ cat <<EOF | istioctl replace -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 1234
  peers:
  - mtls:
EOF
{{< /text >}}

同时对目的地规则做出相应的改变：

{{< text bash >}}
$ cat <<EOF | istioctl replace -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: httpbin.bar.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
    portLevelSettings:
    - port:
        number: 1234
      tls:
        mode: ISTIO_MUTUAL
EOF
{{< /text >}}

这项新的策略只作用于 `httpbin` 服务的 `1234` 端口上。结果是，双向 TLS 在端口 `8000` 上（又）被禁用并且从 `sleep.legacy` 发出的请求会恢复工作。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

## 同时使用命名空间层级和服务层级的策略

假设我们已经为命名空间 `foo` 中所有的服务添加了启用双向 TLS 的命名空间层级的策略并且观察到从 `sleep.legacy` 到 `httpbin.foo` 的请求都失败了（见上文）。现在专门为 `httpbin` 服务添加额外的策略来禁用双向 TLS （peers 域留空）：

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-3"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

另外添加对应的目的地规则：

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-3"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

重新从 `sleep.legacy` 发送请求，我们应当看到请求成功返回的状态码（200），表明服务层级的策略覆盖了命名空间层级的策略。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

## 设置终端用户认证

你需要一个有效的 JWT （与在本例中你想使用的 JWKS endpoint 相一致）。请按照[这里]({{< github_tree >}}/security/tools/jwt)的说明进行操作来创建一个 JWT 。你也可以在示例中使用自己的 JWT/JWKS endpoint。创建之后，在环境变量中设置相关信息。

{{< text bash >}}
$ export SVC_ACCOUNT="example@my-project.iam.gserviceaccount.com"
$ export JWKS=https://www.googleapis.com/service_accounts/v1/jwk/${SVC_ACCOUNT}
$ export TOKEN=<YOUR-TOKEN>
{{< /text >}}

另外，为了方便，通过入口暴露 `httpbin.foo` 服务（详细信息参考[入口任务](/zh/docs/tasks/traffic-management/ingress/)）。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: httpbin-ingress
  namespace: foo
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - http:
      paths:
      - path: /headers
        backend:
          serviceName: httpbin
          servicePort: 8000
EOF
{{< /text >}}

获取入口 IP:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get ing -n foo -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
{{< /text >}}

并且运行查询测试:

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

现在，让我们为 `httpbin.foo` 添加一项策略使其必须通过用户 JWT 访问。下一步命令假设名称为 "httpbin" 的策略已经存在（如果你是按照前面小节的说明进行的操作）。你可以运行 `kubectl get policies.authentication.istio.io -n foo` 进行确认。如果相应资源不存在，使用 `istio create` （替换 `istio replace` ）创建资源。注意在以下策略中，对端的认证方式（双向 TLS ）也会被设置，尽管可以移除该设置同时不影响初始的认证设置。

{{< text bash >}}
$ cat <<EOF | istioctl replace -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-3"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
  origins:
  - jwt:
      issuer: $SVC_ACCOUNT
      jwksUri: $JWKS
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

使用上面小节中同样的 curl 命令进行测试时会返回 401 错误状态码，这是因为服务端需要 JWT 进行认证但请求端并没有提供：

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

在请求中附加上面操作生成的 token ，然后执行请求就会返回成功信息：

{{< text bash >}}
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

你也可以尝试修改 token 或 policy （例如改变 issuer、audiences、expiry date 等信息）来观察 JWT 验证的其它方面信息。

## 清除

清除所有资源。

{{< text bash >}}
$ kubectl delete ns foo bar legacy
{{< /text >}}
