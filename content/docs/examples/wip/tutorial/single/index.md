---
title: Run a single microservice locally
overview: Work on a single microservice, on a local developer machine.
weight: 10
---

This module demonstrates work on a single microservice, `ratings`, on a local developer machine.
The `ratings` service is a small web app written in [Node.js](https://nodejs.org/en/) that can run on its own.
Since `ratings` is a web app it performs the following actions:

- Listen to port `9080`.
- Expect `HTTP GET` requests on the `/ratings/{productID}` path
ratings of a product with `productID`.

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

    Skim the service's code. Note the "embedded" Web Server and the aspects related to HTTP, such as the headers, the
    path, the status code.

1.  Run the following command to install the service's dependencies in the directory with the service code and the
    package file:

    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1.  Run the service:

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

1.  Access [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or by the `curl` command:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Change ratings by using the POST method, set them to `1`:

    {{< text bash >}}
    $ curl -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1.  Check that `curl` returns the updated ratings:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1.  Stop the microservice by killing its process (`Ctrl-C` in the terminal).
