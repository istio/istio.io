---
---
## Перш ніж розпочати {#before-you-begin}

* Налаштуйте Istio, дотримуючися інструкцій у [посібнику з встановлення](/docs/setup/).

    {{< tip >}}
    Egress gateway та доступ до логів будуть увімкнені, якщо ви встановите профіль конфігурації `demo` з [додаткових налаштувань](/docs/setup/additional-setup/config-profiles/).
    {{< /tip >}}

* Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl) для використання як джерело тестових запитів. Якщо у вас увімкнено [автоматичне додавання sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), виконайте наступну команду для розгортання демонстраційного застосунку:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    Інакше, вручну додайте sidecar перед розгортанням застосунку `curl` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Ви можете використовувати будь-який pod з встановленим `curl` як джерело тестів.
    {{< /tip >}}

* Встановіть змінну середовища `SOURCE_POD` на імʼя вашого podʼа:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}
