---
title: Build and serve the website locally
description: Explains how to locally build, test, serve, and preview the website.
weight: 5
keywords: [contribute, serve, Docker, Hugo, build]
---

After making your contribution to our website, ensure the changes
render as you expect. To ensure you can preview your changes locally, we have
tools that let you build and view them easily. We use automated tests to check
the quality of all contributions. Before submitting your changes in a Pull
Request (PR), you should run the tests locally too.

## Before you begin

To guarantee the tests you run locally use the same versions as the tests
running on the Istio Continuous Integration (CI), we provide a Docker image with
all the tools needed, including our site generator: [Hugo](https://gohugo.io/).

To build, test, and preview the site locally, you need to install
[Docker](https://www.docker.com/get-started) on your system.

## Preview your changes

To preview your changes to the site, go to the root of your fork of
`istio/istio.io` and run the following command:

{{< text bash >}}
$ make serve
{{< /text >}}

If your changes have no build errors, the command builds the site and starts a
local web server to host it. To see the local build of the site, go to
`http://localhost:1313` on your web browser.

If you need to make and serve the site from a remote server, you can use
`ISTIO_SERVE_DOMAIN` to provide the IP address or DNS Domain of the server, for
example:

{{< text bash >}}
$ make ISTIO_SERVE_DOMAIN=192.168.7.105 serve
{{< /text >}}

The example builds the site and starts a web server, which hosts the site on the
remote server at the `192.168.7.105` IP address. Like before, you can then
connect to the web server at `http://192.168.7.105:1313`.

### Test your changes

We use linters and tests to ensure a quality baseline for the site's content
through automated checks. These checks must pass without failure for us to
approve your contribution. Make sure you run the checks locally before you
submit your changes to the repository through a PR. We perform the following
automated checks:

- HTML proofing: ensures all links are valid along with other checks.

- Spell check: ensures content is spelled correctly.

- Markdown Style check: ensures the markup used complies with our Markdown style
  rules.

To run these checks locally, use the following command:

{{< text bash >}}
$ make lint
{{< /text >}}

If the spell checker reports errors, the following are the most likely causes:

- A real typo: Fix the typo on your Markdown files.

- The error is reported for a command, field, or symbol name: Place
  \`back-ticks\` around the content with the error.

- The error is reported for a correct word or proper name not present in the
  tool's dictionary: Add the word to the `.spelling` file at the root of the
  `istio/istio.io` repository.

Due to poor Internet connectivity, you could have trouble with the link checker.
If you can't get good connectivity, you can set the checker to prevent it from
checking external links. Set the `INTERNAL_ONLY` environment variable to `True`
when running the linter, for example:

{{< text bash >}}
$ make INTERNAL_ONLY=True lint
{{< /text >}}

When your content passes all the checks, submit it to the repository through a
PR. Visit [Working with GitHub](/about/contribute/github) for more
information.
