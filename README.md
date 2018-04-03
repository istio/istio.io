# istio.github.io

This repository contains the source code for the [istio.io](https://istio.io),
[preliminary.istio.io](https://preliminary.istio.io) and [archive.istio.io](https://archive.istio.io) websites.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please
see the Istio [contribution guidelines](https://github.com/istio/community/blob/master/CONTRIBUTING.md).

* [Working with the site](#building-the-site)
* [Versions and releases](#versions-and-releases)
  * [How versioning works](#how-versioning-works)
  * [Creating a version](#creating-a-version)

## Working with the site

The website uses [Jekyll](https://jekyllrb.com/) templates Please make sure you are
familiar with these before editing.

To run the site locally with Docker, use the following command from the toplevel directory for this git repo
(e.g. pwd must be `~/github/istio.github.io` if you were in `~/github` when you issued
`git clone https://github.com/istio/istio.github.io.git`)

```bash
# First time: (slow)
docker run --name istio-jekyll --volume=$(pwd):/srv/jekyll  -it -p 4000:4000 jekyll/jekyll:3.5.2 sh -c "bundle install && rake test && bundle exec jekyll serve --incremental --host 0.0.0.0"
# Then open browser with url 127.0.0.1:4000 to see the change.
# Subsequent, each time you want to see a new change and you stopped the previous run by ctrl+c: (much faster)
docker start istio-jekyll -a -i
# Clean up, only needed if you won't be previewing website changes for a long time or you want to start over:
docker rm istio-jekyll
```

The `rake test` part is to make sure you are not introducing html errors or bad links, you should see
```
HTML-Proofer finished successfully.
```
in the output

> In some cases the `--incremental` may not work properly and you might have to remove it.

Alternatively, if you just want to develop locally w/o Docker/Kubernetes/Minikube, you can try installing Jekyll locally. You may need to install other prerequisites manually (which is where using the docker image shines). Here's an example of doing so for Mac OS X:

```bash
xcode-select --install
sudo xcodebuild -license
brew install ruby
gem update --system
gem install bundler
gem install jekyll
cd istio.github.io
bundle install
bundle exec rake test
bundle exec jekyll serve
```

## Versions and releases

Istio maintains three variations of its public website:

* istio.io is the main site, showing documentation for the current release of the product.
This site is currently hosted on Firebase.

* archive.istio.io contains snapshots of the documentation for previous releases of the product.
This is useful for customers still using these older releases.
This site is currently hosted on Firebase.

* preliminary.istio.io contains the actively updated documentation for the next release of the product.
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

### Creating a version

Here are the steps necessary to create a new documentation version. Let's assume the current
version of Istio is 0.6 and you wish to introduce 0.7 which has been under development.

1. Create a new release branch off of master, named as release-*major*.*minor*, which in this case would be
release-0.7. There is one such branch for every release.

1. In the **master** branch, edit the file `_data/istio.yml` and update the `version` field to have the version
of the next release of Istio. In this case, you would set the field to 0.8.

1. In the **master** branch, edit the file `_data/releases.yml` and add a new entry at the top of the file
for version 0.8. You'll need to make sure the URLs are updated for the first few entries. The top
entry (0.8) should point to preliminary.istio.io. The second entry (0.7) should point to istio.io. The third
and subsequent entries should point to archive.istio.io.

1. Commit the previous two edits to GitHub.

1. In the **release** branch you created, edit the file `_data/istio.yml`. Set the `preliminary` field to `false`.

1. Commit the previous edit to GitHub.

1. Go to the Google Search Console and create a new search engine that searches the archive.istio.io/V<major>.<minor>
directory. This search engine will be used to perform version-specific searches on archive.istio.io.

1. In the **previous release's** branch (in this case release-0.6), edit the file `_data/istio.yml`. Set the
`archive` field to true, the `archive_date` field to the current date, and the `search_engine_id` field
to the ID of the search engine you created in the prior step.

1. Switch to the istio/admin-sites repo. In this repo:

  1. Navigate to the archive.istio.io directory and edit the `build.sh` script to add the newest archive version (in this case
  release-0.6) to the `TOBUILD` variable.

  1. Commit the previous edit to GitHub.

  1. Run the `build.sh` script.

  1. Once the script completes, run 'firebase deploy'. This will update archive.istio.io to contain the
  right set of archives, based on the above steps.

  1. Navigate to the current.istio.io directory

  1. Edit the build.sh script to set the `BRANCH` variable to the current release branch (in this case release-0.7)

  1. Run the `build.sh` script.

  1. Once the script completes, run 'firebase deploy`. This will update the content of istio.io to reflect what is the new release
  branch you created.

Once all this is done, browse the three sites (preliminary.istio.io, istio.io, and archive.istio.io) to make sure
everything looks good.
