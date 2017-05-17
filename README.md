# istio.github.io

This repository contains the source code for the [istio.io](https://istio.io) web site.

Please see the main Istio [README](https://github.com/istio/istio/blob/master/README.md)
file to learn about the overall Istio project and how to get in touch with us. To learn how you can
contribute to any of the Istio components, please 
see the Istio [contribution guidelines](https://github.com/istio/istio/blob/master/CONTRIBUTING.md).

The website uses [Jekyll](https://jekyllrb.com/) templates and is hosted on GitHub Pages. Please make sure you are
familiar with these before editing.

To run the site locally with Docker, use the following command:

```bash
docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll  -it -p 127.0.0.1:4000:4000 jekyll/jekyll jekyll serve
```

Make sure you are not introducing html errors or bad links:
```bash
docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll  -it  jekyll/jekyll sh -c "bundle install && rake test"
```
```
HTML-Proofer finished successfully.
```

#### Side note for those on non-linux machines
 
If you're developing locally but not on a Linux machine, you have a couple options. 
You can opt to use [Docker for Mac](https://docs.docker.com/docker-for-mac/) / [Docker for Windows](https://docs.docker.com/docker-for-windows/). This will give you a docker environment from which to run the above docker container (which has all the of the correct Jekyll dependencies and Ruby versions installed). Alternatively, you could use minikube.


If doing Istio development on Kubernetes locally with [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) and native virtualization (for example, on Mac OS X with[xhyve driver](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#xhyve-driver), then bootstrap like this:

```bash
minikube start --vm-driver=xhyve
```

You can see more about this command and how to install the [xhyve](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#xhyve-driver) drivers by [taking a look at the xhyve driver documentation](https://github.com/zchee/docker-machine-driver-xhyve#install)


Then build and run the website with minikube and bind to your `minikube ip` like this:

```bash
docker run --rm --label=jekyll  --volume=$(pwd):/srv/jekyll  -it -p $(minikube ip):4000:4000 jekyll/jekyll jekyll serve 
```

To see the web page locally on `localhost:4000`, you can port-forward the minikube port `4000` to your local machine. Run this command in a separate tab/window:

```bash
minikube ssh -- -vnNTL *:4000:$(minikube ip):4000 
```

Alternatively, if you just want to develop locally w/o Docker/Kubernetes/Minikube, you can try installing Jekyll locally. You may need to install other prerequisites manually (which is where using the docker image shines). Here's an example of doing so for Mac OS X:

    $ xcode-select --install
    $ brew install ruby
    $ sudo gem install bundler
    $ sudo gem install jekyll
    $ cd istio.github.io
    $ bundle install
    $ bundle exec jekyll build
    $ bundle exec jekyll serve
