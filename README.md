| Site | Status
|------|-------
| istio.io | [![Netlify Status](https://api.netlify.com/api/v1/badges/c98435af-5464-4ac3-93c2-9c98faeec9b6/deploy-status)](https://app.netlify.com/sites/istio/deploys)
| preliminary.istio.io | [![Netlify Status](https://api.netlify.com/api/v1/badges/a1cfd435-23d5-4a43-ac6d-8ec9230d9eb3/deploy-status)](https://app.netlify.com/sites/preliminary-istio/deploys)
| archive.istio.io | [![Netlify Status](https://api.netlify.com/api/v1/badges/f8c3eecb-3c5c-48d9-b952-54c7ed0ece8f/deploy-status)](https://app.netlify.com/sites/archive-istio/deploys)

## istio.io

This repository contains the source code for the [istio.io](https://istio.io),
[preliminary.istio.io](https://preliminary.istio.io), and [archive.istio.io](https://archive.istio.io) sites.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please
see the Istio [contribution guidelines](https://github.com/istio/community/blob/master/CONTRIBUTING.md).

- [Editing and building](#editing-and-building)
- [Versions and releases](#versions-and-releases)
    - [How versioning works](#how-versioning-works)
    - [Publishing content immediately](#publishing-content-immediately)
    - [Creating a version](#creating-a-version)
    - [Creating a patch release](#creating-a-patch-release)

## Editing and building

To learn how to edit and build this repo's content, please refer to
[Creating and Editing Pages](https://preliminary.istio.io/about/contribute/creating-and-editing-pages/).

## Versions and releases

Istio maintains three variations of its public site.

- [istio.io](https://istio.io) is the main site, showing documentation for the current release of the product.

- [archive.istio.io](https://archive.istio.io) contains snapshots of the documentation for previous releases of the product.
This is useful for customers still using these older releases.

- [preliminary.istio.io](https://preliminary.istio.io) contains the actively updated documentation for the next release of the product.

The user can trivially navigate between the different variations of the site using the gear menu in the top right
of each page. All three sites are hosted on [Netlify](https://netlify.com).

### How versioning works

- Documentation changes are primarily committed to the master branch of istio.io. Changes committed to this branch
are automatically reflected on preliminary.istio.io.

- The content of istio.io is taken from the latest release-XXX branch. The specific branch that
is used is determined by the istio.io [Netlify](https://netlify.com) project's configuration.

- The content of archive.istio.io is taken from the older release-XXX branches. The set of branches that
are included on archive.istio.io is determined by the `TOBUILD` variable in this
[script](https://github.com/istio/istio.io/blob/master/scripts/gen_archive_site.sh).

### Publishing content immediately

Checking in updates to the master branch will automatically update preliminary.istio.io, and will only be reflected on
istio.io the next time a release is created, which can be several weeks in the future. If you'd like some changes to be
immediately reflected on istio.io, you need to check your changes both to the master branch and to the
current release branch (named release-XXX such as release-0.7).

This process can be taken care of automatically by our infrastructure. If you submit a PR
to the master branch and annotate the PR with the `actions/merge-to-release-branch` label,
then as soon as your PR is merged into master, it will be merged into the current release branch.

### Creating a version

Here are the steps necessary to create a new documentation version. Let's assume the current
version of Istio is 0.6 and you wish to introduce 0.7 which has been under development.

#### Creating the release branch

1. Switch to the istio/istio.io repo and make sure everything is up to date.

1. Edit the file `scripts/gen_archive_site.sh` and add the new archive version
(in this case release-0.6) to the `TOBUILD` variable.

1. Edit the file `data/versions.yml`. Set the `preliminary` field to the next Istio release
("0.8") and the `main` field to the current release ("0.7").

1. Commit the previous edits to your local git repo.

1. Create a new release branch off of master, named as release-*major*.*minor*, which in this case would be
release-0.7. There is one such branch for every release.

1. In the **release** branch you created, edit the file `data/args.yml`. Set the `preliminary` field to `false`
and the `source_branch_name` and `doc_branch_name` fields to the name of the branch, in this case release-0.7.

1. In the **release** branch you created, edit the file `scripts/grab_reference_docs.sh`. Update the branch
name for `istio.git`, `api.git`, and `operator.git` to point to the release branch. In this case release-0.7.

1. In the **release** branch you created, run `make update_ref_docs` in order to get the latest reference docs.

1. Commit the previous edit to your local git repo and push your **release** branch to GitHub.

#### Updating preliminary.istio.io

1. In the **master** branch, edit the file `data/args.yml`. Set the `version` and `full_version` fields to have the version
of the next Istio release, and `previous_version` to be the version of the previous release. In this case, you would set the fields to
"0.8", "0.8.0", and "0.7" respectively.

1. In the **master** branch, edit the file `data/args.yml`. Set the
`source_branch_name` and `doc_branch_name` fields to `master`.

1. In the **master** branch, edit the file `scripts/grab_reference_docs.sh`. Ensure the branch
name for `istio.git`, `api.git`, and `operator.git` points to the master branch.

1. Run `make update_ref_docs` in order to get the latest reference docs.

1. Commit the previous edits to your local git repo and push the **master** branch to GitHub.

1. Wait a while (~2 minutes) and browse preliminary.istio.io to make sure everything looks good.

#### Updating istio.io

1. Go to the istio.io project on [Netlify](https://netlify.com)

1. Change the branch that is built from the previous release's branch to the new release branch, in this case release-0.7

1. Select the option to trigger an immediate rebuild and redeployment.

1. Once deployment is done, browse istio.io and make sure everything looks good.

#### Updating archive.istio.io

1. Go to the [Google Custom Search Engine](https://cse.google.com) and do the following:

    - Download the archive.istio.io CSE context file from the Advanced tab.

    - Add a new FacetItem at the top of the file containing the previous release's version number. In
    this case, this would be "V0.6".

    - Upload the updated CSE context file to the site.

    - In the Setup section, add a new site that covers the previous release's archive directory. In this
    case, the site URL would be archive.istio.io/v0.6/*. Set the label of this site to the name of the
    facet item created above (V0.6 in this case).

1. In the **previous release's** branch (in this case release-0.6), edit the file `data/args.yml`. Set the
`archive` field to true and the `archive_date` field to the current date.

1. In the **previous release's** branch (in this case release-0.6), edit the file `config.toml`. Set the
`disableAliases` field to `false`.

1. Commit the previous edits to your local git repo and push the **previous release's** branch to GitHub.

1. In the **archive** branch, rebase the branch to have all changes from the current release. In this case,
all changes from the release-0.7 branch.

1. Commit the previous edits to your local git repo and push the **archive** branch to GitHub.

1. Wait a while (~15 minutes) and browse archive.istio.io to make sure everything looks good.

### Creating a patch release

Creating a new patch release involves modifying a few files:

1. Create the release note for the release by adding a markdown file in
`content/en/news/<YEAR>/1.X.Y/index.md`, where 1.X.Y is the name of the release. This is where
you describe the changes in the release.

1. Edit the `data/args.yml` file and change the `full_version` field to the name of the release.

1. Run `make update_ref_docs` to get the latest reference docs.

For the release note file, please look at existing files in the same location for example content and
layout.
