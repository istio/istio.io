## istio.github.io

This repository contains the source code for the [istio.io](https://istio.io),
[preliminary.istio.io](https://preliminary.istio.io) and [archive.istio.io](https://archive.istio.io) sites.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please
see the Istio [contribution guidelines](https://github.com/istio/community/blob/master/CONTRIBUTING.md).

* [Editing and testing content](#editing-and-testing-content)
* [Linting](#linting)
* [Site infrastructure](#site-infrastructure)
* [Versions and releases](#versions-and-releases)
  * [How versioning works](#how-versioning-works)
  * [Publishing content immediately](#publishing-content-immediately)
  * [Creating a version](#creating-a-version)

## Editing and testing content

We use [Hugo](https://gohugo.io/) to generate our sites. To build and test the site locally,
install Hugo, go to the root of the repo and do:

```bash
$ hugo serve
```

This will build the site and start a web server hosting the site. You can then connect to the web server
at `http://localhost:1313`.

All normal content for the site is located in the `content` directory. To
create a new content file, go to the root of the repo and do:

```bash
$ hugo new <path to new file>
```

This will create a fresh content file, ready for editing. The path you specify is relative to the `content` directory. For
example:

```bash
$ hugo new docs/tasks/traffic-management/foo.md
```

Will create the file `content/docs/tasks/traffic-management/foo.md` which you can then add your markdown to.

## Linting

We use linters to ensure some base quality to the site's content. We currently
run 3 linters as a precommit requirement:

* HTML proofing, which ensures all your links are valid along with other checks.

* Spell checking.

* Style checking, which makes sure your markdown files comply with our common style rules.

You can run these linters locally using:

```bash
$ make prep_lint
$ make lint
```

The `prep_lint` step installs a bunch of Ruby and Node.js tools in a local directory. You only need to do
this once. Afterwards, just use the `lint` target to run the linters.

If you get spelling errors, you have three choices to address it:

* It's a real typo, so fix your markdown.

* It's a command/field/symbol name, so stick some `backticks` around it.

* It's really valid, so go add the word to the `.spelling` file at the root of the repo.

## Site infrastructure

Here's how things work:

* Primary site content is in the `content` directory. This is mostly
markdown files which Hugo processes into HTML.

* Additional site content is in the `static` directory. These are files that
Hugo directly copies to the site without any processing.

*   The `src` directory contains the source material for certain files from the
`static` directory. You use

    ```bash
    $ make prep_build
    $ make build
    ```

    to build the material from the `src` directory and refresh what's in the `static`
    directory.

## Versions and releases

Istio maintains three variations of its public site:

* [istio.io](https://istio.io) is the main site, showing documentation for the current release of the product.
This site is currently hosted on Firebase.

* [archive.istio.io](https://archive.istio.io) contains snapshots of the documentation for previous releases of the product.
This is useful for customers still using these older releases.
This site is currently hosted on Firebase.

* [preliminary.istio.io](https://preliminary.istio.io) contains the actively updated documentation for the next release of the product.
This site is hosted by GitHub Pages.

The user can trivially navigate between the different variations of the site using the gear menu in the top right
of each page.

### How versioning works

* Documentation changes are primarily committed to the master branch of istio.github.io. Changes committed to this branch
are automatically reflected on preliminary.istio.io.

* The content of istio.io is taken from the latest release-XXX branch. The specific branch that
is used is determined by the `BRANCH` variable in this [script](https://github.com/istio/admin-sites/blob/master/current.istio.io/build.sh)

* The content of archive.istio.io is taken from the older release-XXX branches. The set of branches that
are included on archive.istio.io is determined by the `TOBUILD` variable in this
[script](https://github.com/istio/admin-sites/blob/master/archive.istio.io/build.sh)

> The above means that if you want to do a change to the main istio.io site, you will need
to make the change in the master branch of istio.github.io and then merge that change into the
release branch.

### Publishing content immediately

Checking in updates to the master branch will automatically update preliminary.istio.io, and will only be reflected on
istio.io the next time a release is created, which can be several weeks in the future. If you'd like some changes to be
immediately reflected on istio.io, you need to check your changes both to the master branch and to the
current release branch (named release-XXX such as release-0.7).

### Creating a version

Here are the steps necessary to create a new documentation version. Let's assume the current
version of Istio is 0.6 and you wish to introduce 0.7 which has been under development.

1. Create a new release branch off of master, named as release-*major*.*minor*, which in this case would be
release-0.7. There is one such branch for every release.

1. In the **master** branch, edit the file `data/args.yml` and update the `version` field to have the version
of the next release of Istio. In this case, you would set the field to 0.8.

1. In the **master** branch, edit the file `data/releases.yml` and add a new entry at the top of the file
for version 0.8. You'll need to make sure the URLs are updated for the first few entries. The top
entry (0.8) should point to preliminary.istio.io. The second entry (0.7) should point to istio.io. The third
and subsequent entries should point to archive.istio.io.

1. Commit the previous two edits to GitHub.

1. In the **release** branch you created, edit the file `data/args.yml`. Set the `preliminary` field to `false`.

1. Commit the previous edit to GitHub.

1. Go to the Google Search Console and create a new search engine that searches the archive.istio.io/V&lt;major&gt;.&lt;minor&gt;
directory. This search engine will be used to perform version-specific searches on archive.istio.io.

1. In the **previous release's** branch (in this case release-0.6), edit the file `data/args.yml`. Set the
`archive` field to true, the `archive_date` field to the current date, the `search_engine_id` field
to the ID of the search engine you created in the prior step, and the `branch_name` field to the 
name of the branch.

1. Switch to the istio/admin-sites repo.

1. Navigate to the archive.istio.io directory.

1. Edit the `build.sh` script to add the newest archive version (in this case
release-0.6) to the `TOBUILD` variable.

1. Commit the previous edit to GitHub.

1. Run the `build.sh` script.

1. Once the script completes, run `firebase deploy`. This will update archive.istio.io to contain the
right set of archives, based on the above steps.

1. Navigate to the current.istio.io directory.

1. Edit the `build.sh` script to set the `BRANCH` variable to the current release branch (in this case release-0.7)

1. Run the `build.sh` script.

1. Once the script completes, run 'firebase deploy`. This will update the content of istio.io to reflect what is the new release
branch you created.

Once all this is done, browse the three sites (preliminary.istio.io, istio.io, and archive.istio.io) to make sure
everything looks good.
