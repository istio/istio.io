---
title: Використання інструменту командного рядка Istioctl
description: Istio включає додатковий інструмент, що надає можливості для налагодження та діагностики розгортання сервісної мережі Istio.
weight: 10
keywords: [istioctl,bash,zsh,shell,command-line]
aliases:
  - /uk/help/ops/component-debugging
  - /uk/docs/ops/troubleshooting/istioctl
owner: istio/wg-user-experience-maintainers
test: no
---

Ви можете отримати уявлення про те, що роблять окремі компоненти, переглядаючи їх [журнали](/docs/ops/diagnostic-tools/component-logging/) або заглядаючи всередину за допомогою [інтроспекції](/docs/ops/diagnostic-tools/controlz/). Якщо цього недостатньо, нижче описано, як заглянути під капот.

Інструмент [`istioctl`](/docs/reference/commands/istioctl) — це інструмент командного рядка для конфігурації, який дозволяє операторам сервісів налагоджувати та діагностувати свої розгортання сервісної мережі Istio. Проєкт Istio також включає два корисні скрипти для `istioctl`, які забезпечують автодоповнення для Bash і Zsh. Обидва скрипти підтримують команди, доступні в поточній версії `istioctl`.

{{< tip >}}
`istioctl` підтримує автодоповнення лише для команд, що не визнані застарілими.
{{< /tip >}}

## Перед початком {#before-you-begin}

Рекомендуємо використовувати ту ж версію `istioctl`, що й версія вашої панелі управління Istio. Використання однакових версій допомагає уникнути непередбачуваних проблем.

{{< tip >}}
Якщо ви вже [завантажили випуск Istio](/docs/setup/additional-setup/download-istio-release/), ви вже маєте `istioctl` і не потрібно встановлювати його знову.
{{< /tip >}}

## Встановлення `istioctl` {#install-istioctl}

Встановіть бінарний файл `istioctl` за допомогою `curl`:

1. Завантажте останній випуск командою:

    {{< text bash >}}
    $ curl -sL https://istio.io/downloadIstioctl | sh -
    {{< /text >}}

1. Додайте клієнт `istioctl` до вашого шляху в системі macOS або Linux:

    {{< text bash >}}
    $ export PATH=$HOME/.istioctl/bin:$PATH
    {{< /text >}}

