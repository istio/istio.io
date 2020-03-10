---
title: 安全问题
description: 定位常见 Istio 认证、授权、安全相关问题的技巧。
force_inline_toc: true
weight: 20
keywords: [security,citadel]
aliases:
    - /zh/help/ops/security/repairing-citadel
    - /zh/help/ops/troubleshooting/repairing-citadel
    - /zh/docs/ops/troubleshooting/repairing-citadel
---

## 终端用户认证失败{#end-user-authentication-fails}

使用 Istio，可以启用终端用户认证。目前，Istio 认证策略提供的终端用户凭证是 JWT。以下是排查终端用户 JWT 身份认证问题的指南。

1. 检查 Istio 身份认证策略 Policy 配置，`principalBinding` 需要被设为 `USE_ORIGIN` 来验证终端用户。

1. 如果 `jwksUri` 未设置，确保 JWT 发行者是 url 格式并且 `url + /.well-known/openid-configuration` 可以在浏览器中打开；例如，如果 JWT 发行者是 `https://accounts.google.com`，确保 `https://accounts.google.com/.well-known/openid-configuration` 是有效的 url，并且可以在浏览器中打开。

    {{< text yaml >}}
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
          issuer: "628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
          jwksUri: "https://www.googleapis.com/service_accounts/v1/jwk/628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
      principalBinding: USE_ORIGIN
    {{< /text >}}

