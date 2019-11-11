---
title: Announcing Istio 0.7
subtitle: Major Update
description: Istio 0.7 announcement.
publishdate: 2018-03-28
release: 0.7.0
aliases:
    - /about/notes/0.7
    - /about/notes/0.7/index.html
    - /news/announcing-0.7
---

For this release, we focused on improving our build and test infrastructures and increasing the
quality of our tests. As a result, there are no new features for this month.

{{< relnote >}}

Please note that this release includes preliminary support for the new v1alpha3 traffic management
functionality. This functionality is still in a great deal of flux and there may be some breaking
changes in 0.8. So if you feel like exploring, please go right ahead, but expect that this may
change in 0.8 and beyond.

Known Issues:

Our [Helm chart](/docs/setup/install/helm)
currently requires some workaround to apply the chart correctly, see [4701](https://github.com/istio/istio/issues/4701) for details.
