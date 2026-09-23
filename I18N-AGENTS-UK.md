# i18n conventions for Ukrainian (UK) translations

This document defines **translation conventions for the Ukrainian site content** (`content/uk/**`).
It is intentionally written in **English** so both Ukrainian translators and non-Ukrainian reviewers can align.

If an existing UK page conflicts with these conventions, **do not “mass-fix” it**. Apply these rules to new/edited text and improve consistency opportunistically.

## Related documentation (must read)

- Terminology guide (docs contribution): `/uk/docs/releases/contribute/terminology/` (**Стандарти термінології**)
- Glossary (reference): `/uk/docs/reference/glossary/`

## Core principle

Prefer **technical accuracy and consistency** over literal translation. Many Istio/Kubernetes concepts are proper nouns or widely-used terms in English; translating them often reduces clarity. For equal candidates, prefer the term that is **already dominant in the current `content/uk/**` corpus** so older and newer pages stay aligned.

## Terminology: keep these in English (no translation / no transliteration)

Use Ukrainian articles, case endings and prepositions around the English term where the grammar requires it (added as suffixes when the term is used in a declined case).

- **mesh**: use **“mesh”**. Do **not** transliterate to «меш».
- **service mesh**: keep **“service mesh”** (the terminology guide explicitly lists `service mesh`); may be translated as **«сервісна мережа»** where it reads naturally (avoid «мережа сервісів»).
- **sidecar**: keep **“sidecar”** (do not translate).
- **workload**: keep **“workload”** in technical contexts; may be translated as **«робоче навантаження»** (prefer the Ukrainian form in running prose).
- **Ambient / ambient mode**: keep **“ambient”** as the feature name; prefer **«режим ambient»** for “ambient mode”.
- **waypoint**: keep **“waypoint”** (and “waypoint proxy” as-is).
- **ztunnel**: keep **“ztunnel”**.
- **Envoy**: keep **“Envoy”**.
- **EnvoyFilter / Envoy proxy**: keep as-is.
- **Gateway**: for the Kubernetes/Istio `Gateway` object kind and “Gateway API”, keep **“Gateway”**. Only the generic computational sense may be translated (see below).
- **Kubernetes**: keep **“Kubernetes”** (terminology guide forbids `kubernetes` / `k8s`).
- **Istio resources / CRDs** (e.g., `VirtualService`, `DestinationRule`, `PeerAuthentication`, `ServiceEntry`, `AuthorizationPolicy`): **never translate resource kind names**.
- **`K8s`/`k8s`**: never use.
- **`vs.` style versions**: keep version numbers and codenames as-is.

## Terminology: prefer Ukrainian translations

These are safe and expected in Ukrainian:

- **control plane** → «панель управління»
- **data plane** → «панель даних»
- **namespace** → «простір імен» (accepted; both «простір імен» and English “namespace” appear in the corpus — prefer «простір імен» in running text, keep “namespace“ in code/paths)
- **cluster** → «кластер» (plural «кластери»); English “cluster” is also acceptable
- **certificate** → «сертифікат»
- **mutual TLS** → «взаємний TLS»
- **addon** → «надбудова»
- **traffic** → «трафік»
- **observability** → «спостережуваність»
- **authentication / authorization** → «автентифікація / авторизація»
- **policy** → «політика»
- **installation / install** → «встановлення / встановити»
- **configuration** → «конфігурація» (not «config» as a word)
- **distributed tracing / tracing** → «розподілене трасування / трасування»

## Canonical term choices (use these consistently)

Use these canonical choices across Ukrainian content:

- **mesh**: “mesh” (avoid «меш» and «мережа сервісів»)
- **control plane / data plane**: «панель управління» / «панель даних» (prefer the translated form over English “control plane” / “data plane”)
- **namespace**: «простір імен» (preferred in prose; “namespace” acceptable in tight technical context)
- **gateway**: prefer “gateway” for the object kind; «шлюз» is acceptable for generic conceptual usage
- **sidecar**: “sidecar”
- **plugin**: «втулок» (never «плагін»; masculine gender, so decline accordingly: «втулка», «втулком»…)
- **traffic management**: prefer «керування трафіком» (also seen: «управління трафіком» — pick one within a page and stay consistent)
- **waypoint**: "waypoint"
- **ambient mode**: «режим ambient»

## Style guidelines (Ukrainian)

- **Voice**: prefer the plural/formal-yet-friendly voice already used across the site (Ми / ви / ваші, e.g. «Ми рекомендуємо вам оновитися…»). The “ти” singular is only appropriate where a page already uses it.
- **Clarity**: short sentences; avoid overly literal calques from English; pay attention to correct Ukrainian case endings and prepositions (`з`/`зі`/`із`, `до`/`у`).
- **Consistency**: once you pick a term within a page/section, keep using it (don't alternate between synonyms).
- **Gender/number around English terms**: English nouns keep their form; Ukrainian case is expressed by adding suffixes or prepositions (e.g. «до останньої версії», «у 1.25», «waypoint-ом» is **not** used for English terms — prefer to rephrase rather than force a transliterated case ending).
- **Register**: prefer «Повідомлення про завершення життєвого циклу Istio X.» for announcement descriptions.

## Formatting and markup rules

- **Paragraph line wrapping**: the UK version keeps **long lines for paragraphs** (a whole paragraph on one line). Do **not** break paragraphs into multiple short lines.
- **Do not translate code, CLI output, API fields, YAML keys, or filenames/paths.**
- **Inline code and code blocks**: keep exactly as in the source language.
- **Comments inside code blocks**: translate them to Ukrainian where possible (e.g., `# This installs the addon` → `# Це встановлює надбудову`), as long as they are not part of executable output or required syntax.
- **Hugo shortcodes / gloss tags** (e.g., `{{< gloss >}}...{{< /gloss >}}`): do not change the shortcode structure. Note: `{{<istio_release_name>}}` and `{{< istio_release_name >}}` both work, but keep the form consistent within a page.
- **Links**:
  - Keep URLs unchanged.
  - Translate the **link text** unless it is a product name, resource kind, command, or code.
- **Apostrophe**: use the Unicode modifier letter apostrophe **U+02BC (ʼ)** for Ukrainian «’»/«ʼ» inside Ukrainian words (e.g. «зʼєднання»), not the ASCII `'` and not the typographic curly apostrophe where the modifier letter is expected.
- **Anchors**: section anchors in Ukrainian must match the English Hugo anchors via explicit `{#en-anchor}` — do not create translated anchors.
- **Ellipsis / dashes**: prefer `&nbsp;&mdash;` for mid-sentence em-dashes where the EN source uses `—`.

## Quick “Do / Don’t” examples

- **mesh**
  - ✅ «Підключіть свої робочі навантаження до **mesh**»
  - ❌ «Підключіть свої робочі навантаження до **меш**»
- **resource kinds**
  - ✅ «Створіть `VirtualService`…»
  - ❌ «Створіть `ВіртуальнийСервіс`…»
- **control plane / data plane**
  - ✅ «**панель управління**», «**панель даних**»
  - ❌ «control plane», «data plane» як основний термін у прозі
- **namespace**
  - ✅ «у просторі імен `default`»
  - ❌ «в namespace default» (у звичайній прозі)
- **mode names**
  - ✅ «У **режимі ambient**…»
  - ❌ «У режимі оточення/ambiental…»

## When in doubt

Add a short note in the PR describing the choice and rationale (accuracy/consistency). If a term is controversial, prefer matching **existing Istio Ukrainian terminology guide and glossary usage** unless it conflicts with the “keep in English” list above.
