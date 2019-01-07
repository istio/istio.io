---
title: Run a single microservice locally
overview: Work on a single microservice, on a local developer machine.
weight: 10
---

This module demonstrates work on a single microservice, on a local developer machine. The microservice is written in
[Node.js](https://nodejs.org/en/) and is a small web app on its own. Being a web app, it listens to a port, expects for
HTTP GET requests on the path `/ratings/{productID}` and returns the product ratings by the reviewers.

1.  Download
    [the service's code](https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/src/ratings/ratings.js)
    and
    [the package file](https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/src/ratings/package.json)
    into a separate directory.
    Skim the service's code. Note the "embedded" Web Server and the aspects related to HTTP, such as the headers, the
    path, the status code.

1.  Run the following command to install the service's dependencies in the directory with the service code and the
    package file:

    {{< text bash >}}
    $ npm install
    {{< /text >}}

1.  Run the service:

    {{< text bash >}}
    $ npm start 9080
    {{< /text >}}

1.  Access [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or by the _curl_ command:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {{< /text >}}
