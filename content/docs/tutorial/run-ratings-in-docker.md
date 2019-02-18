---
title: Run ratings in Docker
overview: Run a single microservice in a Docker container.

weight: 20

---

This module shows how you create a Docker image and run it locally.

1.  Observe the [Dockerfile]({{< github_blob >}}/samples/bookinfo/src/ratings/Dockerfile):

    {{< text bash >}}
    $ more Dockerfile
    {{< /text >}}

1.  Build Docker image:

    {{< text bash >}}
    $ docker build -t $USER/ratings .
    {{< /text >}}

1.  Run ratings in Docker:

    {{< text bash >}}
    $ docker run -d -p 9081:9080 $USER/ratings
    {{< /text >}}

1.  Access [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) in your browser or by the _curl_ command:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {{< /text >}}

1.  Observe the running container:

    {{< text bash >}}
    $ docker ps
    {{< /text >}}

1.  Stop the running container:

    {{< text bash >}}
    $ docker stop <container ID>
    {{< /text >}}

1.  Go back to the Istio directory:

    {{< text bash >}}
    $ popd
    {{< /text >}}
