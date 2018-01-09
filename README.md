# istio.github.io

This repository contains the source code for the [istio.io](https://istio.io) web site.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please
see the Istio [contribution guidelines](https://github.com/istio/community/blob/master/CONTRIBUTING.md).

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

## Local/Native Jekyll install:

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
