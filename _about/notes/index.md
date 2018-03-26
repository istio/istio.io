---
title: Release Notes
overview: Istio releases information.

order: 5

layout: about
type: markdown
redirect_from:
  - "/docs/reference/release-notes.html"
  - "/release-notes"
  - "/docs/welcome/notes/index.html"
  - "/docs/references/notes"
toc: false  
---

{% include section-index.html docs=site.about %}


- The [latest](https://github.com/istio/istio/releases) Istio monthly release is {{site.data.istio.version}}. It is downloaded when the following is used(*):
  ```
  curl -L https://git.io/getLatestIstio | sh -
  ```

- The most recent 'stable' release is [0.2.12](https://github.com/istio/istio/releases/tag/0.2.12), the matching docs are [archive.istio.io/v0.2/docs/](https://archive.istio.io/v0.2/docs/)
  ```
  curl -L https://git.io/getIstio | sh -
  ```

We typically wait to 'bake' the latest release for several weeks and ensure it is more stable than the previous one before promoting it to stable.

> (*) Note: security conscious users should examine the output of the curl command before piping it to a shell.
