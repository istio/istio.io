---
title: Creating a Pull Request
description: Shows you how to create a GitHub pull request in order to submit your docs for approval.

weight: 20

redirect_from: /docs/welcome/contribute/creating-a-pull-request.html
---

To contribute to Istio documentation, create a pull request against the
[istio/istio.github.io](https://github.com/istio/istio.github.io)
repository. This page shows the steps necessary to create a pull request.

## Before you begin

1. Create a [GitHub account](https://github.com).

1. Sign the [Contributor License Agreement](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements).

Documentation will be published under the [Apache 2.0](https://github.com/istio/istio.github.io/blob/master/LICENSE) license.

## Creating a fork

Before you can edit documentation, you need to create a fork of Istio's documentation GitHub repository:

1. Go to the
[istio/istio.github.io](https://github.com/istio/istio.github.io)
repository.

1. In the upper-right corner, click **Fork**. This creates a copy of Istio's
documentation repository in your GitHub account. The copy is called a *fork*.

## Making your changes

1. In your GitHub account, in your fork of the Istio repository, create
a new branch to use for your contribution.

1. In your new branch, make your changes and commit them. If you want to
[write a new topic](./writing-a-new-topic.html),
choose the [page-type](./writing-a-new-topic.html#choosing-a-page-type)
that is the best fit for your content.

## Submitting a pull request

To publish your changes, you must create a pull request against the master branch of Istio's
documentation repository.

1. Make sure your change produce valid html and links are valid, `rake test`
will check this for you.

1. In your GitHub account, in your new branch, create a pull request
against the master branch of the istio/istio.github.io
repository. This opens a page that shows the status of your pull request.

1. During the next few days, check your pull request for reviewer comments.
If needed, revise your pull request by committing changes to your
new branch in your fork.

> Once your changes have been committed, they will show up immediately on [preliminary.istio.io](https://preliminary.istio.io), but
will only show up on [istio.io](http://istio.io) the next time we produce a new release, which happens around once a month.
