---
title: Review and run the ratings microservice locally
overview: Work on a single microservice, on a local developer machine.

order: 01

layout: docs
type: markdown
---

This module demonstrates the work on a single microservice, on a local developer machine. The microservice is written in node.js and is a small web app on its own. Being a web app, it listens to a port, expects for HTTP GET requests on the path `/ratings/{productID}` and returns the product ratings by the reviewers.

1. Review the service's code. Note the "embedded" Web Server and the aspects related to HTTP, such as the headers, the path, the status code.
   ```bash
   pushd istio-sources/samples/bookinfo/src/ratings
   more ratings.js
   ```
1. Download npm modules
   ```bash
   npm install
   ```
1. Run ratings
   ```bash
   npm start 9080
   ```

1. Access [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or by the _curl_ command:
   ```bash
   curl localhost:9080/ratings/7
   ```

