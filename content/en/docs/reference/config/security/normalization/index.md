---
title: Authorization Policy Normalization
description: Describes the supported normalizations in authorization policies.
weight: 40
owner: istio/wg-security-maintainers
test: n/a
---

This page describes all the supported normalizations in the authorization policy. The normalized request will be used for
both the evaluation of authorization policies and the request that is ultimately sent to the backend server.

For more information, please refer to [authorization normalization best practices](/docs/ops/best-practices/security/#customize-your-system-on-path-normalization).

## Path Related

This applies to the `paths` and `notPaths` field.

### 1. Single percent-encoded character (%HH)

Istio will normalize the single percent-encoded character as follows (normalization happens only once, no double decoding):

| Percent-Encoded Character (case insensitive) | Normalized Result | Note | Enable |
|----------------------------------------------|-------------------|------|--------|
| `%00` | `N/A` | The request will always be rejected with HTTP code 400 | N/A |
| `%2d` | `-` | (dash) | Enabled by default with the normalization option `BASE` |
| `%2e` | `.` | (dot) | Enabled by default with the normalization option `BASE` |
| `%2f` | `/` | (forward slash) | Disabled by default, can be enabled with the normalization option `DECODE_AND_MERGE_SLASHES` |
| `%30` - `%39` | `0` - `9` | (digit) | Enabled by default with the normalization option `BASE` |
| `%41` - `%5a` | `A` - `Z` | (letters in uppercase) | Enabled by default with the normalization option `BASE` |
| `%5c` | `\` | (backslash) | Disabled by default, can be enabled with the normalization option `DECODE_AND_MERGE_SLASHES` |
| `%5f` | `_` | (underscore) | Enabled by default with the normalization option `BASE` |
| `%61` - `%7a` | `a` - `z` | (letters in lowercase) | Enabled by default with the normalization option `BASE` |
| `%7e` | `~` | (tilde) | Enabled by default with the normalization option `BASE` |

For example, the request with path `/some%2fdata/%61%62%63` will be normalized to `/some/data/abc`.

### 2. Backslash (`\`)

Istio will normalize the backslash `\` to the forward slash `/`. For example, the request with path `/some\data`
will be normalized to `/some/data`.

This is enabled by default with the normalization option `BASE`.

### 3. Multiple forward slashes (`//`, `///`, etc.)

Istio will merge multiple forward slashes to a single forward slash (`/`). For example, the request
with path `/some//data///abc` will be normalized to `/some/data/abc`.

This is disabled by default but can be enabled with the normalization option `MERGE_SLASHES`.

### 4. Single dot and double dots (`/./`, `/../`)

Istio will resolve single dot `/./` and double dot `/../` according to [RFC 3986](https://tools.ietf.org/html/rfc3986#section-6).
The single dot will be resolved as the current directory, and the double dots will be resolved as the parent directory.

For example, `/public/./data/abc/../xyz` will be normalized to `/public/data/xyz`.

This is enabled by default with the normalization option `BASE`.

### 5. Path with query (`/foo?v=1`)

Istio authorization policy will remove anything after the question mark (`?`) when comparing with the path. Note the
backend application will still see the query.

This is enabled by default.

## Method related

This applies to the `methods` and `notMethods` field.

### 1. Method not in upper case

Istio will reject requests with HTTP 400 if the verb in the HTTP request is not in upper case.

This is enabled by default.

## Header name related

This applies to the header name specified in the `request.headers[<header-name>]` condition.

### 1. Case-insensitive matching

Istio authorization policy will compare the header name with a case-insensitive approach.

This is enabled by default.

### 2. Duplicate headers

Istio will merge duplicate headers to a single header by concatenating all values using comma as a separator.

The authorization policy will do a simple string match on the merged headers. For example, a request with header
`x-header: foo` and `x-header: bar` will be merged to `x-header: foo,bar`.

This is enabled by default.

### 3. White space in header name

Istio will reject requests with HTTP 400 if the header name includes any white spaces.

This is enabled by default.
