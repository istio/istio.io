---
title: Run ratings in Docker
overview: Run a single microservice in a Docker container.

order: 02

layout: docs
type: markdown
---
{% include home.html %}

This step shows how you create a Docker image and run it locally.

1. Observe the [Dockerfile](https://github.com/istio/istio/blob/master/samples/bookinfo/src/ratings/Dockerfile):
   ```bash
   more Dockerfile
   ```
1. Build Docker image:
   ```bash
   docker build -t $USER/ratings .
   ```
1. Run ratings in Docker:
   ```bash
   docker run -d -p 9081:9080 $USER/ratings
   ```

1. Access [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or by the _curl_ command:
   ```bash
   curl localhost:9080/ratings/7
   ```

1. Observe the running container:
   ```bash
   docker ps
   ```

1. Stop the running container:
   ```bash
   docker stop <container ID>
   ```

1. Go back to the Istio directory:
   ```bash
   popd
   ```
