---
title: Istio 1.14 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.14.0.
publishdate: 2022-05-24
weight: 20
---

When you upgrade from Istio 1.13.x to Istio 1.14.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.14.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.13.x`.
Users upgrading from 1.12.x to Istio 1.14.0 should also reference the [1.13.0 change logs](/news/releases/1.13.x/announcing-1.13/change-notes/).

## `gogo/protobuf` library migration

The `istio.io/api` and `istio.io/client-go` libraries have switched from using the [`gogo/protobuf`](https://github.com/gogo/protobuf)
to using the [`golang/protobuf`](https://github.com/golang/protobuf) library for API types.

This change does not have any impact on typical Istio users, but rather impacts users importing Istio as a Go library.

For these users, upgrading the Istio libraries will likely cause compilation issues. These issues are typically simple to address,
and largely syntactical. The [Go blog](https://go.dev/blog/protobuf-apiv2) on the new protobuf API can help with migration.
