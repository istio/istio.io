---
title: Додавання блоків коду
description: Пояснює, як включати код у вашу документацію.
weight: 8
aliases:
  - /uk/about/contribute/code-blocks
  - /latest/uk/about/contribute/code-blocks
keywords: [внесок, документація, посібник, блоки-коду]
owner: istio/wg-docs-maintainers
test: n/a
---

Блоки коду в документації Istio є форматованими блоками вмісту. Ми використовуємо Hugo для побудови нашого вебсайту, і він використовує короткі коди `text` та `text_import` для додавання коду на сторінку.

Використання такої розмітки дозволяє нам надати нашим читачам кращий досвід. Ці блоки коду можна легко скопіювати, надрукувати або завантажити.

Використання цих коротких кодів є обовʼязковим для всього контенту. Якщо ваш контент не використовує відповідні короткі коди, він не буде обʼєднаний, поки не буде відповідати цим вимогам. Ця сторінка містить кілька прикладів вбудованих блоків і доступних параметрів форматування.

Найпоширеніший приклад блоків коду — це команди командного рядка (CLI), наприклад:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

Короткий код вимагає, щоб ви починали кожну команду CLI з `$`, і він перетворює вміст наступним чином:

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

Ви можете мати кілька команд у блоці коду, але короткий код розпізнає лише один вивід, наприклад:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

Стандартно і з заданим атрибутом `bash`, команди показуються з підсвічуванням синтаксису bash, а вихідний текст показується як простий текст, наприклад:

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