1. 如果 JWT token 放在 http 请求头 Authorization 字段值中，需要确认 JWT token 的有效性（未过期等）。JWT 令牌中的字段可以使用在线 JWT 解析工具进行解码，例如：[jwt.io](https://jwt.io/)。

1. 通过获取 Istio 代理（例如：Envoy）日志来验证 Pilot 分发的配置是否正确的。
   例如，如果身份认证策略在命名空间 `foo` 中的 `httpbin` 服务上执行，使用如下命令可以查看 Istio 代理的日志，确保 `local_jwks` 已设置，并且 http 响应码输出到 Istio 代理日志中。

    {{< text bash >}}
    $ kubectl logs httpbin-68fbcdcfc7-hrnzm -c istio-proxy -n foo
    [2018-07-04 19:13:30.762][15][info][config] ./src/envoy/http/jwt_auth/auth_store.h:72] Loaded JwtAuthConfig: rules {
      issuer: "628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
      local_jwks {
        inline_string: "{\n \"keys\": [\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"03bc39a6b56602c0d2ad421c3993d5e4f88e6f54\",\n   \"n\": \"u9gnSMDYw4ggVKInAfxpXqItv9Ii7PlUFrAcwANQMW9fbZrFpITFD45t0gUy9CK4QewkLhqDDUJSvpH7wprS8Hi0M8wAJf_lgugdRr6Nc2qK-eywjjDK-afQjhGLcMJGS0YXi3K2lyP-oWiLingMbYRiJxTi86icWT8AU8bKoTyTPFOExAJkDFnquulU0_KlteZxbjnRIVvMKfpgZ3yK9Pzv7XjtdvO7xlr59K9Zotd4mgphIUADfw1fR0lNkjHQp9N0WP9cbOsyUwm5jjDklnyVh7yBHcEk1YHccntosxnwIn-cj538PSaL_qDZgDAsJKHPZlkiP_1mjsu3NkofIQ\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"60aef5b0877e9f0d67b787b5be797636735efdee\",\n   \"n\": \"0TmzDEN12GF9UaWJI40oKwJlu53ZQihHcaVi1thLGs1l3ubdPWv8MEsc9X2DjCRxEB6Ss1R2VOImrQ2RWFuBSNHorjE0_GyEGNzvOH-0uUQ5uES2HvEN7384XfUYj9MoTPibstDEl84pm4d3Ka3R_1wk03Jrl9MIq6fnV_4Z-F7O7ElGqk8xcsiVUowd447dwlrd55ChIyISF5PvbCLtOKz9FgTz2mEb8jmzuZQs5yICgKZCzlJ7xNOOmZcqCZf9Qzaz4OnVLXykBLzSuLMtxvvOxf53rvWB0F2__CjKlEWBCQkB39Zaa_4I8dCAVxgkeQhgoU26BdzLL28xjWzdbw\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"62a93512c9ee4c7f8067b5a216dade2763d32a47\",\n   \"n\": \"0YWnm_eplO9BFtXszMRQNL5UtZ8HJdTH2jK7vjs4XdLkPW7YBkkm_2xNgcaVpkW0VT2l4mU3KftR-6s3Oa5Rnz5BrWEUkCTVVolR7VYksfqIB2I_x5yZHdOiomMTcm3DheUUCgbJRv5OKRnNqszA4xHn3tA3Ry8VO3X7BgKZYAUh9fyZTFLlkeAh0-bLK5zvqCmKW5QgDIXSxUTJxPjZCgfx1vmAfGqaJb-nvmrORXQ6L284c73DUL7mnt6wj3H6tVqPKA27j56N0TB1Hfx4ja6Slr8S4EB3F1luYhATa1PKUSH8mYDW11HolzZmTQpRoLV8ZoHbHEaTfqX_aYahIw\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"b3319a147514df7ee5e4bcdee51350cc890cc89e\",\n   \"n\": \"qDi7Tx4DhNvPQsl1ofxxc2ePQFcs-L0mXYo6TGS64CY_2WmOtvYlcLNZjhuddZVV2X88m0MfwaSA16wE-RiKM9hqo5EY8BPXj57CMiYAyiHuQPp1yayjMgoE1P2jvp4eqF-BTillGJt5W5RuXti9uqfMtCQdagB8EC3MNRuU_KdeLgBy3lS3oo4LOYd-74kRBVZbk2wnmmb7IhP9OoLc1-7-9qU1uhpDxmE6JwBau0mDSwMnYDS4G_ML17dC-ZDtLd1i24STUw39KH0pcSdfFbL2NtEZdNeam1DDdk0iUtJSPZliUHJBI_pj8M-2Mn_oA8jBuI8YKwBqYkZCN1I95Q\",\n   \"e\": \"AQAB\"\n  }\n ]\n}\n"
      }
      forward: true
      forward_payload_header: "istio-sec-8a85f33ec44c5ccbaf951742ff0aaa34eb94d9bd"
    }
    allow_missing_or_failed: true
    [2018-07-04 19:13:30.763][15][info][upstream] external/envoy/source/server/lds_api.cc:62] lds: add/update listener '10.8.2.9_8000'
    [2018-07-04T19:13:39.755Z] "GET /ip HTTP/1.1" 401 - 0 29 0 - "-" "curl/7.35.0" "e8374005-1957-99e4-96b6-9d6ec5bef396" "httpbin.foo:8000" "-"
    [2018-07-04T19:13:40.463Z] "GET /ip HTTP/1.1" 401 - 0 29 0 - "-" "curl/7.35.0" "9badd659-fa0e-9ca9-b4c0-9ac225571929" "httpbin.foo:8000" "-"
    {{< /text >}}

## 授权过于严格{#authorization-is-too-restrictive}

当你第一次对一个服务启用授权，所有的请求都会被默认拒绝。在你增加上授权策略后，满足授权策略的请求才能够通过。如果所有的请求还是被拒绝，你可以尝试以下操作：

1. 确保在你的授权策略 YAML 文件中内容没有输入错误。

1. 不要为 Istio 的控制面组件启用授权，包括 Mixer、Pilot、Ingress。Istio 授权策略是为访问 Istio 网格内服务的授权而设计的。如果对 Istio 的控制面启用授权会导致不可预期的行为。

1. 确保你的 `ServiceRoleBinding` 和相关的 `ServiceRole` 对象在同一个命名空间（检查 `metadata/namespace` 这一行）。

