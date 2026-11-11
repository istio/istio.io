---
title: UpdateIncompatibility
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when [`istioctl x precheck`](/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
finds configuration that can work differently after you upgrade Istio. The default behavior of a
setting changed in the new release.

## How to resolve

Read the text of the message. It tells you which setting changed, and in which release. Then do one
of these:

- Change your configuration so that it works with the new behavior.
- Install with `--set compatibilityVersion=<version>` to keep the old default behavior.
  For more information, refer to [Compatibility Versions](/docs/setup/additional-setup/compatibility-versions/).
