---
title: Запуск ratings у Docker
overview: Запустіть окремий мікросервіс у контейнері Docker.

weight: 20

owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Цей модуль демонструє, як створити образ [Docker](https://www.docker.com) та запустити його локально.

1. Завантажте [`Dockerfile`](https://docs.docker.com/engine/reference/builder/) для мікросервісу `ratings`.

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/Dockerfile -o Dockerfile
    {{< /text >}}

2. Ознайомтесь з `Dockerfile`.

    {{< text bash >}}
    $ cat Dockerfile
    {{< /text >}}

    Зверніть увагу, що він копіює файли у файлову систему контейнера, а потім виконує команду `npm install`, яку ви виконували в попередньому модулі. Команда `CMD` інструктує Docker запустити сервіс `ratings` на порту `9080`.

3. Створіть змінну середовища для збереження вашого ідентифікатора користувача, який буде використовуватися для теґування образу Docker для сервісу `ratings`. Наприклад, `user`.

    {{< text bash >}}
    $ export USER=user
    {{< /text >}}

4. Зберіть Docker образ з `Dockerfile`:

    {{< text bash >}}
    $ docker build -t $USER/ratings .
    ...
    Step 9/9 : CMD node /opt/microservices/ratings.js 9080
    ---> Using cache
    ---> 77c6a304476c
    Successfully built 77c6a304476c
    Successfully tagged user/ratings:latest
    {{< /text >}}

5. Запустіть `ratings` у Docker. Наступна команда [docker run](https://docs.docker.com/engine/reference/commandline/run/) інструктує Docker відкрити порт `9080` контейнера для порту `9081` вашого компʼютера, що дозволяє вам отримати доступ до мікросервісу `ratings` на порту `9081`.

    {{< text bash >}}
    $ docker run --name my-ratings --rm -d -p 9081:9080 $USER/ratings
    {{< /text >}}

6. Отримайте доступ до [http://localhost:9081/ratings/7](http://localhost:9081/ratings/7) у вашому оглядачі або скористайтеся наступною командою `curl`:

    {{< text bash >}}
    $ curl localhost:9081/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

7. Огляньте працюючий контейнер. Виконайте команду [docker ps](https://docs.docker.com/engine/reference/commandline/ps/), щоб показати всі працюючі контейнери та зверніть увагу на контейнер з образом `<your user name>/ratings`.

    {{< text bash >}}
    $ docker ps
    CONTAINER ID        IMAGE            COMMAND                  CREATED             STATUS              PORTS                    NAMES
    47e8c1fe6eca        user/ratings     "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes        0.0.0.0:9081->9080/tcp   elated_stonebraker
    ...
    {{< /text >}}

8. Зупиніть працюючий контейнер:

    {{< text bash >}}
    $ docker stop my-ratings
    {{< /text >}}

Ви навчилися упаковувати один сервіс у контейнер. Наступний крок — дізнатися, як [розгортати весь застосунок у кластер Kubernetes](/docs/examples/microservices-istio/bookinfo-kubernetes).
