---
title: Run a single service locally
overview: Learn how to work on a single service on your local machine.
weight: 10
---

{{< boilerplate work-in-progress >}}

This module covers the different aspects involved in developing a single service on a local machine.
We will not ask you to write code, your task will be to build, run and test an already implemented service,
`ratings`.
The goal is to show that you can implement, build, run and test a service on your local machine,
before deploying it to a development, testing or production environment.

The `ratings` service is a small web app written in [Node.js](https://nodejs.org/en/) that can run on its own.
It performs the following actions, similar to the actions the web apps usually perform:

- Listen to the port it receives as a parameter.
- Expect `HTTP GET` requests on the `/ratings/{productID}` path and return the ratings of the product matching the value
  you specify for `productID`.
- Expect `HTTP POST` requests on the `/ratings/{productID}` path and update the ratings of the product matching the value
  you specify for `productID`.

Download the code of the app, install its dependencies and run it locally following the steps below:

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

    A quick explanation for those who are not familiar with Node.js or some of other modern web application framework.
    As opposed to the architecture of frameworks like [Apache Tomcat](http://tomcat.apache.org) or
    [WebSphere Application Server](https://www.ibm.com/support/knowledgecenter/SS7K4U_9.0.5/com.ibm.websphere.zseries.doc/ae/welc6productov.html),
    where one web server software runs multiple applications, in the case of Node.js the web serving functionality is
    embedded in the code of a single web application. A Node.js web application runs as a standalone process and
    contains all the web serving features.

1.  Since Node.js applications are written in JavaScript they are interpreted
    (well, with [just-in-time compilation](https://en.wikipedia.org/wiki/Just-in-time_compilation)),
    so there is no explicit compilation step. To build a Node.js application, roughly means to install its dependencies.

    Install the service's dependencies in the same folder you used to store the service code and the package file:

    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1.  Run the service, passing `9080` as a parameter. The application will listen on port 9080.

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

1.  Since the service is a web app, you can communicate with it as with any other web app, via a browser or by a
    command line web client like [cURL](https://curl.haxx.se) or [Wget](https://www.gnu.org/software/wget/).
    Since you run the service locally, you can access it via the `localhost` hostname.


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

1.  To stop the service stop its process, press `Ctrl-C` while in the terminal running it.

In this module you saw how you can implement, build, test and run a service on a local machine.
In the next module you will learn how create a container for your service and how to run the container locally.
