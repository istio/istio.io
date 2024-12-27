---
title: Видалення застарілої документації
description: Деталі про те, як видалити застарілу документацію з Istio.
weight: 4
aliases:
    - /uk/about/contribute/remove-content
    - /uk/latest/about/contribute/remove-content
keywords: [внесок]
owner: istio/wg-docs-maintainers
test: n/a
---

Щоб видалити документацію з Istio, дотримуйтесь цих простих кроків:

1. Видаліть сторінку.
1. Виправте зламані посилання.
1. Подайте свій внесок у GitHub.

## Видалення сторінки {#remove-the-page}

Використовуйте команду `git rm -rf`, щоб видалити теку, що містить сторінку `index.md`.

## Виправлення зламаних посилань {#reconcile-broken-links}

Щоб виправити зламані посилання, скористайтеся цією блок-схемою:

{{< image width="100%"
    link="./remove-documentation.svg"
    alt="Видалення документації Istio."
    caption="Видалення документації Istio"
    >}}

## Подання внеску на GitHub {#submit-your-contribution-to-github}

Якщо ви не знайомі з GitHub, перегляньте наш [посібник з роботи з GitHub](/docs/releases/contribute/github), щоб дізнатися, як подати зміни в документацію.

Якщо ви хочете дізнатися більше про те, як і коли публікуються ваші внески, перегляньте [розділ про гілки](/docs/releases/contribute/github#branching-strategy), щоб зрозуміти, як ми використовуємо гілки та вибіркове обʼєднання для публікації нашого контенту.
