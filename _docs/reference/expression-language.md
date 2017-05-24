---
title: Mixer Config Expression Language
overview: Mixer config expression language reference.

order: 43

layout: docs
type: markdown
---
{% include home.html %}

{% capture mixerConfig %}{{home}}/docs/concepts/policy-and-control/mixer-config.html{% endcapture %}

This page describes how to use the Mixer config expression language (CEXL).

## Background

Mixer configuration uses an expression language (CEXL) to specify [selectors]({{mixerConfig}}#selectors) and [mapping expressions]({{mixerConfig}}#attribute-expressions). CEXL expressions map a set of typed [attributes]({{home}}/docs/concepts/policy-and-control/attributes.html) and constants to a typed [value](https://github.com/istio/api/blob/master/mixer/v1/config/descriptor/value_type.proto#L23).
  
```
f(attr0, attr1, ..., constant0, constant1, ...) --> value
```

## Syntax

CEXL accepts a subset of the **golang** expressions, which defines the syntax. CEXL parses a string input using the builtin [golang parser](https://golang.org/pkg/go/parser/#ParseExpr) to produce a simplified AST that consists of functions, variables and, constants. CEXL treats operators as functions and implements a subset of the golang operators that constrains the set of accepted expressions. CEXL supports arbitrary parenthesization. 

## Functions

CEXL supports the following functions.

|Operator |Function  |Description |Example 
|------------------------------------
|`==` |EQ |Equals |`request.size == 200` 
|`==` |EQ |Equals Prefix|`service.name == "svc1.*"` 
|`==` |EQ |Equals Suffix|`service.name == "*.ns1.svc.cluster.local"` 
|`!=` |NE |Not Equals |`request.user != "admin"`
|`||` |LOR | Logical OR | `(request.size == 200) || (request.user == "admin")` 
|`&&` |LAND | Logical AND | `(request.size == 200) && (request.user == "admin")` 
|`[ ]` |INDEX | Map Access | `request.headers["x-id"]`
|`|` |OR | First non empty | `source.labels["app"] | source.labels["svc"] | "unknown"`

Mixer developers can add new CEXL functions by implementing the [Func interface](https://github.com/istio/mixer/blob/master/pkg/expr/func.go#L39).

## Typechecking

CEXL variables are attributes from the typed [attribute vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html), constants are implicitly typed and, functions are explicitly typed.

Mixer validates a CEXL expression and resolves it to a type during config validation.
Selectors must resolve to a boolean value and mapping expressions must resolve to the type they are mapping into. Config validation fails if a selector fails to resolve to a boolean or if a mapping expression resolves to an incorrect type. 

If an operator specifies a *string* label as `request.size | 200`, validation fails because the expression resolves to an integer.

## Missing attributes

If an expression uses an attribute that is not available during request processing, the expression evaluation fails. Use the `|` operator to provide a default value if an attribute may be missing. 

The expression `request.user == "user1"` fails evaluation if the request.user attribute is missing. The `|` (OR) operator addresses the problem: `(request.user | "nobody" ) == "user1"`.

## Examples

|Expression |Return Type |Description
|------------------------------------
|`request.size| 200` |  **int** | request.size if available, otherwise 200.
|`request.header["X-FORWARDED-HOST"] == "myhost"`| **boolean** 
|`(request.header["x-user-group"] == "admin") || (request.user == "admin")`| **boolean**| True if the user is admin or in the admin group.
|`(request.user | "nobody" ) == "user1"` | **boolean** | True if request.user is "user1", The expression will not error out if request.user is missing.
|`source.labels["app"]=="reviews" && source.labels["version"]=="v3"`| **boolean** | True if app label is reviews and version label is v3, false otherwise.

A comprehensive list of examples is in the [expression tests](https://github.com/istio/mixer/blob/master/pkg/expr/eval_test.go#L33).