1. Ви можете опціонально увімкнути [опцію автодоповнення](#enabling-auto-completion) під час роботи з консоллю bash або Zsh.

## Огляд вашої мережі {#get-an-overview-of-your-mesh}

Ви можете отримати огляд вашої мережі за допомогою команди `proxy-status` або `ps`:

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

Якщо у виведеному списку відсутній проксі, це означає, що він наразі не підключений до екземпляра istiod і тому не отримає жодної конфігурації. Крім того, якщо він позначений як застарілий, це, ймовірно, свідчить про проблеми з мережею або необхідність масштабування istiod.

## Отримання конфігурації проксі {#get-proxy-configuration}

Інструмент [`istioctl`](/docs/reference/commands/istioctl) дозволяє отримати інформацію про конфігурацію проксі за допомогою команди `proxy-config` або `pc`.

Наприклад, щоб отримати інформацію про конфігурацію кластерів для екземпляра Envoy у конкретному podʼі:

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

Щоб отримати інформацію про початкову конфігурацію для екземпляра Envoy у конкретному podʼі:

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

Щоб отримати інформацію про конфігурацію слухачів для екземпляра Envoy у конкретному podʼі:

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

Щоб отримати інформацію про конфігурацію маршрутів для екземпляра Envoy у конкретному podʼі:

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

Щоб отримати інформацію про конфігурацію кінцевих точок для екземпляра Envoy у конкретному podʼі:

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

Дивіться [Налагодження Envoy та Istiod](/docs/ops/diagnostic-tools/proxy-cmd/) для отримання порад щодо інтерпретації цієї інформації.

## Автодоповнення `istioctl` {#istioctl-auto-completion}

{{< tabset category-name="prereqs" >}}

{{< tab name="macOS" category-value="macos" >}}

Якщо ви використовуєте операційну систему macOS з оболонкою термінала Zsh, переконайтеся, що пакет `zsh-completions` встановлено. За допомогою менеджера пакетів [brew](https://brew.sh) для macOS, ви можете перевірити, чи встановлено пакет `zsh-completions`, за допомогою наступної команди:

{{< text bash >}}
$ brew list zsh-completions
/usr/local/Cellar/zsh-completions/0.34.0/share/zsh-completions/ (147 files)
{{< /text >}}

Якщо ви отримуєте повідомлення `Error: No such keg: /usr/local/Cellar/zsh-completion`, встановіть пакет `zsh-completions` за допомогою наступної команди:

{{< text bash >}}
$ brew install zsh-completions
{{< /text >}}

Після того, як пакет `zsh-completions` буде встановлено на вашій системі macOS, додайте наступне до вашого файлу `~/.zshrc`:

{{< text plain >}}
    if type brew &>/dev/null; then
      FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

      autoload -Uz compinit
      compinit
    fi
{{< /text >}}

Можливо, вам також потрібно буде примусово перебудувати `zcompdump`:

{{< text bash >}}
$ rm -f ~/.zcompdump; compinit
{{< /text >}}

Крім того, якщо ви отримуєте попередження `Zsh compinit: insecure directories` під час спроби завантажити ці доповнення, можливо, потрібно виконати наступну команду:

{{< text bash >}}
$ chmod -R go-w "$(brew --prefix)/share"
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" category-value="linux" >}}

Якщо ви використовуєте операційну систему на основі Linux, ви можете встановити пакет автодоповнення Bash за допомогою команди `apt-get install bash-completion` для дистрибутивів Linux на основі Debian або `yum install bash-completion` для дистрибутивів на основі RPM, що є двома найбільш поширеними випадками.

Після встановлення пакету `bash-completion` на вашій системі Linux, додайте наступний рядок до вашого файлу `~/.bash_profile`:

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Увімкнення автодоповнення {#enabling-auto-completion}

Щоб увімкнути автодоповнення для `istioctl` у вашій системі, виконайте кроки для вашої улюбленої оболонки:

{{< warning >}}
Вам потрібно буде завантажити повний випуск Istio, який містить файли автодоповнення (у теці `/tools`). Якщо ви ще цього не зробили, [завантажте повний випуск](/docs/setup/additional-setup/download-istio-release/) зараз.
{{< /warning >}}

{{< tabset category-name="profile" >}}

{{< tab name="Bash" category-value="bash" >}}

Встановлення файлу автодоповнення для Bash

Якщо ви використовуєте bash, файл автодоповнення для `istioctl` знаходиться в теці `tools`. Щоб його використовувати, скопіюйте файл `istioctl.bash` у вашу домашню теку, а потім додайте наступний рядок до вашого файлу `.bashrc`, щоб увімкнути автодоповнення:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="Zsh" category-value="zsh" >}}

Встановлення файлу автодоповнення для Zsh

Для користувачів Zsh файл автодоповнення для `istioctl` знаходиться в теці `tools`. Скопіюйте файл `_istioctl` у вашу домашню теку або будь-яку іншу теку на ваш вибір (оновіть шлях до файлу в наведеному нижче прикладі), а потім увімкніть файл автодоповнення для `istioctl` у файлі `.zshrc`, додавши такий рядок:

{{< text zsh >}}
source ~/_istioctl
{{< /text >}}

Також можна додати файл `_istioctl` до теки, зазначеного в змінній `fpath`. Щоб це зробити, помістіть файл `_istioctl` в наявну теку зі змінної `fpath` або створіть нову теку і додайте її до змінної `fpath` у вашому файлі `~/.zshrc`.

{{< tip >}}

Якщо ви отримуєте помилку на кшталт `complete:13: command not found: compdef`, додайте наступне на початку вашого файлу `~/.zshrc`:

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

Якщо автодоповнення не працює, спробуйте повторно запустити термінал. Якщо автодоповнення все ще не працює, спробуйте скинути кеш автодоповнення, використовуючи наведені вище команди.

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

### Використання автодоповнення {#using-auto-completion}

Якщо файл автодоповнення для `istioctl` було правильно встановлено, натисніть клавішу Tab під час введення команди `istioctl`, і ви отримаєте перелік можливих варіантів команд:

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}
