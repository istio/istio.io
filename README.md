# istio.github.io

istio.io website source.

The website uses [Jekyll](http://jekyllrb.com/) templates and is hosted on
GitHub Pages. Please make sure you are familiar with these before editing.

Running the Site Locally
------------------------

Running the site locally is simple. If you have `jekyll` installed with the
`github-pages` plugin you can clone this repo
and run `jekyll serve`. Your website will be visible at
`http://localhost:4000`.

If you do not have (or don't want) `jekyll`, you can build the site inside
a docker container in the following manner:

```
docker build -t istio/webpage .
docker run -p 4000:4000 -v "$(pwd)":/srv/jekyll istio/webpage
```

For users who do not need the `docker-machine`, from your host machine you
can access the website at `http://localhost:4000`. For those who do, you
can access the website from `http://<your-docker-machine-ip>:4000`.

You can use the `-d` option on the `docker run`, but it will take a few
moments for dependencies to load and for the page to be generated. During
this time you will not be able to access the website.
