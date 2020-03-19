---
title: 在 Docker 中运行 ratings 服务
overview: 在一个 Docker 容器里运行一个微服务。

weight: 20

---

{{< boilerplate work-in-progress >}}

本模块展示了如何创建一个 [Docker](https://www.docker.com) 镜像并在本地运行它。

1. 下载微服务 `ratings` 的 [`Dockerfile`](https://docs.docker.com/engine/reference/builder/)。

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/Dockerfile -o Dockerfile
    {{< /text >}}

1. 观察这个`Dockerfile`。

    {{< text bash >}}
    $ cat Dockerfile
    {{< /text >}}

    请注意，它将文件复制到容器的文件系统中，然后执行你在上一个模块中执行过的 `npm install` 命令。
    `CMD` 命令指示 Docker 在 `9080` 端口上运行 `ratings` 服务。

1. 根据 `Dockerfile` 构建出一个镜像：

    {{< text bash >}}
    $ docker build -t $USER/ratings .
    ...
    Step 9/9 : CMD node /opt/microservices/ratings.js 9080
    ---> Using cache
    ---> 77c6a304476c
    Successfully built 77c6a304476c
    Successfully tagged user/ratings:latest
    {{< /text >}}

1. 在 Docker 中运行 `ratings` 服务. 接下来的 [docker run](https://docs.docker.com/engine/reference/commandline/run/) 命令
    指示 Docker 将容器的 `9080` 端口暴露到计算机的 `9081` 端口，从而允许你访问 `9081` 端口上的 `ratings` 微服务。

    {{< text bash >}}
    $ docker run -d -p 9081:9080 $USER/ratings
    {{< /text >}}

1. 在浏览器访问 [http://localhost:9081/ratings/7](http://localhost:9081/ratings/7)，或使用以下的 `curl` 命令：

    {{< text bash >}}
    $ curl localhost:9081/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1. 观察运行中的容器。执行 [docker ps](https://docs.docker.com/engine/reference/commandline/ps/) 命令，列出所有运行中的容器，同时
    注意镜像是 `<your user name>/ratings` 的容器。

    {{< text bash >}}
    $ docker ps
    CONTAINER ID        IMAGE            COMMAND                  CREATED             STATUS              PORTS                    NAMES
    47e8c1fe6eca        user/ratings     "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes        0.0.0.0:9081->9080/tcp   elated_stonebraker
    ...
    {{< /text >}}

1. 停止运行中的容器：

    {{< text bash >}}
    $ docker stop <the container ID from the output of docker ps>
    {{< /text >}}

现在，你已经准备好[部署应用程序](/zh/docs/examples/microservices-istio/bookinfo-kubernetes)。
