---
title: ISTIO-SECURITY-2019-002
subtitle: 安全公告
description: CVE-2019-12995 所披露的安全漏洞。
cves: [CVE-2019-12995]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F/RL:O/RC:C"
releases: ["1.0 to 1.0.8", "1.1 to 1.1.9", "1.2 to 1.2.1"]
publishdate: 2019-06-28
keywords: [CVE]
skip_seealso: true
aliases:
    - /zh/blog/2019/cve-2019-12995
    - /zh/news/2019/cve-2019-12995
---

{{< security_bulletin >}}

当请求包含格式错误的 JWT 令牌时，Istio JWT 认证过滤器中的 BUG 会导致 Envoy 在某些情况下崩溃。该 BUG 已由一个用户在 [GitHub](https://github.com/istio/istio/issues/15084) 上于 2019 年 6 月 23 日发现并报告。

此 BUG 会影响所有正在使用 JWT 身份认证策略的 Istio 版本。

此 BUG 会导致客户端收到 HTTP 503 错误，并且 Envoy 会有以下日志。

{{< text plain >}}
Epoch 0 terminated with an error: signal: segmentation fault (core dumped)
{{< /text >}}

无论 JWT 规范中的 `trigger_rules` 如何设置，Envoy 都可能因为格式错误的 JWT token (没有有效的签名) 崩溃，导致所有 URI 访问不受限制。因此，这个 BUG 使 Envoy 容易受到潜在的 DoS 攻击。

## 影响范围{#impact-and-detection}

如果满足以下两个条件，则 Envoy 将很容易受到攻击：

* 使用了 JWT 身份认证策略。
* 使 JWT Issuer(由 `jwksUri` 发行) 使用 RSA 算法进行签名认证。

{{< tip >}}
用于签名认证的 RSA 算法不包含任何已知的安全漏洞。仅当使用此算法时才触发此 CVE，但与系统的安全性无关。
{{< /tip >}}

如果将 JWT 策略应用于 Istio Ingress Gateway。请注意，有权访问 Ingress Gateway 的任何外部用户都可以通过单个 HTTP 请求导致它崩溃。

如果仅将 JWT 策略应用 Sidecar，请记住它仍然可能受到攻击。例如，Istio Ingress Gateway 可能会将 JWT Token 转发到 Sidecar，这可能是格式错误的 JWT Token ，该 Token 可能让 Sidecar 崩溃。

易受攻击的 Envoy 将在处理 JWT Token 格式错误的 HTTP 请求上崩溃。当 Envoy 崩溃时，所有现有连接将立即断开连接。`pilot-agent` 将自动重启崩溃的 Envoy，重启可能需要几秒钟到几分钟的时间。崩溃超过十次后，pilot-agent 将停止重新启动 Envoy。在这种情况下，Kubernetes 将重新部署 Pod，包括 Envoy 的工作负载。

要检测集群中是否应用了任何 JWT 身份认证策略，请运行以下命令，该命令将显示以下任一输出：

* 在身份认证策略中找到了 JWT, **你会收到影响**
* 未在身份认证策略中找到 JWT, *你不会会收到影响*

{{< text bash >}}
$ cat <<'EOF' | bash -
set -e
set -u
set -o pipefail

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "Checking authentication policy..."

JWKS_URI=()
JWKS_URI+=($(kubectl get policy --all-namespaces -o jsonpath='{range .items[*]}{.spec.origins[*].jwt.jwksUri}{" "}{end}'))
JWKS_URI+=($(kubectl get meshpolicy --all-namespaces -o jsonpath='{range .items[*]}{.spec.origins[*].jwt.jwksUri}{" "}{end}'))
if [ "${#JWKS_URI[@]}" != 0 ]; then
  echo "${red}在身份认证策略中找到了 JWT, 你会收到影响${reset}"
  exit 1
fi

echo "${green}未在身份认证策略中找到 JWT, 你不会受到影响${reset}"
EOF
{{< /text >}}

## 防范{#mitigation}

在以下 Istio 发行版中已修复此 BUG：

* Istio 1.0.x： 升级到 [Istio 1.0.9](/zh/news/releases/1.0.x/announcing-1.0.9) 或者更新高版本。
* Istio 1.1.x： 升级到 [Istio 1.1.10](/zh/news/releases/1.1.x/announcing-1.1.10) 或者更新高版本。
* Istio 1.2.x： 升级到 [Istio 1.2.2](/zh/news/releases/1.2.x/announcing-1.2.2) 或者更新高版本。

如果您无法立即升级到以下版本之一，则可以选择注入一个 [Lua Filter](https://github.com/istio/tools/tree/master/examples/luacheck) 到老的 Istio 版本中。Istio 1.1.9、1.0.8、1.0.6、和 1.1.3 将会进行该认证。

Lua 过滤器是在 Istio `jwt-auth` 过滤器 *之前* 注入的。如果在 HTTP 请求中提供了 JWT 令牌，则 `Lua` 过滤器将检查 JWT 令牌头是否包含 alg:ES256 。如果过滤器找到了这样的 JWT 令牌，则该请求将被拒绝。

要安装 Lua 过滤器，请执行以下命令：

{{< text bash >}}
$ git clone git@github.com:istio/tools.git
$ cd tools/examples/luacheck/
$ ./setup.sh
{{< /text >}}

安装脚本使用 Helm 模板来生成一个 `envoyFilter` 资源，该资源将部署到 Gateway。您可以将 Listener 类型更改为 `ANY`，以将其也应用到 Sidecar。只有当您在 Sidecar 上强制使用 JWT 身份认证策略，并在直接接收外部的请求，才应该这样做。

## 致谢{#credit}

Istio 团队非常感谢 Divya Raj 的原始 BUG 报告。

{{< boilerplate "security-vulnerability" >}}
