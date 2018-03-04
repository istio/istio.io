---
title: Run ratings in docker
overview: Overview

order: 02

layout: docs
type: markdown
---
{% include home.html %}\n# Run the _ratings_ service in a docker container.
This learning module shows how you can create a docker image and run it locally.

1. Observe the `Dockerfile`
   ```
   cd ../../src/ratings
   more Dockerfile
   ```
1. Build docker image
   ```
   docker build -t $USER/ratings .
   ```
1. Run ratings
   ```
   docker run -d -p 9081:9080 $USER/ratings
   ```

1. Access http://localhost:9081/ratings/7

1. Observe the running container
   ```
   docker ps
   ```

1. Stop the running container
   ```
   docker stop <container ID>
   ```
