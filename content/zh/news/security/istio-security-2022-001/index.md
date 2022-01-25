---
title: ISTIO-SECURITY-2022-001
subtitle: 安全公告
description: Authorization Policy For Host Rules During Upgrades.
cves: [CVE-2022-21679]
cvss: "6.8"
vector: "AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:N"
releases: ["1.12.0 to 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE{#CVE}

### CVE-2022-21679{#CVE-2022-21679}

Istio 1.12.0/1.12.1 会为 1.11 版本的代理生成不正确的配置，影响授权策略中的 `hosts` 和 `notHosts` 字段。错误的配置可能会导致请求在使用 `hosts` 和 `notHosts` 字段时意外绕过或被授权策略拒绝。

当 1.12.0/1.12.1 控制平面和 1.11 数据平面混合使用，并在授权策略中使用 `hosts` 或 `notHosts` 字段时，会出现该问题。

### 补救措施{#mitigation}

* 升级到最新的 1.12.2 或者；
* 如果在授权策略中使用 `hosts` 或者 `notHosts` 字段，请勿将 1.12.0/1.12.1 控制平面和 1.11 数据平面混合使用。

## 赞扬{#credit}

我们要感谢 Yangmin Zhu 和 @Aakash2017。
