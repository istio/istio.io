---
title: 基础认证策略
description: 介绍如何使用 Istio 认证策略设置双向 TLS 和基本的终端用户认证。
weight: 10
keywords: [安全,认证]
---

此任务涵盖启用、配置和使用 Istio 身份验证策略时可能需要执行的主要活动。[认证概述](/zh/docs/concepts/security/#认证)中可以了解更多相关的基本概念。

## 开始之前

* 理解 Istio [认证策略](/zh/docs/concepts/security/#认证策略)和相关的
[双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)概念。

* 拥有一个安装好 Istio 的 Kubernetes 集群，并且禁用全局双向 TLS（可使用[安装步骤](/zh/docs/setup/kubernetes/quick-start/#安装步骤)中提供的示例配置
 `install/kubernetes/istio.yaml`，或者使用 [Helm](/zh/docs/setup/kubernetes/helm-install/)
 设置 `global.mtls.enabled` 为 false）。

### 安装

为了演示，需要创建两个命名空间 `foo` 和 `bar`，并且在两个空间中都部署带有 sidecar 的
 [httpbin]({{< github_tree >}}/samples/httpbin) 应用和 [sleep]({{< github_tree >}}/samples/sleep) 应用。同时运行另外一份不带有 Sidecar 的 httpbin 和 sleep 应用（为了保证独立性，
 在 `legacy` 命名空间中运行它们）。如果您在尝试任务时想要使用相同的示例，运行以下内容：

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

通过从任意客户端（例如 `sleep.foo`、`sleep.bar` 和 `sleep.legacy`）向任意服务端（`httpbin.foo` 、`httpbin.bar` 或 `httpbin.legacy`）发送 HTTP 请求（可以使用 curl 命令）来验证以上设置。所有请求都应该成功进行并且返回的 HTTP 状态码为 200。

以下是一个从 `sleep.bar` 到 `httpbin.foo` 可达性的检查命令示例：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

以下单行命令可以方便对所有客户端和服务端的组合进行检查：

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

重要的是，验证系统目前没有认证策略：

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
No resources found.
{{< /text >}}

{{< text bash >}}
$ kubectl get meshpolicies.authentication.istio.io
No resources found.
{{< /text >}}

最后要进行的验证是，确保没有为示例服务定义匹配的目标规则。一个验证方法是：获取现存目标规则，查看 `host:` 字段值是否匹配示例服务的 FQDN。例如：

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

> 你可能看到一些策略和/或由 Istio 安装时自动添加的目的地规则，具体取决于所选的安装模式。但是在 `foo`、`bar` 和 `legacy` 命名空间中没有任何的策略或规则。

## 为网格中的所有服务启用双向 TLS 认证

你可以提交如下**网格范围的认证策略（`MeshPolicy`）**和目的地规则为网格中所有服务启用双向 TLS 认证：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

此策略指定网格中的所有工作负荷仅接受使用 TLS 的加密请求。如您所见，此身份验证策略的类型是
`MeshPolicy`，这种策略的生效范围是整个网格内的所有服务，因此名称必须是 `default`，另外也不包含 `targets` 字段。

此时，只有接收方被配置为使用双向 TLS。如果在 Istio 服务（即那些带有 Sidecar 的服务）之间运行 `curl` 命令，所有请求都将失败并显示 503 错误代码，原因是客户端仍在使用明文请求。

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 503
sleep.foo to httpbin.bar: 503
sleep.bar to httpbin.foo: 503
sleep.bar to httpbin.bar: 503
{{< /text >}}

要配置客户端也使用双向 TLS，就需要设置[目标规则](/zh/docs/concepts/traffic-management/#目标规则)。可以使用多个目标规则，一个一个的为每个适用的服务（或命名空间）进行配置；然而在规则中使用 `*` 符号来匹配所有服务会更方便，这样也就跟网格范围的认证策略一致了。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "default"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

>
* 主机值 `*.local` 仅限于与集群中的服务匹配，而不是外部服务。另请注意，目标规则中没有针对名称或命名空间的限制。
* 在 `ISTIO_MUTUAL` TLS 模式中，Istio 将根据其内部实现设置密钥和证书（例如客户端证书、私钥和 CA 证书）的路径。

除了认证场合之外，目标规则还有其它方面的应用，例如金丝雀部署。但是所有的目标规则都适用相同的优先顺序。因此，如果一个服务需要配置其它目标规则（例如配置负载均衡），那么新规则定义中必须包含类似的 TLS 块来定义 `ISTIO_MUTUAL` 模式，否则它将覆盖网格或命名空间范围的 TLS 设置并禁用 TLS。

如上所述重新运行测试命令，您将看到 Istio 服务之间的所有请求现已成功完成：

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

### 从非 Istio 服务请求到 Istio 服务

非 Istio 服务，例如 `sleep.legacy` 没有 Sidecar，因此它无法启动与 Istio 服务通信所需的 TLS 连接。因此从 `sleep.legacy` 到 `httpbin.foo` 或 `httpbin.bar` 的请求将失败：

{{< text bash >}}
$ for from in "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> 在这种情况下，由于 Envoy 拒绝了明文请求，因此 `curl` 会以错误代码 56（接收网络数据失败）退出。

这一结果是符合预期的，但遗憾的是，如果不降低这些服务的身份验证要求，就无法完成这种访问。

### 从 Istio 服务请求非 Istio 服务

如果从 `sleep.foo`（或 `sleep.bar`）向 `httpbin.legacy` 发送请求，也会看到请求失败，因为 Istio 按照我们的指示配置客户端目标规则使用双向 TLS，但 `httpbin.legacy` 没有 Sidecar，所以它无法处理它。

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 503
sleep.bar to httpbin.legacy: 503
{{< /text >}}

要解决此问题，我们可以添加目标规则来覆盖 `httpbin.legacy` 的 TLS 设置。例如：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "httpbin-legacy"
spec:
 host: "httpbin.legacy.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

### 从 Istio 服务请求到 Kubernetes API Server

Kubernetes API Server 没有 Sidecar，因此来自 `sleep.foo` 等 Istio 服务的请求会失败，出现像请求非 Istio 服务时同样的问题而失败。

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
000
command terminated with exit code 35
{{< /text >}}

同样，我们可以通过覆盖 API 服务器的目标规则来更正此问题（ `kubernetes.default` ）

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "api-server"
spec:
 host: "kubernetes.default.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

> 如果使用[默认双向 TLS 选项](/zh/docs/setup/kubernetes/quick-start/#安装步骤)安装 Istio，此规则与上述全局身份验证策略和目标规则一起将在安装过程中注入系统。

重新运行上面的测试命令，确认在添加规则后能够成功返回 200：

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清理第 1 部分

删除在上述步骤中创建的策略和目标规则：

{{< text bash >}}
$ kubectl delete meshpolicy default
$ kubectl delete destinationrules default httpbin-legacy api-server
{{< /text >}}

## 为每个命名空间或服务启用双向 TLS

除了为整个网格指定身份验证策略之外，Istio 还允许您为特定命名空间或服务指定策略。一个
命名空间范围的策略优先于网格范围的策略，而特定于服务的策略仍具有更高的优先级。

### 命名空间范围的策略

下面的示例显示了为命名空间 `foo` 中的所有服务启用双向 TLS 的策略。正如你所看到的，它使用的类别是 `Policy` 而不是 `MeshPolicy`，并指定了一个命名空间，在本例中为 `foo`。如果未指定命名空间值，则策略将应用于默认命名空间。

{{< text bash >}}
$ kubectl apply -f - <<EOF
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

> 类似于**网格范围的策略**，命名空间范围的策略必须命名为 `default`，并且不限定任何特定的服务（没有 `targets` 字段）。

添加相应的目的地规则：

{{< text bash >}}
$ kubectl apply -f - <<EOF
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

> 主机名称 `*.foo.svc.cluster.local` 限制了只能匹配命名空间 `foo` 中的服务。

由于这些策略和目的地规则只对命名空间 `foo` 中的服务有效，你应该看到只有从不带 Sidecar 的客户端（`sleep.legacy`）到 `httpbin.foo` 的请求会出现失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

## 特定于服务的策略

也可以为某个特定的服务设置认证策略和目的地规则。执行以下命令，只为 `httpbin.bar` 服务新增一项策略。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
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
$ cat <<EOF | kubectl apply -n bar -f -
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

> 在这个例子中，我们**不**在 metadata 中指定命名空间而是放在命令行（`-n bar`）中。它们的效果是一样的。
> 对于认证策略和目的地规则的名称并没有任何限定。在本例中为了简单，使用服务本身的名称为策略和规则命名。

同样地，运行上文中提供的测试命令。和预期一致，从 `sleep.legacy` 到 `httpbin.bar` 的请求因为同样的原因开始出现失败。

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

如果在命名空间 `bar` 中还存在其他服务，我们会发现目标为这些服务的流量不会受到影响。验证这一行为有两种方法：一种是加入更多服务；另一种是把这一策略限制到某个端口。这里我们展示第二种方法：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
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
  - mtls: {}
EOF
{{< /text >}}

同时对目的地规则做出相应的改变：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
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

新的策略只作用于 `httpbin` 服务的 `1234` 端口上。结果是，双向 TLS 在端口 `8000` 上（又）被禁用并且从 `sleep.legacy` 发出的请求会恢复工作。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

## 策略优先级

服务级策略是优先于命名空间级策略的，为了证实这一行为，可以新建一条策略，禁止 `httpbin.foo` 的双向 TLS 设置；而此时网格中已经创建了一个命名空间级的策略，该策略为 `foo` 命名空间中的所有服务启用了双向 TLS，下面就来观察一下从 `sleep.legacy` 到 `httpbin.foo` 的请求是如何失败的：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "overwrite-example"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

另外添加对应的目的地规则：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "overwrite-example"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

重新从 `sleep.legacy` 发送请求，我们应当看到请求成功返回的状态码（`200`），表明服务级的策略覆盖了命名空间层级的策略。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清理第 2 部分

删除在上述步骤中创建的策略和目标规则：

{{< text bash >}}
$ kubectl delete policy default overwrite-example -n foo
$ kubectl delete policy httpbin -n bar
$ kubectl delete destinationrules default overwrite-example -n foo
$ kubectl delete destinationrules httpbin -n bar
{{< /text >}}

## 设置终端用户认证

要验证这一功能，首先要有一个有效的 JWT。JWT 必须与本例中的 JWKS 端点相匹配。本例中我们使用 Istio 代码库中的 [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) 以及
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json) 进行演示。

另外为了方便起见，我们使用 `ingressgateway` 开放了 `httpbin.foo` 服务（这部分内容可以参看[控制 Ingress 流量](/zh/docs/tasks/traffic-management/ingress/)任务中的介绍）。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: foo
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: foo
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - route:
    - destination:
        port:
          number: 8000
        host: httpbin.foo.svc.cluster.local
EOF
{{< /text >}}

获取入口 IP：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

并且运行查询测试：

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

现在添加一条策略，强制 `httpbin.org` 使用终端用户 JWT。下一个命令假设没有为 `httpbin.org` 指定服务级策略（也就是说成功运行了上面[清理第 2 部分](#清理第-2-部分)的内容）。可以用命令 `kubectl get policies.authentication.istio.io -n foo` 来验证这一假设：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

使用上面小节中同样的 curl 命令进行测试时会返回 401 错误状态码，这是因为服务端需要 JWT 进行认证但请求端并没有提供：

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

用下面的 `curl` 命令生成 Token 并附加在请求中，然后执行请求就会返回成功信息：

{{< text bash>}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

要观察 JWT 验证的其他方面，请使用脚本 [`gen-jwt.py`]({{<github_tree>}}/security/tools/jwt/samples/gen-jwt.py) 生成新的令牌以测试不同的发行者、受众和到期日期等。例如下面的命令创建一个 5 秒后到期的 Token。Istio 首先成功通过该令牌的验证请求，但在 5 秒后就会拒绝这一 Token 了：

{{< text bash >}}
$ TOKEN=$(@security/tools/jwt/samples/gen-jwt.py@ @security/tools/jwt/samples/key.pem@ --expire 5)
$ for i in `seq 1 10`; do curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"; sleep 1; done
200
200
200
200
200
401
401
401
401
401
{{< /text >}}

### 使用双向 TLS 进行最终用户身份验证

最终用户身份验证和双向 TLS 可以一起使用。修改上面的策略以定义双向 TLS 和最终用户 JWT 身份验证：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

> 如果尚未提交 `jwt-example` 策略，请使用 `istio create`。

并添加目标规则：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
  namespace: "foo"
spec:
  host: "httpbin.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

> 如果已经在网格级或者命名空间级的策略中启用了双向 TLS，则主机 `httpbin.foo` 已被其它目标规则覆盖。因此就不需要添加此目标规则了。另一方面，仍然需要将 `mtls` 节添加到身份验证策略，因为服务级的策略将完全覆盖网格级（或命名空间级）的策略。

在这些更改之后，来自 Istio 服务（包括 ingress gateway）到 `httpbin.foo` 的流量将使用双向 TLS。上面的测试命令仍然有效。在使用正确的令牌的情况下，Istio 服务直接向 `httpbin.foo` 发出的请求也可以正常工作：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
200
{{< /text >}}

但是，来自非 Istio 服务的明文请求将失败：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
401
{{< /text >}}

### 清理第 3 部分

1. 删除身份验证策略：

    {{< text bash >}}
    $ kubectl delete policy jwt-example
    {{< /text >}}

1. 删除目标规则：

    {{< text bash >}}
    $ kubectl delete policy httpbin
    {{< /text >}}

1. 如果您不打算探索任何后续任务，则只需删除测试命名空间即可删除所有资源：

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}
