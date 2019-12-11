---
title: Working with GitHub
description: Shows you how to use GitHub to work on Istio documentation.
weight: 30
aliases:
    - /docs/welcome/contribute/creating-a-pull-request.html
    - /docs/welcome/contribute/staging-your-changes.html
    - /docs/welcome/contribute/editing.html
    - /about/contribute/creating-a-pull-request
    - /about/contribute/editing
    - /about/contribute/staging-your-changes
keywords: [contribute,community,github,pr]
---

We're excited that you're interested in contributing to improve and expand
our docs! Please take a few moments to get familiar with our procedures before
you get started.

To work on Istio documentation, you need to:

1. Create a [GitHub account](https://github.com).

1. Sign the [Contributor License
   Agreement](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements).

The documentation is published under the [Apache
2.0](https://github.com/istio/community/blob/master/LICENSE) license.

## How to contribute

There are three ways you can contribute to the Istio documentation:

* If you want to edit an existing page, you can open up the page in your
  browser and select the **Edit This Page on GitHub** option from the gear menu
  at the top right of each page. This takes you to GitHub to edit and
  submit the changes.

* If you want to work on the site in general, follow the steps in our
  [How to add content section](#add).

* If you want to review an existing pull request (PR), follow the steps in our
  [How to review content section](#review)

Once your changes are merged, they show up immediately on
`preliminary.istio.io`. However, the changes only
show up on `istio.io` the next time we produce a new
release, which happens around once a quarter.

### How to add content {#add}

To add content you must create a fork of the repository and submit a PR from
your fork to the docs main repository. The following steps describe the
process:

<a class="btn"
href="https://github.com/istio/istio.io/">Browse this site's source
code</a>

1.  Click the button above to visit the GitHub repository.

1.  Click the **Fork** button in the upper-right corner of the screen to
    create a copy of our repository in your GitHub account.

1.  Create a clone of your fork and make any changes you want.

1.  When you are ready to send those changes to us, push the changes to your
    fork.

1.  Go to the index page for your fork, and click **New Pull Request** to let
    us know about it.

### How to review content {#review}

If your review is small, simply comment on the PR directly. If you review the
content in detail, follow these steps:

1.  Leave a comment on the PR with the text `/hold`. This command prevents the
    PR from being merged before you are able to complete your review.

1.  Perform your detailed review. When possible leave specific comments
    directly on the files and lines affected.

1.  Provide suggestions to the PR owner in your comments when appropriate. For
    example:

    {{< text markdown >}}
    Use present tense to avoid verb congruence issues and
    to make the text easier to understand:

    &96;&96;&96;suggestion

    Pilot maintains an abstract model of the mesh.

    &96;&96;&96;
    {{< /text >}}

1.  Publish your review to share your comments and suggestions with us and the
    PR owner. Request changes as the review warrants.

    {{< warning >}}
    If you don't publish your review, the PR owner and
    the community cannot see your comments.
    {{< /warning >}}

1.  Once you publish your review, leave a comment with the text:
    `/hold cancel`. That command unblocks the PR from being merged.

## Previewing your work

When you submit a pull request, your PR page on GitHub shows a link to a
staging site built automatically for your PR. This is useful for you to see
what the final page looks like to end-users. Folks reviewing your
pull request also use this staging site to make sure everything looks good.

If you created a fork of the repository, you can preview your changes locally.
See this
[README](https://github.com/istio/istio.io/blob/master/README.md) for
instructions.

## Branching

We use multiple branches to track documentation for different versions of Istio.
The master branch is where active doc work takes place, this is where you should
generally be making changes.

On the day of an Istio release, a release branch is created from master for that
release. For example, there are branches called `release-1.0`, `release-1.1`,
`release-1.2` and so forth.

The `istio.io` public site is produced by processing content from the current
release branch. The `preliminary.istio.io` site is produced by processing
content from the master branch. And the `archive.istio.io` site is
produced by processing content from all prior release branches.

Given how branching works, if you submit a change into the master branch,
that change will not appear on `istio.io` until the next major Istio release
happens. If your documentation change is relevant to the current Istio release,
then it's probably worth also applying your change to the current release branch.
You can do this easily and automatically by using the special cherry-pick labels
on your documentation PR. For example, if you introduce a correction in a PR to
the master branch, you can apply the `cherrypick/release-1.4` label in order to
merge this change to the `release-1.4` branch.

Once your initial PR is merged, automation will create a new PR in the release
branch which includes your changes. You may need to add a comment to the PR
that reads `@googlebot I consent` in order to satisfy the `CLA` bot that we
use.

On rare occasions, automatic cherry picks don't work. When that happens, the
automation will leave a note in the original PR indicating it failed. When
that happens, you will need to manually create the cherry pick and deal
with the merge issues that prevented the process from working automatically.

Note that we only ever cherry pick changes into the current release branch,
and never to older branches. Older branches are considered to be archived and
generally no longer receive any changes.

## Istio community roles

Depending on your contributions and responsibilities, there are several roles
you can assume.

Visit our [role summary page](https://github.com/istio/community/blob/master/ROLES.md#role-summary)
to learn about the roles, the related requirements and responsibilities, and
the privileges associated with the roles.

Visit our [community page](https://github.com/istio/community) to learn more
about the Istio community in general.
