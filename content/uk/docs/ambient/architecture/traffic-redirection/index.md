---
title: Перенаправлення трафіку в Ztunnel
description: Зрозумійте, як трафік перенаправляється між podʼами і проксі-вузлом ztunnel.
weight: 5
aliases:
  - /uk/docs/ops/ambient/usage/traffic-redirection
  - /latest/uk/docs/ops/ambient/usage/traffic-redirection
owner: istio/wg-networking-maintainers
test: no
---

У контексті режиму ambient, _перенаправлення трафіку_ стосується функціональності панелі даних, яка перехоплює трафік, що надходить до і з навантажень, увімкнених в ambient, маршрутизуючи його через проксі вузлів {{< gloss >}}ztunnel{{< /gloss >}}, які обробляють основний шлях даних. Іноді також використовується термін _захоплення трафіку_.

Оскільки ztunnel має на меті прозоро шифрувати та маршрутизувати трафік застосунків, потрібен механізм для захоплення всього трафіку, що входить і виходить з "in mesh" podʼів. Це критично важливе завдання з погляду безпеки: якщо ztunnel можна обійти, можна обійти й політики авторизації.

## Модель перенаправлення трафіку в podʼах Istio {#istio-in-pod-traffic-redirection-model}

Основний принцип дизайну, що лежить в основі моделі перенаправлення трафіку в podʼах режиму ambient, полягає в тому, що проксі ztunnel має можливість виконувати захоплення шляху даних всередині мережевого простору імен Linux podʼа. Це досягається через співпрацю функціональності між [`istio-cni`  агентом вузла](/docs/setup/additional-setup/cni/) та проксі вузла ztunnel. Ключовою перевагою цієї моделі є те, що вона дозволяє ambient режиму Istio працювати разом з будь-яким втулком CNI Kubernetes прозоро і без впливу на функції мережі Kubernetes.

Наступна схема ілюструє послідовність подій, коли новий pod навантаження запускається в (або додається до) простору імен, доданого в ambient.

{{< image width="100%"
link="./pod-added-to-ambient.svg"
alt="Pod додано до flow ambient mesh"
>}}

Вузловий агент `istio-cni` реагує на події CNI, такі як створення та видалення podʼів, а також спостерігає за відповідним сервером API Kubernetes для подій, таких як додавання мітки ambient до podʼа або простору імен.

Вузловий агент `istio-cni` додатково встановлює ланцюговий втулок CNI, який виконується контейнерним середовищем після того, як основний втулок CNI в кластері Kubernetes виконується. Його єдина мета — повідомити вузловий агент `istio-cni`, коли новий pod створюється контейнерним середовищем у просторі імен, вже зареєстрованому в режимі ambient, і передати контекст нового podʼа до `istio-cni`.

Якщо вузловий агент `istio-cni` отримує сповіщення, що pod потрібно додати до mesh (або від втулка CNI, якщо pod новий, або від сервера API Kubernetes, якщо pod вже працює, але його потрібно додати), виконується наступна послідовність операцій:

- `istio-cni` входить у мережевий простір імен podʼа та встановлює правила перенаправлення мережі, так що пакети, що входять і виходять з podʼа, перехоплюються і прозоро перенаправляються до локального екземпляра проксі ztunnel, що слухає на [відомих портах](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).

- Вузловий агент `istio-cni` потім інформує проксі ztunnel через сокет Unix-домену, що йому потрібно встановити локальні порти прослуховування проксі всередині мережевого простору імен podʼа (на портах 15008, 15006 і 15001), і надає ztunnel низькорівневий [файловий дескриптор](https://en.wikipedia.org/wiki/File_descriptor), що представляє мережевий простір імен podʼа.
  - Хоча зазвичай сокети створюються всередині мережевого простору імен Linux процесом, що фактично працює всередині цього простору імен, цілком можливо використовувати низькорівневий API сокетів Linux, щоб дозволити процесу, що працює в одному мережевому просторі імен, створювати порти прослуховування в іншому мережевому просторі імен, за умови, що цільовий мережевий простір імен відомий на момент створення.

- Локальний ztunnel на вузлі створює новий логічний екземпляр проксі-сервера і набір портів для прослуховування, призначених для щойно доданого podʼа. Зауважте, що це все ще виконується у межах того самого процесу і є лише окремим завданням для цього podʼа.

- Коли правила перенаправлення всередині podʼа встановлені і ztunnel створив порти прослуховування, pod додається в mesh, і трафік починає текти через локальний ztunnel.

Трафік до і з podʼів у mesh стандартно буде повністю зашифрований за допомогою mTLS.

Дані тепер будуть входити й виходити з мережевого простору імен podʼа в зашифрованому вигляді. Кожен pod у mesh має можливість застосовувати політику mesh і надійно шифрувати трафік, навіть якщо застосунок користувача, що працює в podʼф, не має інформації про це.

Ця схема ілюструє, як зашифрований трафік тече між podʼами в ambient mesh у новій моделі:

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE трафік між подами в ambient mesh"
    >}}

