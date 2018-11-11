---
title: Denier
description: 始终返回按前提条件拒绝的适配器。
weight: 70
---

该 `denier` 适配器设计为始终返回一个否定预处理检查。您可以为这些拒绝指定要返回的确切错误。

此适配器支持 [checknothing 模板](/zh/docs/reference/config/policy-and-telemetry/templates/checknothing/)，[listentry 模板](/zh/docs/reference/config/policy-and-telemetry/templates/listentry/)和[配额模板](/zh/docs/reference/config/policy-and-telemetry/templates/quota/) 。

## PARAMS

Denier 适配器的配置格式。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `status` | [google.rpc.Status](#google-rpc-Status) | 拒绝请求时返回的错误。|
| `validDuration` | [google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) | 拒绝有效的持续时间。|
| `validUseCount` | `int32` | 拒绝可以使用的次数。|

## google.rpc.Status

该 `Status` 类型定义了适用于不同编程环境的逻辑错误模型，包括 REST API 和 RPC API。它由 [gRPC 使用](https://github.com/grpc)。错误模型旨在：

*   易于使用和理解大多数用户
*   足够灵活，以满足意外的需求

### 概述

该 `Status` 消息包含三个数据：错误代码，错误消息和错误详细信息。错误代码应为 *google.rpc.Code* 的枚举值，但如果需要，它可能会接受其他错误代码。错误消息应该是面向开发人员的英语消息，可帮助开发人员 *理解* 并 *解决* 错误。如果需要本地化的面向用户的错误消息，请将本地化消息放在错误详细信息中或在客户端中将其本地化。可选的错误详细信息可能包含有关错误的任意信息。包中有一组预定义的错误详细信息类型 `google.rpc`，可用于常见错误条件。

### 语言映射

该 `Status` 消息是误差模型的逻辑表示，但它不一定是实际的格式。当 `Status` 消息在不同的客户端库和不同的协议中公开时，它可以以不同的方式映射。例如，它可能会映射到 Java 中的某些异常，但也可以映射到 C 中的某些错误代码。

### 其他用途

错误模型和 `Status` 消息可以在各种环境中使用，无论是否有 API，以在不同环境中提供一致的开发人员体验。

此错误模型的示例用法包括：

*   部分错误。如果服务需要将部分错误返回给客户端，则可以将其嵌入 `Status` 到正常响应中以指示部分错误。

*   工作流程错误。典型的工作流程有多个步骤。每个步骤都可能有 `Status` 错误报告消息。

*   批量操作。如果客户端使用批处理请求和批处理响应， `Status` 则应在批处理响应中直接使用 该 消息，每个错误子响应一个消息。

*   异步操作。如果 API 调用在其响应中嵌入异步操作结果，则应使用该 `Status` 消息 直接表示这些操作的状态。

*   日志记录。如果某些 API 错误存储在日志中，则 `Status` 出于安全/隐私原因需要进行任何剥离后，可以直接使用该消息。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `code` | `int32` | 状态代码，应该是 *google.rpc.Code* 的枚举值。|
| `message` | `string` | 面向开发人员的错误消息，应该是英文的。任何面向用户的错误消息都应进行本地化，并在 `google.rpc.Status.details` 字段中发送，或由客户端进行本地化。|
| `details` | [google.protobuf.Any[]](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Any) | 带有错误详细信息的消息列表。API有一组通用的消息类型可供使用。|