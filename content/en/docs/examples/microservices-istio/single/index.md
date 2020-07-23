---
title: Run a Microservice Locally
overview: Learn how to work on a single service on your local machine.
weight: 10
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Before the advent of microservice architecture, development teams built,
deployed and ran the whole application as one large chunk of software. To test a
small change in their module not merely by unit testing, the developers had to
build the whole application. Therefore the builds took large amount of time.
After the build, the developers deployed their version of the application into a
test server. The developers ran the server either on a remote machine, or on their
local computer. In the latter case, the developers had to install and operate a
rather complex environment on their local computer.

In the era of microservice architecture, the developers write, build, test and
run small software services. Builds are fast. With modern frameworks like
[Node.js](https://nodejs.org/en/) there is no need to install and operate
complex server environments to test a single service, since the service runs as
a regular process. You do not have to deploy your service to some environment to
merely test it, so you just build your service and run it immediately on your
local computer.

This module covers the different aspects involved in developing a single service
on a local machine. You don't need to write code though. Instead, you build,
run, and test an existing service: `ratings`.

The `ratings` service is a small web app written in
[Node.js](https://nodejs.org/en/) that can run on its own. It performs similar
actions to those of other web apps:

- Listen to the port it receives as a parameter.
- Expect `HTTP GET` requests on the `/ratings/{productID}` path and return the
  ratings of the product matching the value the client specifies for `productID`.
- Expect `HTTP POST` requests on the `/ratings/{productID}` path and update the
  ratings of the product matching the value you specify for `productID`.

Follow these steps to download the code of the app, install its dependencies,
and run it locally:

1. Download
    [the service's code]({{< github_blob >}}/samples/bookinfo/src/ratings/ratings.js)
    and
    [the package file]({{< github_blob >}}/samples/bookinfo/src/ratings/package.json)
    into a separate directory:

    {{< text bash >}}
    $ mkdir ratings
    $ cd ratings
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/ratings.js -o ratings.js
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/package.json -o package.json
    {{< /text >}}

1. Skim the service's code and note the following elements:
    - The web server's features:
        - listening to a port
        - handling requests and responses
    - The aspects related to HTTP:
        - headers
        - path
        - status code

    {{< tip >}}
    In Node.js, the web server's functionality is embedded in the code of the application. A Node.js
    web application runs as a standalone process.
    {{< /tip >}}

1. Node.js applications are written in JavaScript, which means that there is no
    explicit compilation step. Instead, they use [just-in-time compilation](https://en.wikipedia.org/wiki/Just-in-time_compilation). To build a Node.js application, then means to install its dependencies. Install
    the dependencies of the `ratings` service in the same folder where you
    stored the service code and the package file:

    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1. Run the service, passing `9080` as a parameter. The application then listens on port 9080.

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

{{< tip >}}
The `ratings` service is a web app and you can communicate with it as you would
with any other web app. You can use a browser or a command line web client like
[`curl`](https://curl.haxx.se) or [`Wget`](https://www.gnu.org/software/wget/).
Since you run the `ratings` service locally, you can also access it via the
`localhost` hostname.
{{< /tip >}}

1. Open [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in
    your browser or access `ratings` using the `curl` command from a different terminal window:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1. Use the `POST` method of the `curl` command to set the ratings for the
    product to `1`:

    {{< text bash >}}
    $ curl -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. Check the updated ratings:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. Use `Ctrl-C` in the terminal running the service to stop it.

Congratulations, you can now build, test, and run a service on your local computer!

You are ready to [package the service](/docs/examples/microservices-istio/package-service) into a container.
