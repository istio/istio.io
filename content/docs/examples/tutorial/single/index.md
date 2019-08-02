---
title: Run a single microservice locally
overview: Learn how to work on a single service on your local machine.
weight: 10
---

{{< boilerplate work-in-progress >}}

This module demonstrates teaches you how to work on a single service, `ratings`, on your local machine.
The `ratings` service is a small web app written in [Node.js](https://nodejs.org/en/) that can run on its own.
Since `ratings` is a web app it performs the following actions:

- Listen to port `9080`.
- Expect `HTTP GET` requests on the `/ratings/{productID}` path
- Return the ratings of the product matching the value you specify for `productID`.

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
    - The embedded web server
    - The aspects related to HTTP:
        - Headers
        - Path
        - Status code
    path, the status code.

1.  Install the service's dependencies in the same folder you used to store the service code and the
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
