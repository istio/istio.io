---
title: ISTIO-SECURITY-2019-002
subtitle: Security Bulletin
description: Security vulnerability disclosure for CVE-2019-12995.
cves: [CVE-2019-12995]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F/RL:O/RC:C"
releases: ["1.0 to 1.0.8", "1.1 to 1.1.9", "1.2 to 1.2.1"]
publishdate: 2019-06-28
keywords: [CVE]
skip_seealso: true
aliases:
    - /blog/2019/cve-2019-12995
    - /news/2019/cve-2019-12995
---

{{< security_bulletin >}}

A bug in Istio’s JWT validation filter causes Envoy to crash in certain cases when the request contains a malformed JWT token. The bug was discovered and reported by a user [on GitHub](https://github.com/istio/istio/issues/15084) on June 23, 2019.

This bug affects all versions of Istio that are using the JWT authentication policy.

The symptoms of the bug are an HTTP 503 error seen by the client, and

{{< text plain >}}
Epoch 0 terminated with an error: signal: segmentation fault (core dumped)
{{< /text >}}

in the Envoy logs.

The Envoy crash can be triggered using a malformed JWT without a valid signature, and on any URI being accessed regardless of the `trigger_rules` in the JWT specification. Thus, this bug makes Envoy vulnerable to a potential DoS attack.

## Impact and detection

Envoy is vulnerable if the following two conditions are satisfied:

* A JWT authentication policy is applied to it.
* The JWT issuer (specified by `jwksUri`) uses the RSA algorithm for signature verification

{{< tip >}}
The RSA algorithm used for signature verification does not contain any known security vulnerability.  This CVE is triggered only when using this algorithm but is unrelated to the security of the system.
{{< /tip >}}

If JWT policy is applied to the Istio ingress gateway, please be aware that any external user who has access to the ingress gateway could crash it with a single HTTP request.

If JWT policy is applied to the sidecar only, please keep in mind it might still be vulnerable. For example, the Istio ingress gateway might forward the JWT token to the sidecar which could be a malformed JWT token that crashes the sidecar.

A vulnerable Envoy will crash on an HTTP request with a malformed JWT token. When Envoy crashes, all existing connections will be disconnected immediately. The `pilot-agent` will restart the crashed Envoy automatically and it may take a few seconds to a few minutes for the restart. pilot-agent will stop restarting Envoy after it crashed more than ten times. In this case, Kubernetes will redeploy the pod, including the workload behind Envoy.

To detect if there is any JWT authentication policy applied in your cluster, run the following command which print either of the following output:

* Found JWT in authentication policy, **YOU ARE AFFECTED**
* Did NOT find JWT in authentication policy, *YOU ARE NOT AFFECTED*

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
  echo "${red}Found JWT in authentication policy, YOU ARE AFFECTED${reset}"
  exit 1
fi

echo "${green}Did NOT find JWT in authentication policy, YOU ARE NOT AFFECTED${reset}"
EOF
{{< /text >}}

## Mitigation

This bug is fixed in the following Istio releases:

* For Istio 1.0.x deployments: update to [Istio 1.0.9](/news/releases/1.0.x/announcing-1.0.9) or later.
* For Istio 1.1.x deployments: update to [Istio 1.1.10](/news/releases/1.1.x/announcing-1.1.10) or later.
* For Istio 1.2.x deployments: update to [Istio 1.2.2](/news/releases/1.2.x/announcing-1.2.2) or later.

If you cannot immediately upgrade to one of these releases, you have the additional option of injecting a
[Lua filter](https://github.com/istio/tools/tree/master/examples/luacheck) into older releases of Istio.
This filter has been verified to work with Istio 1.1.9, 1.0.8, 1.0.6, and 1.1.3.

The Lua filter is injected *before* the Istio `jwt-auth` filter.
If a JWT token is presented on an http request, the `Lua` filter will check if the JWT token header contains alg:ES256. If the filter finds such a JWT token, the request is rejected.

To install the Lua filter, please invoke the following commands:

{{< text bash >}}
$ git clone git@github.com:istio/tools.git
$ cd tools/examples/luacheck/
$ ./setup.sh
{{< /text >}}

The setup script uses helm template to produce an `envoyFilter` resource that deploys to gateways. You may change the listener type to `ANY` to also apply it to sidecars. You should only do this if you enforce JWT policies on sidecars *and* sidecars receive direct traffic from the outside.

## Credit

The Istio team would like to thank Divya Raj for the original bug report.

{{< boilerplate "security-vulnerability" >}}
