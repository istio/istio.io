---
title: Домен довіри
test: n/a
---

[Домен довіри](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#trust-domain) відповідає кореню довіри системи і є частиною ідентичності навантаження.

Istio використовує домен довіри для створення всіх [ідентичностей](/docs/reference/glossary/#identity) у мережі. Наприклад, у `spiffe://mytrustdomain.com/ns/default/sa/myname` рядок `mytrustdomain.com` вказує, що навантаження походить з домену довіри з назвою `mytrustdomain.com`.

Ви можете мати один або кілька доменів довіри у багатокластерній мережі, якщо кластери мають спільний корінь довіри.