1. 请您不要为 TCP 服务的 `ServiceRole` 和 `ServiceRoleBinding` 设置那些仅适用于 HTTP 服务的属性字段。否则，Istio 会自动忽略这些配置，就好像它们不存在一样。

1. 在 Kubernetes 环境，确保在一个 `ServiceRole` 对象下的所有服务都和 `ServiceRole` 在同一个 namespace 。例如，如果 `ServiceRole` 对象中的服务是 `a.default.svc.cluster.local`，`ServiceRole` 必须在 `default` 命名空间（`metadata/namespace` 这一行应该是 `default`）。对于非 Kubernetes 的环境，一个网格的所有 `ServiceRoles` 和 `ServiceRoleBindings` 都应该在相同的命名空间下。

1. 根据[确保授权正确开启](#ensure-authorization-is-enabled-correctly)找到确切的原因。

## 授权太过宽松{#authorization-is-too-permissive}

如果已经对一个服务启用了授权，但是对这个服务的请求没有被阻止，那么很有可能是授权没有成功启用。通过以下步骤可以检查这种情况：

1. 检查[启用授权文档](/zh/docs/concepts/security/#authorization)来正确的启用 Istio 授权。

1. 避免为 Istio 控制面组件启用授权，包括 Mixer，Pilot 和 Ingress。Istio 的授权是设计用于 Istio Mesh 下的服务之间的授权的。对 Istio 组件启用授权会引发不可预料的行为。

1. 在你的 Kubernetes 环境中，检查所有命名空间下的部署，确保没有可能导致 Istio 错误的遗留的部署。如果发现在向 Envoy 推送授权策略的时候发生错误，你可以禁用 Pilot 的授权插件。

1. 根据[确保授权正确开启](#ensure-authorization-is-enabled-correctly)找到确切的原因

## 确保授权正确开启{#ensure-authorization-is-enabled-correctly}

`ClusterRbacConfig` 默认是集群级别的自定义资源，用于控制全局的授权功能。

1. 运行下面的命令，列出已存在的 `ClusterRbacConfig` 配置：

    {{< text bash >}}
    $ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
    {{< /text >}}

1. 这里应该**只有一个**命名为 `default` 的 `ClusterRbacConfig` 实例。否则 Istio 会禁用授权功能并忽略所有策略。

    {{< text plain >}}
    NAMESPACE   NAME      AGE
    default     default   1d
    {{< /text >}}

1. 如果有多个 `ClusterRbacConfig` 实例, 请删除其它的 `ClusterRbacConfig`，保证集群之中只有一个名为 `default` 的 `ClusterRbacConfig`。

## 确保 Pilot 接受策略{#ensure-pilot-accepts-the-policies}

Pilot 负责对授权策略进行转换，并将其分发给 Sidecar。下面的的步骤可以用于确认 Pilot 是否按预期在工作：

1. 运行下列命令，导出 Pilot 的 `ControlZ`：

    {{< text bash >}}
    $ kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
    {{< /text >}}

1. 确保看到如下输出:

    {{< text plain >}}
    Forwarding from 127.0.0.1:9876 -> 9876
    {{< /text >}}

1. 用浏览器打开 `http://127.0.0.1:9876/scopez/`，浏览 `ControlZ` 页面。

1. 将 `rbac` 输出级别修改为 `debug`。

1. 在步骤 1 中打开的终端窗口中输入 `Ctrl+C`，终止端口转发进程。

1. 执行以下命令，输出 Pilot 日志并搜索 `rbac`：

    {{< tip >}}
    你可能需要先删除并重建授权策略，以保证调试日志能够根据这些策略正常生成。
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
    {{< /text >}}

1. 检查输出并验证：

    - 没有出现错误。
    - 出现 `"built filter config for ..."` 内容，意味着为目标服务生成了过滤器。

1. 例如你可能会看到类似这样的内容：

    {{< text plain >}}
    2018-07-26T22:25:41.009838Z debug rbac building filter config for {sleep.foo.svc.cluster.local map[app:sleep pod-template-hash:3326367878] map[destination.name:sleep destination.namespace:foo destination.user:default]}
    2018-07-26T22:25:41.009915Z info  rbac no service role in namespace foo
    2018-07-26T22:25:41.009957Z info  rbac no service role binding in namespace foo
    2018-07-26T22:25:41.010000Z debug rbac generated filter config: { }
    2018-07-26T22:25:41.010114Z info  rbac built filter config for sleep.foo.svc.cluster.local
    2018-07-26T22:25:41.182400Z debug rbac building filter config for {productpage.default.svc.cluster.local map[pod-template-hash:2600844901 version:v1 app:productpage] map[destination.name:productpage destination.namespace:default destination.user:bookinfo-productpage]}
    2018-07-26T22:25:41.183131Z debug rbac checking role app2-grpc-viewer
    2018-07-26T22:25:41.183214Z debug rbac role skipped for no AccessRule matched
    2018-07-26T22:25:41.183255Z debug rbac checking role productpage-viewer
    2018-07-26T22:25:41.183281Z debug rbac matched AccessRule[0]
    2018-07-26T22:25:41.183390Z debug rbac generated filter config: {policies:<key:"productpage-viewer" value:<permissions:<and_rules:<rules:<or_rules:<rules:<header:<name:":method" exact_match:"GET" > > > > > > principals:<and_ids:<ids:<any:true > > > > >  }
    2018-07-26T22:25:41.184407Z info  rbac built filter config for productpage.default.svc.cluster.local
    {{< /text >}}

    说明 Pilot 生成了：

    - `sleep.foo.svc.cluster.local` 的空配置。因为没有符合条件的策略，并且 Istio 默认情况下，会禁止所有对这一服务的访问。

    - `productpage.default.svc.cluster.local` 的配置。Istio 会放行所有针对该服务的 GET 访问。

## 确认 Pilot 正确的将策略分发给了代理服务器{#ensure-pilot-distributes-policies-to-proxies-correctly}

Pilot 负责向代理服务器分发授权策略。下面的步骤用来确认 Pilot 按照预期工作：

{{< tip >}}
这一章节的命令假设用户已经部署了 [Bookinfo](/zh/docs/examples/bookinfo/)，否则的话应该将 `"-l app=productpage"` 部分根据实际情况进行替换。
{{< /tip >}}

1. 运行下面的命令，获取 `productpage` 服务的代理配置信息：

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. 校验日志内容：

    - 日志中包含了一个 `envoy.filters.http.rbac` 过滤器，会对每一个进入的请求执行授权策略。
    - 授权策略更新之后，Istio 会据此更新过滤器。

1. 下面的输出表明，`productpage` 的代理启用了 `envoy.filters.http.rbac` 过滤器，配置的规则为允许任何人通过 `GET` 方法进行访问 `productpage` 服务。`shadow_rules` 没有生效，可以放心的忽略它。

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "config": {
      "rules": {
       "policies": {
        "productpage-viewer": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "header": {
                  "exact_match": "GET",
                  "name": ":method"
                 }
                }
               ]
              }
             }
            ]
           }
          }
         ],
         "principals": [
          {
           "and_ids": {
            "ids": [
             {
              "any": true
             }
            ]
           }
          }
         ]
        }
       }
      },
      "shadow_rules": {
       "policies": {}
      }
     }
    },
    {{< /text >}}