## Спостереження та налагодження перенаправлення трафіку в режимі ambient {#observing-and-debugging-traffic-redirection-in-ambient-mode}

Якщо перенаправлення трафіку не працює належним чином у режимі ambient, можна провести кілька швидких перевірок, щоб допомогти звузити проблему. Рекомендується почати усунення неполадок з кроків, описаних у [посібнику з налагодження ztunnel](/docs/ambient/usage/troubleshoot-ztunnel/).

### Перевірте журнали проксі ztunnel {#check-the-ztunnel-proxy-logs}

Коли pod застосунку є частиною ambient mesh, можна перевірити журнали проксі ztunnel, щоб підтвердити, що mesh перенаправляє трафік. Як показано в наведеному нижче прикладі, журнали ztunnel, повʼязані з `inpod`, вказують, що режим перенаправлення всередині podʼа увімкнено, проксі отримав інформацію про мережевий простір імен (netns) про pod застосунку ambient, і почав проксирування для нього.

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system | grep inpod
Found 3 pods, using pod/ztunnel-hl94n
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-02-21T22:01:49.916037Z INFO ztunnel::inpod::workloadmanager: handling new stream
2024-02-21T22:01:49.919944Z INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
2024-02-21T22:01:49.925997Z INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-02-21T22:03:49.074281Z INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
2024-02-21T22:04:58.446444Z INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
{{< /text >}}

### Підтвердження стану сокетів {#confirm-the-state-of-sockets}

Виконайте наведені нижче кроки, щоб підтвердити, що сокети на портах 15001, 15006 та 15008 відкриті та знаходяться у стані прослуховування.

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it -n ambient-demo --image nicolaka/netshoot -- ss -ntlp
Defaulting debug container name to debugger-nhd4d.
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:15080      0.0.0.0:*
LISTEN 0      128                *:15006            *:*
LISTEN 0      128                *:15001            *:*
LISTEN 0      128                *:15008            *:*
{{< /text >}}

### Перевірте налаштування правил iptables {#check-the-iptables-rules-setup}

Щоб переглянути налаштування правил iptables всередині одного з podʼів застосунку, виконайте цю команду:

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it --image gcr.io/istio-release/base --profile=netadmin -n ambient-demo -- iptables-save

Defaulting debug container name to debugger-m44qc.
# Generated by iptables-save
*mangle
:PREROUTING ACCEPT [320:53261]
:INPUT ACCEPT [23753:267657744]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [23352:134432712]
:POSTROUTING ACCEPT [23352:134432712]
:ISTIO_OUTPUT - [0:0]
:ISTIO_PRERT - [0:0]
-A PREROUTING -j ISTIO_PRERT
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -m connmark --mark 0x111/0xfff -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
-A ISTIO_PRERT -m mark --mark 0x539/0xfff -j CONNMARK --set-xmark 0x111/0xfff
-A ISTIO_PRERT -s 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -i lo -p tcp -j ACCEPT
-A ISTIO_PRERT -p tcp -m tcp --dport 15008 -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15008 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
-A ISTIO_PRERT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15006 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
COMMIT
# Completed
# Generated by iptables-save
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [175:13694]
:POSTROUTING ACCEPT [205:15494]
:ISTIO_OUTPUT - [0:0]
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -d 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_OUTPUT -p tcp -m mark --mark 0x111/0xfff -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j REDIRECT --to-ports 15001
COMMIT
{{< /text >}}

Вивід команди показує, що до таблиць NAT та Mangle у netfilter/iptables у мережевому просторі імен podʼа додано додаткові специфічні для Istio ланцюги. Весь TCP трафік, що надходить до podʼа, перенаправляється до проксі ztunnel для обробки входу. Якщо трафік є незашифрованим (порт призначення != 15008), він буде перенаправлений до порту прослуховування plaintext проксі ztunnel всередині podʼа на порту 15006. Якщо трафік є HBONE (порт призначення == 15008), він буде перенаправлений до порту прослуховування HBONE проксі ztunnel всередині podʼа на порту 15008. Будь-який TCP трафік, що виходить з podʼа, перенаправляється на порт 15001 проксі ztunnel для обробки виходу перед відправленням через ztunnel з використанням інкапсуляції HBONE.
