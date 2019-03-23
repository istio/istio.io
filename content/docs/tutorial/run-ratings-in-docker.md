---
title: Run ratings in Docker
overview: Run a single microservice in a Docker container.

weight: 20

---

This module shows how you create a [Docker](https://www.docker.com) image and run it locally.

1.  Download a [Dockerfile](https://docs.docker.com/engine/reference/builder/) for the `ratings` microservice.

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/Dockerfile -o Dockerfile
    {{< /text >}}

1.  Observe the Dockerfile.

    {{< text bash >}}
    $ cat Dockerfile
    {{< /text >}}

    Note that it copies the files
    into the container's filesystem and then runs the `npm install` command you ran in the previous module.
    The `CMD` command instructs Docker to run the `ratings` service on port `9080`.


1.  Build a Docker image:

    {{< text bash >}}
    $ docker build -t $USER/ratings .
    ...
    Step 9/9 : CMD node /opt/microservices/ratings.js 9080
    ---> Using cache
    ---> 77c6a304476c
    Successfully built 77c6a304476c
    Successfully tagged user/ratings:latest
    {{< /text >}}

1.  Run ratings in Docker. The following [docker run](https://docs.docker.com/engine/reference/commandline/run/) command
    instructs Docker to expose port `9080` of the container to port `9081` of your computer. You will access the
    `ratings` microservice by port `9081`.

    {{< text bash >}}
    $ docker run -d -p 9081:9080 $USER/ratings
    {{< /text >}}

1.  Access [http://localhost:9081/ratings/7](http://localhost:9081/ratings/7) in your browser or by the _curl_ command:

    {{< text bash >}}
    $ curl localhost:9081/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Observe the running container. Run the [docker ps](https://docs.docker.com/engine/reference/commandline/ps/) command
    to list all the running containers and notice the container with the image `<your user name>/ratings`.

    {{< text bash >}}
    $ docker ps
    CONTAINER ID        IMAGE                                             COMMAND                  CREATED             STATUS              PORTS                    NAMES
    47e8c1fe6eca        user/ratings                                    "/bin/sh -c 'node /o…"   2 minutes ago       Up 2 minutes        0.0.0.0:9081->9080/tcp   elated_stonebraker
    ...
    {{< /text >}}

1.  Stop the running container:

    {{< text bash >}}
    $ docker stop <the container ID from the output of docker ps>
    {{< /text >}}
