---
title: UnknownUpgradeCompatibility
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a configuration setting that you use changed its default behavior in a new
release of Istio, and Istio cannot find automatically if the change has an effect on your mesh.

## How to resolve

Read the text of the message and the upgrade notes for the release. Then do one of these:

- Make sure that the new behavior is correct for your mesh.
- Install with `--set compatibilityVersion=<version>` to keep the old default behavior.
  For more information, refer to [Compatibility Versions](/docs/setup/additional-setup/compatibility-versions/).
