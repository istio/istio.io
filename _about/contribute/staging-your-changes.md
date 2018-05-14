---
title: Staging Your Changes
overview: Explains how to test your changes locally before submitting them.

order: 40

layout: about
type: markdown
redirect_from: /docs/welcome/contribute/staging-your-changes.html
---

This page shows how to stage content that you want to contribute
to the Istio documentation.

## Before you begin

Create a fork of the Istio documentation repository as described in
[Creating a Doc Pull Request](./creating-a-pull-request.html).

## Staging locally

See [Detailed instructions and options on GitHub](https://github.com/istio/istio.github.io/blob/master/README.md)

Once Jekyll is running, you can open a web browser and go to `http://localhost:4000` to see your
changes. You can make further changes to the content in your repo and just refresh your browser page to see
the results, no need to restart Jekyll all the time.

## Staging from your GitHub account

> Hey, you know, you're much better off staging locally using the above procedure. Just sayin'...

GitHub provides staging of content in your master branch. Note that you
might not want to merge your changes into your master branch. If that is
the case, choose another option for staging your content.

1. In your GitHub account, in your fork, merge your changes into
the master branch.

1. Change the name of your repository to `<your-username>.github.io`, where
`<your-username>` is the username of your GitHub account.

1. Delete the `CNAME` file.

1. View your staged content at this URL: `https://<your-username>.github.io`
