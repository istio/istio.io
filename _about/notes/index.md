---
title: Release Notes
description: Description of features and improvements for every Istio release.

weight: 5

redirect_from:
  - "/docs/reference/release-notes.html"
  - "/release-notes"
  - "/docs/welcome/notes/index.html"
  - "/docs/references/notes"
toc: false
---
{% include section-index.html docs=site.about %}

The latest Istio monthly release is {{site.data.istio.version}} ([release notes]({{site.data.istio.version}}.html)). You can
[download {{site.data.istio.version}}](https://github.com/istio/istio/releases) with:

```command
$ curl -L https://git.io/getLatestIstio | sh -
```

The most recent stable release is 0.2.12. You can [download 0.2.12](https://github.com/istio/istio/releases/tag/0.2.12) with:

```command
$ curl -L https://git.io/getIstio | sh -
```

[Archived documentation for the 0.2.12 release](https://archive.istio.io/v0.2/docs/).

> As we don't control the `git.io` domain, please examine the output of the `curl` command before piping it to a shell if running in any
sensitive or non-sandboxed environment.