## 确认策略在代理服务器中正确执行{#ensure-proxies-enforce-policies-correctly}

代理是授权策略的最终实施者。下面的步骤帮助用户确认代理的工作情况：

{{< tip >}}
这里的命令假设用户已经部署了 [Bookinfo](/zh/docs/examples/bookinfo/)，否则的话应该将 `"-l app=productpage"` 部分根据实际情况进行替换。
{{< /tip >}}

1. 使用以下命令，在代理中打开授权调试日志：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request POST 'logging?rbac=debug'
    {{< /text >}}

1. 确认可以看到以下输出：

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. 在浏览器中打开 `productpage`，以便生成日志。

1. 使用以下命令打印代理日志：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. 检查输出，并验证:

    - 根据请求被允许或者被拒绝，分别输出日志包含 `enforced allowed` 或这 `enforced denied` 。

    - 授权策略需要从请求中获取数据。

1. 下面的输出表示，对 `productpage` 的 `GET` 请求被策略放行。`shadow denied` 没有什么影响，你可以放心的忽略它。

    {{< text plain >}}
    ...
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:79] checking request: remoteAddress: 10.60.0.139:51158, localAddress: 10.60.0.93:9080, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account, subjectPeerCertificate: O=, headers: ':authority', '35.238.0.62'
    ':path', '/productpage'
    ':method', 'GET'
    'upgrade-insecure-requests', '1'
    'user-agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36'
    'dnt', '1'
    'accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    'accept-encoding', 'gzip, deflate'
    'accept-language', 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7'
    'x-forwarded-for', '10.60.0.1'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e23ea62d-b25d-91be-857c-80a058d746d4'
    'x-b3-traceid', '5983108bf6d05603'
    'x-b3-spanid', '5983108bf6d05603'
    'x-b3-sampled', '1'
    'x-istio-attributes', 'CikKGGRlc3RpbmF0aW9uLnNlcnZpY2UubmFtZRINEgtwcm9kdWN0cGFnZQoqCh1kZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWVzcGFjZRIJEgdkZWZhdWx0Ck8KCnNvdXJjZS51aWQSQRI/a3ViZXJuZXRlczovL2lzdGlvLWluZ3Jlc3NnYXRld2F5LTc2NjY0Y2NmY2Ytd3hjcjQuaXN0aW8tc3lzdGVtCj4KE2Rlc3RpbmF0aW9uLnNlcnZpY2USJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApDChhkZXN0aW5hdGlvbi5zZXJ2aWNlLmhvc3QSJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApBChdkZXN0aW5hdGlvbi5zZXJ2aWNlLnVpZBImEiRpc3RpbzovL2RlZmF1bHQvc2VydmljZXMvcHJvZHVjdHBhZ2U='
    'content-length', '0'
    'x-envoy-internal', 'true'
    'sec-istio-authn-payload', 'CkVjbHVzdGVyLmxvY2FsL25zL2lzdGlvLXN5c3RlbS9zYS9pc3Rpby1pbmdyZXNzZ2F0ZXdheS1zZXJ2aWNlLWFjY291bnQSRWNsdXN0ZXIubG9jYWwvbnMvaXN0aW8tc3lzdGVtL3NhL2lzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudA=='
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
      }
    }

    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:88] shadow denied
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:98] enforced allowed
    ...
    {{< /text >}}

