# i18n conventions for Spanish (ES) translations

This document defines **translation conventions for the Spanish site content** (`content/es/**`).
It is intentionally written in **English** so both Spanish translators and non-Spanish reviewers can align.

If an existing ES page conflicts with these conventions, **do not “mass-fix” it**. Apply these rules to new/edited text and improve consistency opportunistically.

## Related documentation (must read)

- Terminology guide (docs contribution): `/es/docs/releases/contribute/terminology/` (**Guía de terminología**)

## Notes from scanning the existing Spanish corpus

The current ES corpus mixes some translations for historical reasons. **Do not mass-edit old pages** to enforce a new standard.
Instead, when you touch a page, try to make terminology consistent *within that page* and prefer the conventions below.

High-signal inconsistencies observed in `content/es/**`:

- **mesh vs malla**: both appear. For new text, prefer **“mesh”** (“la mesh”) and avoid “malla” unless you are matching an existing page’s established terminology.
- **namespace vs espacio de nombres**: “namespace” is dominant; “espacio de nombres” exists but is rare. Prefer **“namespace”** in technical contexts.
- **control plane / data plane vs plano de control / plano de datos**: both appear. Prefer **“control plane”** / **“data plane”** in new text.
- **gateway vs puerta(s) de enlace**: “gateway” is dominant; “puertas de enlace” appears. Prefer **“gateway”** in technical contexts.
- **trazado vs rastreo** (distributed tracing): both appear (e.g., tasks use “trazado”, some conceptual docs use “rastreo”).
  - For new content, prefer **“trazado”** for tracing (and “trazado distribuido” where appropriate), while keeping YAML keys like `tracing` unchanged.

## Core principle

Prefer **technical accuracy and consistency** over literal translation. Many Istio/Kubernetes concepts are proper nouns or widely-used terms in English; translating them often reduces clarity.

## Terminology: keep these in English (with Spanish articles)

Use Spanish articles/adjectives around the English term where needed.

- **mesh**: use **“la mesh”**, not “la malla”.
  - Plural: **“las meshes”**.
  - Examples:
    - ✅ “Agregar workloads a **la mesh**”
    - ❌ “Agregar workloads a **la malla**”
- **service mesh**: prefer **“service mesh”** (optionally “service mesh de Istio”).
  - Avoid translating to “malla de servicios” in new content.
- **control plane / data plane**: keep as **“control plane”** / **“data plane”**.
  - Use Spanish article: “el control plane”, “el data plane”.
- **workload**: keep **“workload”** when referring to the Kubernetes/Istio concept.
  - You may use “carga(s) de trabajo” only when it’s clearly generic prose, not the defined concept.
- **namespace**: keep **“namespace”** (not “espacio de nombres”) unless the sentence is purely explanatory.
- **sidecar**: keep **“sidecar”** (not “secundario”, “carro lateral”, etc.).
- **Ambient / ambient mode**: keep **“ambient”** as the feature name.
  - Prefer “**modo ambient**” for “ambient mode”.
- **waypoint**: keep **“waypoint”** (and “waypoint proxy” as-is).
- **ztunnel**: keep **“ztunnel”**.
- **Envoy**: keep **“Envoy”**.
- **Gateway API**: keep **“Gateway API”**.
- **gateway**: keep **“gateway”** (e.g., “Istio ingress gateway”, “Kubernetes Gateway”).
- **Kubernetes**: keep **“Kubernetes”**.
- **Istio resources / CRDs** (e.g., `VirtualService`, `DestinationRule`, `PeerAuthentication`): **never translate resource kind names**.

## Terminology: prefer Spanish translations

These are safe and expected in Spanish:

- **traffic** → “tráfico”
- **traffic management** → “gestión de tráfico”
- **security** → “seguridad”
- **observability** → “observabilidad”
- **authentication / authorization** → “autenticación / autorización”
- **policy** → “política”
- **upgrade** → “actualización”
- **installation / install** → “instalación / instalar”
- **cluster** → “clúster” (plural “clústeres”)
- **distributed tracing / tracing** → “trazado” (and “trazado distribuido” where helpful)
- **trace** → “traza” (e.g., “spans de traza”)

## Style guidelines (Spanish)

- **Voice**: prefer second-person informal already used across the site (“tú/tu”), unless the page clearly uses another voice.
- **Clarity**: short sentences; avoid overly literal calques from English.
- **Consistency**: once you pick a term within a page/section, keep using it (don’t alternate between synonyms).
- **Gender/number around English terms**:
  - “la mesh”, “el control plane”, “el data plane”, “un sidecar”, “los workloads”.
  - If it reads awkwardly, rephrase instead of translating the term.

## Formatting and markup rules

- **Do not translate code, CLI output, API fields, YAML keys, or filenames/paths.**
- **Inline code and code blocks**: keep exactly as in the source language.
- **Hugo shortcodes / gloss tags** (e.g., `{{< gloss >}}...{{< /gloss >}}`): do not change the shortcode structure.
- **Links**:
  - Keep URLs unchanged.
  - Translate the **link text** unless it is a product name, resource kind, command, or code.

## Quick “Do / Don’t” examples

- **mesh**
  - ✅ “Conecta tus servicios a **la mesh**”
  - ❌ “Conecta tus servicios a **la malla**”
- **resource kinds**
  - ✅ “Crea un `VirtualService`…”
  - ❌ “Crea un `ServicioVirtual`…”
- **mode names**
  - ✅ “En **modo ambient**…”
  - ❌ “En modo ambiental…”

## When in doubt

Add a short note in the PR describing the choice and rationale (accuracy/consistency). If a term is controversial, prefer matching **existing Istio Spanish glossary usage** unless it conflicts with the “keep in English” list above.


