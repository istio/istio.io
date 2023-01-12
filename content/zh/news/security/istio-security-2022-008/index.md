---
title: ISTIO-SECURITY-2022-008
subtitle: 安全公告
description: 用户具有 localhost 访问权限时有身份模仿的风险。
cves: [CVE-2022-39388]
cvss: "7.6"
vector: "CVSS:3.1/AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.15.2"]
publishdate: 2022-11-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39388

- __[CVE-2022-39388](https://github.com/istio/istio/security/advisories/GHSA-6c6p-h79f-g6p4)__:
  (CVSS Score 7.6, High)：用户具有 localhost 访问权限时有身份模仿的风险。

如果用户能够从 localhost 访问 Istiod 控制平面，该用户可以在服务网格内模仿任何工作负载身份。

## 我受到影响了吗？{#am-i-impacted}

如果您正在运行 Istio 1.15.2 且用户有权限访问正运行 Istiod 的机器，那么您面临的风险很大。