## 密钥和证书错误{#keys-and-certificates-errors}

如果您怀疑 Istio 使用的某些密钥或证书不正确，那么第一步是确保 [Citadel 健康](#repairing-citadel)。

然后，您可以验证 Citadel 是否真正生成了密钥和证书：

{{< text bash >}}
$ kubectl get secret istio.my-sa -n my-ns
NAME                    TYPE                           DATA      AGE
istio.my-sa             istio.io/key-and-cert          3         24d
{{< /text >}}

其中 `my-ns` 和 `my-sa` 是您的 pod 运行的 namespace 和 Service Account 。

如果要检查其他 Service Account 的密钥和证书，可以运行以下命令列出 Citadel 生成的密钥和证书的所有的 secret：

{{< text bash >}}
$ kubectl get secret --all-namespaces | grep istio.io/key-and-cert
NAMESPACE      NAME                                                 TYPE                                  DATA      AGE
.....
istio-system   istio.istio-citadel-service-account                  istio.io/key-and-cert                 3         14d
istio-system   istio.istio-cleanup-old-ca-service-account           istio.io/key-and-cert                 3         14d
istio-system   istio.istio-egressgateway-service-account            istio.io/key-and-cert                 3         14d
istio-system   istio.istio-ingressgateway-service-account           istio.io/key-and-cert                 3         14d
istio-system   istio.istio-mixer-post-install-account               istio.io/key-and-cert                 3         14d
istio-system   istio.istio-mixer-service-account                    istio.io/key-and-cert                 3         14d
istio-system   istio.istio-pilot-service-account                    istio.io/key-and-cert                 3         14d
istio-system   istio.istio-sidecar-injector-service-account         istio.io/key-and-cert                 3         14d
istio-system   istio.prometheus                                     istio.io/key-and-cert                 3         14d
kube-public    istio.default                                        istio.io/key-and-cert                 3         14d
.....
{{< /text >}}

然后检查证书是否有效：

{{< text bash >}}
$ kubectl get secret -o json istio.my-sa -n my-ns | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            99:59:6b:a2:5a:f4:20:f4:03:d7:f0:bc:59:f5:d8:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jun  4 20:38:20 2018 GMT
            Not After : Sep  2 20:38:20 2018 GMT
        Subject: O =
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c8:a0:08:24:61:af:c1:cb:81:21:90:cc:03:76:
                    01:25:bc:ff:ca:25:fc:81:d1:fa:b8:04:aa:d4:6b:
                    55:e9:48:f2:e4:ab:22:78:03:47:26:bb:8f:22:10:
                    66:47:47:c3:b2:9a:70:f1:12:f1:b3:de:d0:e9:2d:
                    28:52:21:4b:04:33:fa:3d:92:8c:ab:7f:cc:74:c9:
                    c4:68:86:b0:4f:03:1b:06:33:48:e3:5b:8f:01:48:
                    6a:be:64:0e:01:f5:98:6f:57:e4:e7:b7:47:20:55:
                    98:35:f9:99:54:cf:a9:58:1e:1b:5a:0a:63:ce:cd:
                    ed:d3:a4:88:2b:00:ee:b0:af:e8:09:f8:a8:36:b8:
                    55:32:80:21:8e:b5:19:c0:2f:e8:ca:4b:65:35:37:
                    2f:f1:9e:6f:09:d4:e0:b1:3d:aa:5f:fe:25:1a:7b:
                    d4:dd:fe:d1:d3:b6:3c:78:1d:3b:12:c2:66:bd:95:
                    a8:3b:64:19:c0:51:05:9f:74:3d:6e:86:1e:20:f5:
                    ed:3a:ab:44:8d:7c:5b:11:14:83:ee:6b:a1:12:2e:
                    2a:0e:6b:be:02:ad:11:6a:ec:23:fe:55:d9:54:f3:
                    5c:20:bc:ec:bf:a6:99:9b:7a:2e:71:10:92:51:a7:
                    cb:79:af:b4:12:4e:26:03:ab:35:e2:5b:00:45:54:
                    fe:91
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
    Signature Algorithm: sha256WithRSAEncryption
         78:77:7f:83:cc:fc:f4:30:12:57:78:62:e9:e2:48:d6:ea:76:
         69:99:02:e9:62:d2:53:db:2c:13:fe:0f:00:56:2b:83:ca:d3:
         4c:d2:01:f6:08:af:01:f2:e2:3e:bb:af:a3:bf:95:97:aa:de:
         1e:e6:51:8c:21:ee:52:f0:d3:af:9c:fd:f7:f9:59:16:da:40:
         4d:53:db:47:bb:9c:25:1a:6e:34:41:42:d9:26:f7:3a:a6:90:
         2d:82:42:97:08:f4:6b:16:84:d1:ad:e3:82:2c:ce:1c:d6:cd:
         68:e6:b0:5e:b5:63:55:3e:f1:ff:e1:a0:42:cd:88:25:56:f7:
         a8:88:a1:ec:53:f9:c1:2a:bb:5c:d7:f8:cb:0e:d9:f4:af:2e:
         eb:85:60:89:b3:d0:32:60:b4:a8:a1:ee:f3:3a:61:60:11:da:
         2d:7f:2d:35:ce:6e:d4:eb:5c:82:cf:5c:9a:02:c0:31:33:35:
         51:2b:91:79:8a:92:50:d9:e0:58:0a:78:9d:59:f4:d3:39:21:
         bb:b4:41:f9:f7:ec:ad:dd:76:be:28:58:c0:1f:e8:26:5a:9e:
         7b:7f:14:a9:18:8d:61:d1:06:e3:9e:0f:05:9e:1b:66:0c:66:
         d1:27:13:6d:ab:59:46:00:77:6e:25:f6:e8:41:ef:49:58:73:
         b4:93:04:46
{{< /text >}}

确保显示的证书包含有效信息。特别是，Subject Alternative Name 字段应为 `URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`。
如果不是这样，您的 Citadel 可能已经出现问题。尝试重新部署 Citadel 并再次检查。

最后，您可以验证密钥和证书是否由 sidecar 代理正确安装在 `/etc/certs` 目录中。您可以使用此命令检查：

{{< text bash >}}
$ kubectl exec -it my-pod-id -c istio-proxy -- ls /etc/certs
cert-chain.pem    key.pem    root-cert.pem
{{< /text >}}

（可选）您可以使用以下命令检查其内容：

{{< text bash >}}
$ kubectl exec -it my-pod-id -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            7e:b4:44:fe:d0:46:ba:27:47:5a:50:c8:f0:8e:8b:da
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jul 13 01:23:13 2018 GMT
            Not After : Oct 11 01:23:13 2018 GMT
        Subject: O =
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bb:c9:cd:f4:b8:b5:e4:3b:f2:35:aa:4c:67:cc:
                    1b:a9:30:c4:b7:fd:0a:f5:ac:94:05:b5:82:96:b2:
                    c8:98:85:f9:fc:09:b3:28:34:5e:79:7e:a9:3c:58:
                    0a:14:43:c1:f4:d7:b8:76:ab:4e:1c:89:26:e8:55:
                    cd:13:6b:45:e9:f1:67:e1:9b:69:46:b4:7e:8c:aa:
                    fd:70:de:21:15:4f:f5:f3:0f:b7:d4:c6:b5:9d:56:
                    ef:8a:91:d7:16:fa:db:6e:4c:24:71:1c:9c:f3:d9:
                    4b:83:f1:dd:98:5b:63:5c:98:5e:2f:15:29:0f:78:
                    31:04:bc:1d:c8:78:c3:53:4f:26:b2:61:86:53:39:
                    0a:3b:72:3e:3d:0d:22:61:d6:16:72:5d:64:e3:78:
                    c8:23:9d:73:17:07:5a:6b:79:75:91:ce:71:4b:77:
                    c5:1f:60:f1:da:ca:aa:85:56:5c:13:90:23:02:20:
                    12:66:3f:8f:58:b8:aa:72:9d:36:f1:f3:b7:2b:2d:
                    3e:bb:7c:f9:b5:44:b9:57:cf:fc:2f:4b:3c:e6:ee:
                    51:ba:23:be:09:7b:e2:02:6a:6e:e7:83:06:cd:6c:
                    be:7a:90:f1:1f:2c:6d:12:9e:2f:0f:e4:8c:5f:31:
                    b1:a2:fa:0b:71:fa:e1:6a:4a:0f:52:16:b4:11:73:
                    65:d9
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/default/sa/bookinfo-productpage
    Signature Algorithm: sha256WithRSAEncryption
         8f:be:af:a4:ee:f7:be:21:e9:c8:c9:e2:3b:d3:ac:41:18:5d:
         f8:9a:85:0f:98:f3:35:af:b7:e1:2d:58:5a:e0:50:70:98:cc:
         75:f6:2e:55:25:ed:66:e7:a4:b9:4a:aa:23:3b:a6:ee:86:63:
         9f:d8:f9:97:73:07:10:25:59:cc:d9:01:09:12:f9:ab:9e:54:
         24:8a:29:38:74:3a:98:40:87:67:e4:96:d0:e6:c7:2d:59:3d:
         d3:ea:dd:6e:40:5f:63:bf:30:60:c1:85:16:83:66:66:0b:6a:
         f5:ab:60:7e:f5:3b:44:c6:11:5b:a1:99:0c:bd:53:b3:a7:cc:
         e2:4b:bd:10:eb:fb:f0:b0:e5:42:a4:b2:ab:0c:27:c8:c1:4c:
         5b:b5:1b:93:25:9a:09:45:7c:28:31:13:a3:57:1c:63:86:5a:
         55:ed:14:29:db:81:e3:34:47:14:ba:52:d6:3c:3d:3b:51:50:
         89:a9:db:17:e4:c4:57:ec:f8:22:98:b7:e7:aa:8a:72:28:9a:
         a7:27:75:60:85:20:17:1d:30:df:78:40:74:ea:bc:ce:7b:e5:
         a5:57:32:da:6d:f2:64:fb:28:94:7d:28:37:6f:3c:97:0e:9c:
         0c:33:42:f0:b6:f5:1c:0d:fb:70:65:aa:93:3e:ca:0e:58:ec:
         8e:d5:d0:1e
{{< /text >}}

## 双向 TLS 错误{#mutual-TLS-errors}

如果怀疑双向 TLS 出现了问题，首先要确认 [Citadel 健康](#repairing-citadel)，接下来要查看的是[密钥和证书正确下发](#keys-and-certificates-errors) Sidecar.

如果上述检查都正确无误，下一步就应该验证[认证策略](/zh/docs/tasks/security/authentication/authn-policy/)已经创建，并且对应的目标规则是否正确应用。

## Citadel 行为异常 {#repairing-citadel}

{{< warning >}}
Citadel 不支持多个实例运行，否则会造成竞争状态并导致系统崩溃。
{{< /warning >}}

{{< warning >}}
在 Citadel 维护禁用期间，带有新 ServiceAccount 的负载不能够启动，因为它不能从 Citadel 获取生成的证书。
{{< /warning >}}

Citadel 不是关键的数据平面组件。默认的工作负载证书有效期是 3 个月。证书在过期前会被 Citadel 轮换。如果在 Citadel 短暂的维护期间内，已经存在的 双向 TLS 不会受影响。

如果您怀疑 Citadel 无法正常工作，请验证 `istio-citadel` pod 的状态：

{{< text bash >}}
$ kubectl get pod -l istio=citadel -n istio-system
NAME                                     READY     STATUS   RESTARTS   AGE
istio-citadel-ff5696f6f-ht4gq            1/1       Running  0          25d
{{< /text >}}

如果 `istio-citadel` pod 不存在，请尝试重新部署 pod。

如果 `istio-citadel` pod 存在但其状态不是 `Running` ，请运行以下命令以获得更多调试信息并检查是否有任何错误：

{{< text bash >}}
$ kubectl logs -l istio=citadel -n istio-system
$ kubectl describe pod -l istio=citadel -n istio-system
{{< /text >}}

如果想要检查一个工作负载（在 `default` 命名空间 ，并且使用 `default` ServiceAccount ）的证书有效期：

{{< text bash >}}
$ kubectl get secret -o json istio.default -n default | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -noout -text | grep "Not After" -C 1
  Not Before: Jun  1 18:23:30 2019 GMT
  Not After : Aug 30 18:23:30 2019 GMT
Subject:
{{< /text >}}

{{< tip >}}
不要忘记将 `istio.default` 和 `-n default` 替换成 `istio.YourServiceAccount` 和 `-n YourNamespace`。如果证书已经过期，Citadel 没有及时更新 secret，请检查 Citadel 日志查以获取更多信息。
{{< /tip >}}
