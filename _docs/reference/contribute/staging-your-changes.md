---
category: Reference
title: Staging Your Changes
overview: Explains how to test your changes locally before submitting them.
              
parent: Contributing to the Docs
order: 40

bodyclass: docs
layout: docs
type: markdown
---

This page shows how to stage content that you want to contribute
to the Istio documentation.

## Before you begin

Create a fork of the Istio documentation repository as described in
[Creating a Doc Pull Request](/docs/reference/contribute/creating-a-pull-request.html).

## Staging locally

To stage your changes, go to the top of your documentation repo and start Jekyll via the following
docker command-line:

```bash
docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll  -it -p 127.0.0.1:4000:4000 jekyll/jekyll jekyll serve
```

If you don't have docker installed, get that first and the above should then just work.

Once the docker command is running, you can open a web browser and go to `http://localhost:4000` to see your
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

1. View your staged content at this URL:

        https://<your-username>.github.io
