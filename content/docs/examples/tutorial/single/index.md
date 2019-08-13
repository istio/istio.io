---
title: Run a single service locally
overview: Learn how to work on a single service on your local machine.
weight: 10
---

{{< boilerplate work-in-progress >}}

Before the advent of microservices, it took a large team of developers to develop a large application. Development teams
built, deployed and ran the whole application as one large chunk of software. To test a small change in their module
in addition to unit testing, the developers had to build the whole application. Therefore the builds
took large amount of time. After the build, the developers deployed their version of the application into a test server.
The server either ran on a remote machine, or on the local computer of the developer. In the
latter case, the developers had to install and operate a rather complex environment on their local computer.

In the era of microservices, the developers write, build, test and run much smaller software parts, microservices,
on their local machine. Builds are fast. With modern frameworks like [Node.js](https://nodejs.org/en/) there is no
need to install and operate complex server environments to test a single service, since the service runs as a regular
process. You do not have to deploy your service to some environment merely to test it,
so you just build your service and run it immediately on your local computer.

This module covers the different aspects involved in developing a single service on a local machine.
You don't need to write code though. Instead, you build, run, and test an existing service:
`ratings`.

The `ratings` service is a small web app written in [Node.js](https://nodejs.org/en/) that can run on its own.
It performs similar actions to those of other web apps:

- Listen to the port it receives as a parameter.
- Expect `HTTP GET` requests on the `/ratings/{productID}` path and return the ratings of the product matching the value
  you specify for `productID`.
- Expect `HTTP POST` requests on the `/ratings/{productID}` path and update the ratings of the product matching the value
  you specify for `productID`.

Follow these steps to download the code of the app, install its dependencies, and run it locally:

1.  Download
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

1. Skim the service's code and note the following elements on the code:
    - The web serving features
        - listening to a port
        - handling requests and responses
    - The aspects related to HTTP:
        - Headers
        - Path
        - Status code

    {{< tip >}}
    In Node.js, the web server's functionality is embedded in the code of the application. A Node.js
    web application runs as a standalone process.
    {{< /tip >}}

1. Node.js applications are written in JavaScript, which means that there is no explicit compilation step.
    Instead, they use [just-in-time compilation](https://en.wikipedia.org/wiki/Just-in-time_compilation).
    To build a Node.js application, then means to install its dependencies. Install the dependencies of
    the `ratings` service in the same folder where you stored the service code and the package file:


    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1.  Run the service, passing `9080` as a parameter. The application then listens on port 9080.

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

{{< tip >}}
The `ratings` service is a web app and you can communicate with it as you would with any other web app. You can use a browser or a command line web client like [cURL](https://curl.haxx.se) or [Wget](https://www.gnu.org/software/wget/). Since you run the `ratings` service locally, you can also access it via the `localhost` hostname.
{{< /tip >}}

1.  Open [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or access
    `ratings` using the `curl` command:


    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Use the `POST` method of the `curl` command to set the ratings for the product to `1`:

    {{< text bash >}}
    $ curl -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1.  Check the updated ratings:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1.  Use `Ctrl-C` in the terminal running the service to stop it.

Success!
You can now build, test, and run a service on a local machine.
Go to the next module to learn how to package the service into a container. Once packaged, the service can be deployed
into a test, staging or production environment.
