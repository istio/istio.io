---
title: Status RPC
overview: Google's rpc.Status proto

order: 40

layout: docs
type: markdown
---

<a name="rpcGoogle.rpcIndex"></a>
### Index

* [Status](#google.rpc.Status)
(message)

<a name="google.rpc.Status"></a>
### Status
The `Status` type defines a logical error model that is suitable for different
programming environments, including REST APIs and RPC APIs. It is used by
[gRPC](https://github.com/grpc). The error model is designed to be:

- Simple to use and understand for most users
- Flexible enough to meet unexpected needs



<a name="rpcGoogle.rpcGoogle.rpc.StatusDescriptionSubsection"></a>
#### Overview
The `Status` message contains three pieces of data: error code, error message,
and error details. The error code should be an enum value of
[google.rpc.Code](#google.rpc.Code), but it may accept additional error codes if needed.  The
error message should be a developer-facing English message that helps
developers *understand* and *resolve* the error. If a localized user-facing
error message is needed, put the localized message in the error details or
localize it in the client. The optional error details may contain arbitrary
information about the error. There is a predefined set of error detail types
in the package `google.rpc` that can be used for common error conditions.



<a name="rpcGoogle.rpcGoogle.rpc.StatusDescriptionSubsection_1"></a>
#### Language mapping
The `Status` message is the logical representation of the error model, but it
is not necessarily the actual wire format. When the `Status` message is
exposed in different client libraries and different wire protocols, it can be
mapped differently. For example, it will likely be mapped to some exceptions
in Java, but more likely mapped to some error codes in C.



<a name="rpcGoogle.rpcGoogle.rpc.StatusDescriptionSubsection_2"></a>
#### Other uses
The error model and the `Status` message can be used in a variety of
environments, either with or without APIs, to provide a
consistent developer experience across different environments.

Example uses of this error model include:

- Partial errors. If a service needs to return partial errors to the client,
    it may embed the `Status` in the normal response to indicate the partial
    errors.

- Workflow errors. A typical workflow has multiple steps. Each step may
    have a `Status` message for error reporting.

- Batch operations. If a client uses batch request and batch response, the
    `Status` message should be used directly inside batch response, one for
    each error sub-response.

- Asynchronous operations. If an API call embeds asynchronous operation
    results in its response, the status of those operations should be
    represented directly using the `Status` message.

- Logging. If some API errors are stored in logs, the message `Status` could
    be used directly after any stripping needed for security/privacy reasons.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="google.rpc.Status.code"></a>
 <tr>
  <td><code>code</code></td>
  <td>int32</td>
  <td>The status code, which should be an enum value of <a href="#google.rpc.Code">google.rpc.Code</a>.</td>
 </tr>
<a name="google.rpc.Status.message"></a>
 <tr>
  <td><code>message</code></td>
  <td>string</td>
  <td>A developer-facing error message, which should be in English. Any user-facing error message should be localized and sent in the <a href="#google.rpc.Status.details">google.rpc.Status.details</a> field, or localized by the client.</td>
 </tr>
<a name="google.rpc.Status.details"></a>
 <tr>
  <td><code>details[]</code></td>
  <td>repeated <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a></td>
  <td>A list of messages that carry the error details. There will be a common set of message types for APIs to use.</td>
 </tr>
</table>
