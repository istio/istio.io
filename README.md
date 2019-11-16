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
- [Regular maintenance](#regular-maintenance)

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
current release branch (named release-XXX such as release-1.4).

This process can be taken care of automatically by our infrastructure. If you submit a PR
to the master branch and annotate the PR with the `actions/merge-to-release-branch` label,
then as soon as your PR is merged into master, it will be merged into the current release branch.

### Creating a version

Here are the steps necessary to create a new documentation version. Let's assume the current
version of Istio is 1.3 and you wish to introduce 1.4 which has been under development.

#### When Istio source code is branched

The documentation repo pulls content from the Istio source repos for inclusion in the published site.
When the source repos are branched in preparation for a release, a few changes are needed in the
documentation repo to track this:

1. Switch to the **master** branch of the istio/istio.io repo and make sure everything is up to date.

1. Edit the file `Makefile.core.mk` and change the `SOURCE_BRANCH_NAME` variable to the 
name of the newly created source branches (in this case `release-1.4`).

1. Edit the file `data/args.yml` and set the `source_branch_name` field to the name of the newly created source
branches (in this case `release-1.4`).

1. Run `make update_all` in order to retrieve the latest material from the source repositories.

1. Commit the previous edits to your local git repo and push your **master** branch to GitHub.

#### On the day of the release

##### Creating the release branch

The day of a major Istio release, assuming you've previously done the steps from the above section, you need to:

1. Switch to the **master** branch of the istio/istio.io repo and make sure everything is up to date.

1. Edit the file `scripts/build_archive_site.sh` and add the new archive version
(in this case `release-1.3`) to the `TOBUILD` variable.

1. Edit the file `data/versions.yml`. Set the `preliminary` field to the next Istio release
(in this case `1.5`) and the `main` field to the current release (in this case `1.4`).

1. Commit the previous edits to your local git repo and push your **master** branch to GitHub.

1. Create a new release branch off of master, named as release-**major**.**minor** (in this case `release-1.4`). There is one
such branch for every release.

1. Edit the file `data/args.yml`. Set the `preliminary` field to `false`
and the the `doc_branch_name` field to the name of the release branch (in this case `release-1.4`).

1. Commit the previous edits to your local git repo and push your **release** branch to GitHub.

#### Updating istio.io

1. Go to the istio.io project on [Netlify](https://netlify.com)

1. Change the branch that is built from the previous release's branch to the new release branch, in this case release-1.4

1. Select the option to trigger an immediate rebuild and redeployment.

1. Once deployment is done, browse istio.io and make sure everything looks good.

##### Updating archive.istio.io

1. Go to the [Google Custom Search Engine](https://cse.google.com) and do the following:

    - Download the archive.istio.io CSE context file from the Advanced tab.

    - Add a new FacetItem at the top of the file containing the previous release's version number. In
    this case, this would be "V1.3".

    - Upload the updated CSE context file to the site.

    - In the Setup section, add a new site that covers the previous release's archive directory. In this
    case, the site URL would be archive.istio.io/v1.3/*. Set the label of this site to the name of the
    facet item created above (V1.3 in this case).

1. In the **previous release's** branch (in this case `release-1.3`), edit the file `data/args.yml`. Set the
`archive` field to true and the `archive_date` field to the current date, and the `rchive_search_refinement`
to the previous release version (in this case `V1.3`).

1. In the **previous release's** branch (in this case `release-1.3`), edit the file `config.toml`. Set the
`disableAliases` field to `false`.

1. Commit the previous edits to your local git repo and push the **previous release's** branch to GitHub.

1. In the **archive** branch, rebase the branch to have all changes from the current release. In this case,
all changes from the `release-1.4` branch.

1. Commit the previous edits to your local git repo and push the **archive** branch to GitHub.

1. Wait a while (~20 minutes) and browse archive.istio.io to make sure everything looks good.

##### Updating preliminary.istio.io

1. In the **master** branch, edit the file `data/args.yml`. Set the `version` and `full_version` fields to have the version
of the next Istio release, and `previous_version` to be the version of the previous release. In this case, you would set the fields to
"1.5", "1.5.0", and "1.4" respectively.

1. In the **master** branch, edit the file `data/args.yml`. Set the
`source_branch_name` and `doc_branch_name` fields to `master`.

1. In the **master** branch, edit the file `Makefile.core.mk`. Set the variable `SOURCE_BRANCH_NAKE` to
`master`.

1. Run `make update_all` in order to retrieve the latest material from the source repositories.

1. Commit the previous edits to your local git repo and push the **master** branch to GitHub.

1. Wait a while (~5 minutes) and browse preliminary.istio.io to make sure everything looks good.

### Creating a patch release

Creating a new patch release involves modifying a few files:

1. Create the release note for the release by adding a markdown file in
`content/en/news/<YEAR>/1.X.Y/index.md`, where 1.X.Y is the name of the release. This is where
you describe the changes in the release.

1. Edit the `data/args.yml` file and change the `full_version` field to the name of the release.

1. Run `make update_ref_docs` to get the latest reference docs.

For the release note file, please look at existing files in the same location for example content and
layout.

## Regular maintenance

We have a number of checks in place to ensure a number of invariants are maintained in order to
help the site's overall quality. For example, we disallow checking in broken links and we do spell
checking. There are some things which are hard to systematically check through automation and instead
require a human to review on in a while to ensure everything's doing well. 

It's a good idea to run through this list before every major release of the site:

- Ensure that references to the Istio repos on GitHub don't hardcode branch names. Search for any uses of `/release-1` or `/master`
throughout all the markdown files and replace those with {{< source_branch_name >}} instead, which produces a version-appropriate
branch name.

- Review the .spelling file for words thst shouldn't be in there. Type names in particular tend to creep in here. Type names should
not be in the dictionary and should instead be shown with `backticks`. Remove the entries from the dictionary and fix any spell
checking errors that emerge.

- Ensure proper capitalization. Document titles need to be fully capitalized (e.g. "This is a Valid Title"),
while section headings should use first letter capitalization only (e.g. "This is a valid heading").

- Ensure that preformatted text blocks that reference files from the Istio GitHub repos use the @@ syntax
to produce links to the content. See [here](https://istio.io/about/contribute/creating-and-editing-pages/#links-to-github-files)
for context.
