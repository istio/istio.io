# istio.github.io

This repository contains the source code for the [istio.io](https://istio.io) web site.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please
see the Istio [contribution guidelines](https://github.com/istio/community/blob/master/CONTRIBUTING.md).

## Updating the site

To update istio.io, simply edit files in this repo and push the changes. 30 seconds to one minute after your push
completes, istio.io should reflect your updates.

## Staging the site using Docker

The website uses [Jekyll](https://jekyllrb.com/) templates and is hosted on GitHub Pages. Please make sure you are
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

## Staging the site without Docker

Alternatively, if you just want to develop locally w/o Docker/Kubernetes/Minikube, you can try installing Jekyll locally. You may need to install other prerequisites manually (which is where using the docker image shines). Here's an example of doing so for Mac OS X:

```
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

## Archiving the site

We archive snapshots of the whole site for every release, which allows our customers to time travel and review
older docs. This is very valuable if they're running older versions and need to look something up.
Archives are maintained at https://archive.istio.io.

To create an archive version, you need to follow these steps:

- Go to https://google.com/cse and create a new search engine for the archive site. After you've gone through the hoops necessary
to get access to this site, you'll see there are many search engines already created. We create one search engine
per site archive, which makes it possible for customers to search within this specific version of the site. You will need
to create a new search engine. Just create a new engine and specify that you'd like to search the url https://archive.istio.io/vXX
where XX is the version number such as https://archive.istio.io/v0.5 or https://archive.istio.io/v1.2. Once the engine
is created, you'll need to navigate to the Advanced tab and then download the CSE XML file. Within this file, you'll find
an XML element called nonprofit that's set to false. Flip the element to true and upload the updated XML file to the
web site.

- Once the search engine is created, hunt around in the UI to find the search engine ID and copy that.

- Get the latest version of the site source code and create a new branch for the archive:

   ```bash
   git fetch upstream
   git rebase upstream/master
   git checkout -b release-XX
   ```

  where XX is the version number of the archive such as 0.5 or 1.2

- Load _data/istio.yml into a text editor. In this file, set `archive:` to `true` and update the search
engine id to the value you copied from above.

- Save the file, commit the change, and submit a PR to push your changes into the repo

- Once the PR is introduced, you then need to switch to the istio/admin-sites repo. In this
repo, locate the file archive.istio.io/build.sh and update the TOBUILD array at the top to
include an entry for the branch you just introduced above.

- Run archive.istio.io/build.sh. This will build a full copy of the archive.istio.io site on your local
system, in the public directory.

- Run `firebase deploy` to push the updated archive.istio.io from your system to the live site. The
build.sh script includes a bit of info on prerequisites before you can run the script and run
firebase.
