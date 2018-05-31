---
title: Expression Language
description: Mixer config expression language reference.
weight: 20
aliases:
    - /docs/reference/config/mixer/expression-language.html
---

This page describes how to use the Mixer config expression language (CEXL).

## Background

Mixer configuration uses an expression language (CEXL) to specify match expressions and [mapping expressions](/docs/concepts/policies-and-telemetry/config/#attribute-expressions). CEXL expressions map a set of typed [attributes](/docs/concepts/policies-and-telemetry/config/#attributes) and constants to a typed
[value](https://github.com/istio/api/blob/master/policy/v1beta1/value_type.proto).

## Syntax

CEXL accepts a subset of **[Go expressions](https://golang.org/ref/spec#Expressions)**, which defines the syntax. CEXL implements a subset of the Go operators that constrains the set of accepted Go expressions. CEXL also supports arbitrary parenthesization.

## Functions

CEXL supports the following functions.

|Operator/Function |Definition |Example | Description|
|------------------|-----------|--------|------------|
|`==` |Equals |`request.size == 200`
|`!=` |Not Equals |`request.auth.principal != "admin"`
|`\|\|` |Logical OR | `(request.size == 200) \|\| (request.auth.principal == "admin")`
|`&&` |Logical AND | `(request.size == 200) && (request.auth.principal == "admin")`
|`[ ]` |Map Access | `request.headers["x-id"]`
|`\|` |First non empty | `source.labels["app"] \| source.labels["svc"] \| "unknown"`
|`match` | Glob match |`match(destination.service, "*.ns1.svc.cluster.local")` | Matches prefix or suffix based on the location of `*`
|`email` | Convert a textual e-mail into the `EMAIL_ADDRESS` type | `email("awesome@istio.io")` | Use the `email` function to create an `EMAIL_ADDRESS` literal.
|`dnsName` | Convert a textual DNS name into the `DNS_NAME` type | `dnsName("www.istio.io")` | Use the `dnsName` function to create a `DNS_NAME` literal.
|`ip` | Convert a textual IPv4 address into the `IP_ADDRESS` type | `source.ip == ip("10.11.12.13")` | Use the `ip` function to create an `IP_ADDRESS` literal.
|`timestamp` | Convert a textual timestamp in RFC 3339 format into the `TIMESTAMP` type | `timestamp("2015-01-02T15:04:35Z")` | Use the `timestamp` function to create a `TIMESTAMP` literal.
|`uri` | Convert a textual URI into the `URI` type | `uri("http://istio.io")` | Use the `uri` function to create a `URI` literal.
|`.matches` | Regular expression match | `"svc.*".matches(destination.service)` | Matches `destination.service` against regular expression pattern `"svc.*"`.
|`.startsWith` | string prefix match | `destination.service.startsWith("acme")` | Checks whether `destination.service` starts with `"acme"`.
|`.endsWith` | string postfix match | `destination.service.endsWith("acme")`  | Checks whether `destination.service` ends with `"acme"`.

## Type checking

CEXL variables are attributes from the typed [attribute vocabulary](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/), constants are implicitly typed and, functions are explicitly typed.

Mixer validates a CEXL expression and resolves it to a type during config validation.
Selectors must resolve to a boolean value and mapping expressions must resolve to the type they are mapping into. Config validation fails if a selector fails to resolve to a boolean or if a mapping expression resolves to an incorrect type.

For example, if an operator specifies a *string* label as `request.size | 200`, validation fails because the expression resolves to an integer.

## Missing attributes

If an expression uses an attribute that is not available during request processing, the expression evaluation fails. Use the `|` operator to provide a default value if an attribute may be missing.

For example, the expression `request.auth.principal == "user1"` fails evaluation if the `request.auth.principal` attribute is missing. The `|` (OR) operator addresses the problem: `(request.auth.principal | "nobody" ) == "user1"`.

## Examples

|Expression |Return Type |Description|
|-----------|------------|-----------|
|`request.size \| 200` |  **int** | `request.size` if available, otherwise 200.
|`request.headers["X-FORWARDED-HOST"] == "myhost"`| **boolean**
|`(request.headers["x-user-group"] == "admin") \|\| (request.auth.principal == "admin")`| **boolean**| True if the user is admin or in the admin group.
|`(request.auth.principal \| "nobody" ) == "user1"` | **boolean** | True if `request.auth.principal` is "user1", The expression will not error out if `request.auth.principal` is missing.
|`source.labels["app"]=="reviews" && source.labels["version"]=="v3"`| **boolean** | True if app label is reviews and version label is v3, false otherwise.
