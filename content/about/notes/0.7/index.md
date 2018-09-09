---
title: Istio 0.7
weight: 94
icon: /img/notes.svg
---

For this release, we focused on improving our build and test infrastructures and increasing the
quality of our tests. As a result, there are no new features for this month.

{{< relnote_links >}}

However, this release does include a large number of bug fixes and performance improvements.

Please note that this release includes preliminary support for the new v1alpha3 traffic management
functionality. This functionality is still in a great deal of flux and there may be some breaking
changes in 0.8. So if you feel like exploring, please go right ahead, but expect that this may
change in 0.8 and beyond.

Known Issues:

Our [Helm chart](/docs/setup/kubernetes/helm-install/)
currently requires some workaround to apply the chart correctly, see [4701](https://github.com/istio/istio/issues/4701) for details.