Для зручності читання ви можете використовувати `\` для продовження довгих команд на нових рядках. Нові рядки повинні мати відступ, наприклад:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{</* /text */>}}
{{< /text >}}

Hugo без проблем показує багаторядкову команду:

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

Ваші {{<gloss "Робоче навантаження">}}робочі навантаження{{</gloss>}} можуть бути написані різними мовами програмування. Тому ми реалізували підтримку кількох поєднань підсвічування синтаксису в блоках коду.

## Додавання підсвічування синтаксису {#add-syntax-highlighting}

Розпочнемо з наступного прикладу "Hello World":

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

Атрибут `plain` показує код без підсвічування синтаксису:

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

Ви можете встановити мову коду в блоці для підсвічування його синтаксису. Попередній приклад встановлює синтаксис як `plain`, і показаний блок коду не має жодного підсвічування синтаксису. Однак ви можете встановити синтаксис як Go, наприклад:

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

Тоді Hugo додає відповідне підсвічування:

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

### Підтримуваний синтаксис {#supported-syntax}

Блоки коду в Istio підтримують наступні мови з підсвічуванням синтаксису:

- `plain`
- `markdown`
- `yaml`
- `json`
- `java`
- `javascript`
- `c`
- `cpp`
- `csharp`
- `go`
- `html`
- `protobuf`
- `perl`
- `docker`
- `bash`

Стандартно вихідні дані CLI команд вважаються простим текстом і показуються без підсвічування синтаксису. Якщо вам потрібно додати підсвічування синтаксу до виводу, ви можете вказати мову в коді. У Istio найбільш поширені приклади — це виводи YAML або JSON, наприклад:

{{< text markdown >}}
{{</* text bash json */>}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{</* /text */>}}
{{< /text >}}

Показує команди з підсвічуванням синтаксису bash і вивід з відповідним підсвічуванням синтаксису JSON.

## Динамічний імпорт коду у ваш документ {#dynamic-import-code-into-your-document}

Попередні приклади демонструють, як форматувати код у вашому документі. Однак ви також можете використовувати код `text_import`, щоб додати вміст або код з файлу. Файл може бути збережений у репозиторії документації або в зовнішньому джерелі з увімкненою підтримкою Cross-Origin Resource Sharing (CORS).

### Імпорт коду з файлу в репозиторії `istio.io` {#import-code-from-a-file-in-the-istioio-repository}

Використовуйте атрибут `file`, щоб додати вміст з файлу в репозиторії документації Istio, наприклад:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

Вищенаведений приклад показує вміст файлу як простий текст:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

Встановіть мову вмісту через поле `syntax=`, щоб отримати відповідне підсвічування синтаксису.

### Імпорт коду з зовнішнього джерела через URL {#import-code-from-an-external-source-through-a-url}

Аналогічно, ви можете динамічно додавати вміст з Інтернету. Використовуйте атрибут `url`, щоб вказати джерело. Наступний приклад додає той самий файл, але через URL:

{{< text markdown >}}
{{</* text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

Як бачите, вміст показується так само як і раніше:

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

Якщо файл з іншого джерела, CORS має бути увімкнено на цьому сайті. Зазначте, що сайт GitHub raw content (`raw.githubusercontent.com`) може бути використаний тут.

### Імпорт фрагмента коду з великого файлу {#snippets}

Іноді вам не потрібен вміст усього файлу. Ви можете контролювати, які частини вмісту відображати, використовуючи _іменовані фрагменти_. Позначте код, який ви хочете в фрагменті, коментарями, що містять теги `$snippet SNIPPET_NAME` та `$endsnippet`. Вміст між двома теґами представляє фрагмент. Наприклад, візьмемо наступний файл:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

Файл має три окремі фрагменти: `SNIP1`, `SNIP2`, і `SNIP3`. Зазвичай фрагменти іменуються великими літерами. Щоб послатися на конкретний фрагмент у вашому документі, встановіть значення атрибута `snippet` у коді на імʼя фрагмента, наприклад:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

Отриманий блок коду включає лише код фрагмента `SNIP1`:

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

Ви можете використовувати атрибут `syntax` коду `text_import`, щоб вказати синтаксис фрагмента. Для фрагментів, що містять CLI команди, ви можете використовувати атрибут `outputis`, щоб вказати синтаксис виходу.

## Посилання на файли в GitHub {#link-2-files}

Деякі блоки коду потребують посилання на файли з [репозиторію GitHub Istio](https://github.com/istio/istio). Найпоширеніший приклад — посилання на YAML конфігураційні файли. Замість того, щоб копіювати весь вміст YAML файлу у ваш блок коду, ви можете обгорнути відносний шлях до файлу символами `@`. Це розмітка відображає шлях як посилання на файл з поточної гілки релізу в GitHub, наприклад:

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

Шлях відображається як посилання, яке веде вас до відповідного файлу:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

Стандартно ці посилання вказують на поточну гілку релізу репозиторію `istio/istio`. Щоб посилання вказувало на інший репозиторій Istio, ви можете використовувати атрибут `repo`, наприклад:

{{< text markdown >}}
{{</* text syntax="bash" repo="api" */>}}
$ cat @README.md@
{{</* /text */>}}
{{< /text >}}

Шлях відображається як посилання на файл `README.md` репозиторію `istio/api`:

{{< text syntax="bash" repo="api" >}}
$ cat @README.md@
{{< /text >}}

Іноді ваш блок коду використовує `@` для чогось іншого. Ви можете включити та вимкнути розширення посилання за допомогою атрибута `expandlinks`, наприклад:

{{< text markdown >}}
{{</* text syntax="bash" expandlinks="false" */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

## Розширені функції {#advanced-features}

Щоб використовувати більш розширені функції для попередньо відформатованого вмісту, які описані в наступних розділах, використовуйте розширену форму послідовності `text`, а не спрощену форму, показану досі. Розширена форма використовує звичайні HTML атрибути:

{{< text markdown >}}
{{</* text syntax="bash" outputis="json" */>}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{</* /text */>}}
{{< /text >}}

Доступні атрибути:

| Атрибут      | Опис
|--------------|------------
|`file`        | Шлях до файлу для відображення в попередньо відформатованому блоці.
|`url`         | URL документа для відображення в попередньо відформатованому блоці.
|`syntax`      | Синтаксис попередньо відформатованого блоку.
|`outputis`    | Коли синтаксис є `bash`, це вказує на синтаксис виходу команди.
|`downloadas`  | Назва файлу, яка використовується, коли користувач [завантажує попередньо відформатований блок](#download-name).
|`expandlinks` | Чи розширювати [посилання на файли GitHub](#link-2-files) у попередньо відформатованому блоці.
|`snippet`     | Назва [фрагмента](#snippets) вмісту для витягування з попередньо відформатованого блоку.
|`repo`        | Репозиторій для [посилань GitHub](#link-2-files), вбудованих у попередньо відформатовані блоки.

### Назва для завантаження {#download-name}

Ви можете визначити назву, яка використовується, коли хтось вирішує завантажити блок коду, з допомогою атрибута `downloadas`, наприклад:

{{< text markdown >}}
{{</* text syntax="go" downloadas="hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

Якщо ви не вкажете назву для завантаження, Hugo автоматично визначить її на основі одного з таких можливих імен:

- Назва поточної сторінки для вбудованого вмісту
- Назва файлу, що містить імпортований код
- URL джерела імпортованого коду
