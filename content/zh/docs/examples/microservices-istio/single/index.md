---
title: 本地运行微服务
overview: 学习如何在本地机器上进行单一服务的工作。
weight: 10
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

在微服务架构出现之前，开发团队会将整个应用程序作为一个大型软件进行构建、
部署和运行。想要测试模块中一个微小的改变，开发人员不仅要通过单元测试，
他们必须重新构建整个程序。因此，构建需要花费大量的时间。完成构建后，
开发人员将应用程序版本部署到测试服务器上。他们会把服务跑在远程或本地计算机中。
在后一种情况下，开发者会在他们的本地计算机上安装并管理一个相当复杂的环境。

在微服务架构时代，开发人员编写、构建、测试和运行小型的软件服务。构建是快速的。
使用类似 [Node.js](https://nodejs.org/zh-cn/) 这样的现代框架，
由于服务是作为常规进程来运行的，就不需要安装并管理复杂的服务环境来测试它了。
您不再仅仅为了测试您的服务就得将它部署到某个环境了，
您只需要构建您的服务并且直接在您本地机器上运行即可。

该模块涵盖了在本地机器上开发单个服务所涉及的不同方面。
不过，您无需编写代码，只需要编译、运行和测试现有服务 `rating`。

`ratings` 服务是用 [Node.js](https://nodejs.org/zh-cn/)
编写的一个可以单独运行的小型 Web 应用程序。它与其他 Web 应用程序执行类似的操作：

- 监听它作为参数接受的端口。
- 接受在 `/ratings/{productID}` 路径上的 `HTTP GET` 请求，
  并返回与客户端指定的 `productID` 的值所匹配的产品的评级。
- 接受在 `/ratings/{productID}` 路径上的 `HTTP POST` 请求，
  并更新与您指定的 `productID` 的值所匹配的产品的评级。

请按照下列步骤下载应用程序的代码，安装其依赖项，然后在本地运行它：

1. 将[服务代码]({{< github_blob >}}/samples/bookinfo/src/ratings/ratings.js)和
   [其 package 文件]({{< github_blob >}}/samples/bookinfo/src/ratings/package.json)
   下载到一个单独的目录中：

    {{< text bash >}}
    $ mkdir ratings
    $ cd ratings
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/ratings.js -o ratings.js
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/package.json -o package.json
    {{< /text >}}

1. 浏览服务的代码，并注意代码中以下元素：
    - Web 服务器的特征：
        - 监听一个端口
        - 处理请求和响应
    - 与 HTTP 相关的方面：
        - 请求头
        - 路径
        - 状态码

    {{< tip >}}
    在 Node.js 中，Web 服务器的功能嵌入在应用程序的代码中。
    一个 Node.js Web 应用程序作为一个独立进程运行。
    {{< /tip >}}

1. Node.js 应用程序是用 JavaScript 编写的，这意味着没有显式编译步骤。
   相反，它们使用 [just-in-time 即时编译](https://zh.wikipedia.org/wiki/%E5%8D%B3%E6%99%82%E7%B7%A8%E8%AD%AF)。
   要构建 Node.js 应用程序，则意味着要安装其依赖库。
   将 `rating` 服务的依赖库安装在存储服务代码和 package 文件的同一目录下：

    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1. 通过传递 `9080` 参数来运行服务，然后应用程序在 9080 端口上监听。

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

{{< tip >}}
该 `ratings` 服务是一个 Web 应用程序，
您可以像访问其他 Web 应用程序那样访问它。您可以使用浏览器或者像
[`curl`](https://curl.haxx.se) 或 [`Wget`](https://www.gnu.org/software/wget/)
的命令行 Web 客户端。由于您在本地运行了 `rating` 服务，
因此您也可以通过 `localhost` 主机名访问它。
{{< /tip >}}

1. 在浏览器中打开 [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7)
   或者使用 `curl` 命令来访问 `ratings`：

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1. 使用 `curl` 命令的 POST 方法将产品的评级设置为 1：

    {{< text bash >}}
    $ curl -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. 检查更新的评级：

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. 在运行服务的终端上使用 `Ctrl-C` 停止该服务。

恭喜，您现在可以在本地计算机上构建、测试和运行服务了！

您已经做好了[如何打包服务](/zh/docs/examples/microservices-istio/package-service)到容器的准备了。
