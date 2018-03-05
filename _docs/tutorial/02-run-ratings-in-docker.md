---
title: Run ratings in Docker
overview: Run a single microservice in a Docker container.

order: 02

layout: docs
type: markdown
---
{% include home.html %}

This learning module shows how you create a Docker image and run it locally.

1. Observe the `Dockerfile`
   ```bash
   cd ../../src/ratings
   more Dockerfile
   ```
1. Build Docker image
   ```bash
   docker build -t $USER/ratings .
   ```
1. Run ratings
   ```bash
   docker run -d -p 9081:9080 $USER/ratings
   ```

1. Access http://localhost:9081/ratings/7

1. Observe the running container
   ```bash
   docker ps
   ```

1. Stop the running container
   ```bash
   docker stop <container ID>
   ```
