---
title: Review and run the ratings microservice locally
overview: This learning module demonstrates the work on a single microservice, on a local developer machine.

order: 01

layout: docs
type: markdown
---
{% include home.html %}


This learning module demonstrates the work on a single microservice, on a local developer machine. The microservice is written in node.js and is a small web app by itself - it listens to a port, expects for HTTP GET requests on path `/ratings/{productID}` and returns the product ratings by the reviewers.

1. Review the code of the service. Note the "embedded" Web Server and aspects related to HTTP - headers, the path, the status code.
   ```
   cd ../../src/ratings
   more ratings.js
   ```
1. Download npm modules
   ```
   npm install
   ```
1. Run ratings
   ```
   npm start 9080
   ```

1. Access http://localhost:9080/ratings/7
