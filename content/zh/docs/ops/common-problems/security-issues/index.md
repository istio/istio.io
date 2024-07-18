---
title: 安全问题
description: 定位 Istio 认证、授权、安全相关等常见问题的技巧。
force_inline_toc: true
weight: 20
keywords: [security,citadel]
aliases:
    - /zh/help/ops/security/repairing-citadel
    - /zh/help/ops/troubleshooting/repairing-citadel
    - /zh/docs/ops/troubleshooting/repairing-citadel
owner: istio/wg-security-maintainers
test: n/a
---

## 终端用户认证失败 {#end-user-authentication-fails}

使用 Istio，您可以通过[请求认证策略](/zh/docs/tasks/security/authentication/authn-policy/#end-user-authentication)启用终端用户认证。
目前，Istio 认证策略提供的终端用户凭证是 JWT。以下是排查终端用户 JWT
身份认证问题的指南。

1. 如果 `jwksUri` 未设置，确保 JWT 发行者是 url 格式并且
   `url + /.well-known/openid-configuration` 可以在浏览器中打开；
   例如，如果 JWT 发行者是 `https://accounts.google.com`，确保
   `https://accounts.google.com/.well-known/openid-configuration`
   是有效的 url，并且可以在浏览器中打开。

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: RequestAuthentication
    metadata:
      name: "example-3"
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    {{< /text >}}

1. 如果 JWT 令牌放在 HTTP 请求头 Authorization 字段值中，需要确认
   JWT 令牌的有效性（未过期等）。JWT 令牌中的字段可以使用
   [jwt.io](https://jwt.io/) 这类在线 JWT 解析工具进行解码。

1. 通过 `istioctl proxy-config` 命令来验证目标负载的 Envoy 代理配置是否正确。

   当配置完成上面提到的策略示例后，可以使用以下的指令来检查 `listener` 在入站端口
   `80` 上的配置。您应该可以看到 `envoy.filters.http.jwt_authn` 过滤器包含我们在策略中已经声明的发行者和
   JWKS 信息。

    {{< text bash >}}
    $ POD=$(kubectl get pod -l app=httpbin -n foo -o jsonpath={.items..metadata.name})
    $ istioctl proxy-config listener ${POD} -n foo --port 80 --type HTTP -o json
    <redacted>
                                {
                                    "name": "envoy.filters.http.jwt_authn",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.config.filter.http.jwt_authn.v2alpha.JwtAuthentication",
                                        "providers": {
                                            "origins-0": {
                                                "issuer": "testing@secure.istio.io",
                                                "localJwks": {
                                                    "inlineString": "*redacted*"
                                                },
                                                "payloadInMetadata": "testing@secure.istio.io"
                                            }
                                        },
                                        "rules": [
                                            {
                                                "match": {
                                                    "prefix": "/"
                                                },
                                                "requires": {
                                                    "requiresAny": {
                                                        "requirements": [
                                                            {
                                                                "providerName": "origins-0"
                                                            },
                                                            {
                                                                "allowMissing": {}
                                                            }
                                                        ]
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                },
    <redacted>
    {{< /text >}}

## 授权过于严格或者宽松 {#authorization-is-too-restrictive-or-permissive}

### 确保策略 YAML 文件中没有输入错误 {#make-sure-there-are-no-typos-in-the-policy-yaml-file}

一个常见的错误是无意中在 YAML 文件中定义了多个项，例如下面的策略：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: example
  namespace: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths:
        - /foo
  - from:
    - source:
        namespaces:
        - foo
{{< /text >}}

您期望的策略所允许的请求是符合路径为 `/foo` **且**源命名空间为 `foo`。
但是，策略实际上允许的请求是符合路径为 `/foo` **或**源命名空间为 `foo`，
这显然会更加宽松。

在 YAML 的语义中，`from:` 前面的 `-` 意味着这是列表中的一个新元素。
这会在策略中创建两条规则，而不是所希望的一条。在认证策略中，多条规则之间是
`OR` 的关系。

为了解决这个问题，只需要将多余的 `-` 移除，这样策略就只有一条规则来允许符合路径为
`/foo` **且**源命名空间为 `foo` 的请求，这样就更加严格了。

### 确保您没有在 TCP 端口上使用仅适用于 HTTP 的字段 {#make-sure-you-are-not-using-http-only-fields-on-tcp-ports}

授权策略会变得更加严格因为定义了仅适用于 HTTP 的字段
 (比如 `host`、`path`、`headers`、JWT 等等) 在纯 TCP 连接上是不存在的。

对于 `ALLOW` 类的策略来说，这些字段不会被匹配。但对于 `DENY` 以及 `CUSTOM`
类策略来说，这类字段会被认为是始终匹配的。最终结果会是一个更加严格的策略从而可能导致意外的连接拒绝。

检查 Kubernetes 服务定义来确定端口是[命名中包含正确的协议名称](/zh/docs/ops/configuration/traffic-management/protocol-selection/#manual-protocol-selection)。
如果您在端口上使用了仅适用于 HTTP 的字段，要确保端口名有 `http-` 前缀。

### 确保策略配置在正确的目标上 {#make-sure-the-policy-is-applied-to-the-correct-target}

检查工作负载的选择器和命名空间来确认策略配置在了正确的目标上。您可以通过指令
`istioctl x authz check POD-NAME.POD-NAMESPACE` 来检查认证策略。

### 留意策略中的动作 {#pay-attention-to-the-action-specified-in-the-policy}

- 如果没有声明，策略中默认动作是 `ALLOW`。

- 当一个工作负载上同时配置了多个动作时（`CUSTOM`、`ALLOW` 和 `DENY`），
  所有的动作必须都满足。换句话说，如果有任何一个动作拒绝该请求，那么该请求会被拒绝，
  并且只有所有的动作都允许了该请求，该请求才会被允许。

- 在任何情况下，`AUDIT` 动作不会实施控制访问权并且不会拒绝请求。

阅读[授权隐式启用](/zh/docs/concepts/security/#implicit-enablement)了解有关评估顺序的更多详细信息。

## 确保 Istiod 接受策略 {#ensure-istiod-accepts-the-policies}

Istiod 负责对授权策略进行转换，并将其分发给 Sidecar。下面的步骤可以用于确认
Istiod 是否按预期在工作：

1. 运行以下命令启用 Istiod 的调试日志记录：

    {{< text bash >}}
    $ istioctl admin log --level authorization:debug
    {{< /text >}}

1. 通过以下命令获取 Istio 日志：

    {{< tip >}}
    您可能需要先删除并重建授权策略，以保证调试日志能够根据这些策略正常生成。
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system
    {{< /text >}}

1. 检查输出并验证是否出现错误，例如您可能会看到类似这样的内容：

    {{< text plain >}}
    2021-04-23T20:53:29.507314Z info ads Push debounce stable[31] 1: 100.981865ms since last change, 100.981653ms since last push, full=true
    2021-04-23T20:53:29.507641Z info ads XDS: Pushing:2021-04-23T20:53:29Z/23 Services:15 ConnectedEndpoints:2  Version:2021-04-23T20:53:29Z/23
    2021-04-23T20:53:29.507911Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508077Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508128Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
    2021-04-23T20:53:29.508158Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509097Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509167Z debug authorization Processed authorization policy for sleep-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509501Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509652Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on TCP filter chain successfully
        * built 1 TCP filters for DENY action
        * added 1 TCP filters to filter chain 2
        * added 1 TCP filters to filter chain 3
        * added 1 TCP filters to filter chain 4
    2021-04-23T20:53:29.510903Z info ads LDS: PUSH for node:sleep-557747455f-6dxbl.foo resources:18 size:85.0kB
    2021-04-23T20:53:29.511487Z info ads LDS: PUSH for node:httpbin-74fb669cc6-lpscm.foo resources:18 size:86.4kB
    {{< /text >}}

    以上输出说明 Istiod 生成了：

    - 适用于工作负载 `httpbin-74fb669cc6-lpscm.foo` 且带有策略
      `ns[foo]-policy[deny-path-headers]-rule[0]` 的 HTTP 过滤器配置。

    - 适用于工作负载 `httpbin-74fb669cc6-lpscm.foo` 且带有策略
      `ns[foo]-policy[deny-path-headers]-rule[0]` 的 TCP 过滤器配置。

## 确认 Istiod 正确地将策略分发给了代理 {#ensure-istiod-distributes-policies-to-proxies-correctly}

Pilot 负责向代理分发授权策略。下面的步骤用来确认 Pilot 按照预期工作：

{{< tip >}}
以下命令假设您已经部署了 [Bookinfo](/zh/docs/examples/bookinfo/)，
如果您未使用 `httpbin`，则应该根据实际情况来替换 `"-l app=httpbin"`。
{{< /tip >}}

1. 运行下面的命令，获取 `httpbin` 工作负载的代理配置信息：

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. 校验日志内容：

    - 日志中包含了一个 `envoy.filters.http.rbac` 过滤器，会对每一个进入的请求强制执行授权策略。
    - 您更新授权策略之后，Istio 会据此更新过滤器。

1. 下面的输出表明，`httpbin` 的代理启用了 `envoy.filters.http.rbac` 过滤器，
   配置的规则为拒绝所有人访问 `/headers` 路径。

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "typed_config": {
      "@type": "type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC",
      "rules": {
       "action": "DENY",
       "policies": {
        "ns[foo]-policy[deny-path-headers]-rule[0]": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "url_path": {
                  "path": {
                   "exact": "/headers"
                  }
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
      "shadow_rules_stat_prefix": "istio_dry_run_allow_"
     }
    },
    {{< /text >}}

## 确认策略在代理中正确执行 {#ensure-proxies-enforce-policies-correctly}

代理是授权策略的最终实施者。下面的步骤帮助用户确认代理是否按预期工作：

{{< tip >}}
以下命令假设您已经部署了 `httpbin`，如果您没有使用 `httpbin`，
则应将 `"-l app=httpbin"` 替换为实际的 Pod。
{{< /tip >}}

1. 使用以下命令，在代理中打开授权调试日志：

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin --level "rbac:debug"
    {{< /text >}}

1. 确认可以看到以下输出：

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. 发送一些请求到 `httpbin` 工作负载以生成一些日志。

1. 使用以下命令打印代理日志：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. 检查输出，并验证:

    - 根据请求被允许或者被拒绝，分别输出日志包含 `enforced allowed` 或这 `enforced denied` 。

    - 授权策略需要从请求中获取数据。

1. 以下是在 `/httpbin` 路径处请求的输出示例：

    {{< text plain >}}
    ...
    2021-04-23T20:43:18.552857Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:46180, directRemoteIP: 10.44.3.13:46180, remoteIP: 10.44.3.13:46180,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/sleep, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', '672c9166-738c-4865-b541-128259cc65e5'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '8a124905edf4291a21df326729b264e9'
    'x-b3-spanid', '21df326729b264e9'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/sleep'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
      }
    }

    2021-04-23T20:43:18.552910Z debug envoy rbac enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    ...
    {{< /text >}}

    日志 `enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]`
    意味着请求被策略 `ns[foo]-policy[deny-path-headers]-rule[0]` 拒绝。

1. 以下是[模拟运行模式](/zh/docs/tasks/security/authorization/authz-dry-run)下授权策略的输出示例：

    {{< text plain >}}
    ...
    2021-04-23T20:59:11.838468Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:49826, directRemoteIP: 10.44.3.13:49826, remoteIP: 10.44.3.13:49826,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/sleep, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e7b2fdb0-d2ea-4782-987c-7845939e6313'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '696607fc4382b50017c1f7017054c751'
    'x-b3-spanid', '17c1f7017054c751'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/sleep'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/sleep"
          }
        }
      }
    }

    2021-04-23T20:59:11.838529Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    2021-04-23T20:59:11.838538Z debug envoy rbac no engine, allowed by default
    ...
    {{< /text >}}

    日志 `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]`
    意味着请求将会被**模拟运行**策略 `ns[foo]-policy[deny-path-headers]-rule[0]` 拒绝。

    日志 `no engine, allowed by default` 意味着请求实际上是被允许的，
    因为模拟运行策略是工作负载上唯一的策略。

## 密钥和证书错误 {#keys-and-certificates-errors}

如果您怀疑 Istio 使用的某些密钥或证书不正确，您可以检查任何 Pod 的内容信息。

{{< text bash >}}
$ istioctl proxy-config secret sleep-8f795f47d-4s4t7
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           138092480869518152837211547060273851586     2020-11-11T16:39:48Z     2020-11-10T16:39:48Z
ROOTCA            CA             ACTIVE     true           288553090258624301170355571152070165215     2030-11-08T16:34:52Z     2020-11-10T16:34:52Z
{{< /text >}}

通过 `-o json` 标记，您可以将证书的全部内容传递给 `openssl` 来分析其内容：

{{< text bash >}}
$ istioctl proxy-config secret sleep-8f795f47d-4s4t7 -o json | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -noout -text
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
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
...
{{< /text >}}

确保显示的证书包含有效信息。特别是，`Subject Alternative Name` 字段应为
`URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`。

## 双向 TLS 错误 {#mutual-TLS-errors}

如果怀疑双向 TLS 出现了问题，首先要确认 istiod 的健康状态，
接下来要查看的是[密钥和证书正确下发到了](#keys-and-certificates-errors) Sidecar。

如果上述检查都正确无误，下一步就应该验证[认证策略](/zh/docs/tasks/security/authentication/authn-policy/)已经创建，
并且对应的目标规则是否正确应用。

如果您怀疑客户端 Sidecar 可能不正确地发送双向 TLS 或明文流量，
请检查 [Grafana 工作负载仪表盘](/zh/docs/ops/integrations/grafana/)。
无论是否使用 mTLS，都对出站请求添加注解。检查后，如果您认为客户端 Sidecar 是错误的，
请在 GitHub 上提交一个 Issue。
