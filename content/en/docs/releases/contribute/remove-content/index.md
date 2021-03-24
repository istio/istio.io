---
title: Remove Retired Documentation
description: Details how to contribute retired documentation to Istio.
weight: 4
aliases:
    - /about/contribute/remove-content
    - /latest/about/contribute/remove-content
keywords: [contribute]
owner: istio/wg-docs-maintainers
test: n/a
---

To remove documentation from Istio, please follow these simple steps:

1. Remove the page.
1. Reconcile the broken links.
1. Submit your contribution to GitHub.

## Remove the page

Use `git rm -rf` to remove the directory containing the `index.md` page.

## Reconcile broken links

To reconcile broken links, use this flowchart:

{{< image width="100%"
    link="./remove-documentation.svg"
    alt="Remove Istio documentation."
    caption="Remove Istio documentation"
    >}}

## Submit your contribution to GitHub

If you are not familiar with GitHub, see our [working with GitHub guide](/docs/releases/contribute/github)
to learn how to submit documentation changes.

If you want to learn more about how and when your contributions are published,
see the [section on branching](/docs/releases/contribute/github#branching-strategy) to understand
how we use branches and cherry picking to publish our content.
