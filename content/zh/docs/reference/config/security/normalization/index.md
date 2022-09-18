---
title: 授权策略规范化
description: 描述授权策略中支持的规范化操作。
weight: 40
owner: istio/wg-security-maintainers
test: n/a
---

本页说明授权策略中支持的所有规范化操作。规范化请求将用于评估授权策略和最终发送到后端服务器的请求。

有关更多信息，请参阅[授权规范化最佳实践](/zh/docs/ops/best-practices/security/#customize-your-system-on-path-normalization)。

## 相关路径{#path-related}

这适用于 `paths` 和 `notPaths` 字段。

### 1. 单个百分比编码的字符 (%HH){#single-percent-encoded-character}

如下表所示，Istio 将规范化单个百分比编码的字符（规范化仅发生一次，不会有两次编码）：

| 百分比编码的字符（不区分大小写） | 规范化结果 | 注释 | 启用 |
|----------------------------------------------|-------------------|------|--------|
| `%00` | `N/A` | 该请求将始终被拒绝并给出 HTTP code 400 | N/A |
| `%2d` | `-` | (短划线) | 默认用规范化选项 `BASE` 启用 |
| `%2e` | `.` | (英文句点) | 默认用规范化选项 `BASE` 启用 |
| `%2f` | `/` | (斜杠) | 默认禁用，可以用规范化选项 `DECODE_AND_MERGE_SLASHES` 启用 |
| `%30` - `%39` | `0` - `9` | (数字) | 默认用规范化选项 `BASE` 启用 |
| `%41` - `%5a` | `A` - `Z` | (大写字母) | 默认用规范化选项 `BASE` 启用 |
| `%5c` | `\` | (反斜杠) | 默认禁用，可以用规范化选项 `DECODE_AND_MERGE_SLASHES` 启用 |
| `%5f` | `_` | (下划线) | 默认用规范化选项 `BASE` 启用 |
| `%61` - `%7a` | `a` - `z` | (小写字母) | 默认用规范化选项 `BASE` 启用 |
| `%7e` | `~` | (英文波浪线) | 默认用规范化选项 `BASE` 启用 |

例如，带路径 `/some%2fdata/%61%62%63` 的请求将被规范化为 `/some/data/abc`。

### 2. 反斜杠 (`\`){#backslash}

Istio 将把反斜杠 `\` 规范化为斜杠 `/`。例如带路径 `/some\data` 的请求将被规范化为 `/some/data`。

这默认用规范化选项 `BASE` 启用.

### 3. 多个斜杠（`//`、`///` 等）{#multiple-forward-slashes}

Istio 将把多个斜杠合并为单个斜杠 (`/`)。例如，带路径 `/some//data///abc` 的请求将被规范化为 `/some/data/abc`。

这被默认禁用，但可以用规范化选项 `MERGE_SLASHES` 启用。

### 4. 一个和两个英文句点（`/./`、`/../`）{#single-dot-and-double-dots}

Istio 将按照 [RFC 3986](https://tools.ietf.org/html/rfc3986#section-6) 解析一个英文句点 `/./` 和两个英文句点 `/../`。
一个英文句点将被解析为当前目录，而两个英文句点将被解析为父级目录。

例如，`/public/./data/abc/../xyz` 将被规范化为 `/public/data/xyz`。

这默认用规范化选项 `BASE` 启用.

### 4. 带查询的路径 (`/foo?v=1`){#path-with-query}

Istio 授权策略在比较路径时将移除问号 (`?`) 后的所有内容。请注意，后端应用程序将仍然看到此查询。

这默认启用。

## 相关方法{#method-related}

这适用于 `methods` 和 `notMethods` 字段。

### 1. 非大写的方法{#method-not-in-upper-case}

如果 HTTP 请求中的动词不是大写，Istio 将拒绝这些请求并返回 HTTP 400。

这默认启用。

## 相关头名称{#header-name-related}

这适用于 `request.headers[<header-name>]` 条件中指定的头名称。

### 1. 不区分大小写的匹配{#case-insensitive-matching}

Istio 授权策略将以不区分大小写的方法来比较头名称。

这默认启用。

### 2. 重复的头{#duplicate-headers}

Istio 将使用英文逗号作为分隔符串联所有值，将重复的头合并为一个头。

授权策略将对合并的头执行简单的字符串匹配。例如，头为 `x-header: foo` 和 `x-header: bar` 的请求将被合并为 `x-header: foo,bar`。

这默认启用。

### 3. 头名称中的空格{#white-space-in-header-name}

如果头名称包含任何空格，Istio 将拒绝这些请求并返回 HTTP 400。

这默认启用。
