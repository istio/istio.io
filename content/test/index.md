---
title: Test
description: This page is to test the web site infrastructure, no useful content here.
skip_sitemap: true
---

This page exercises various site features as a quick smoke test to make sure things generally work.

## Callouts

{{< warning >}}
This is a warning
{{< /warning >}}

{{< warning >}}
This is a warning

with two paragraphs
{{< /warning >}}

{{< tip >}}
This is a tip
{{< /tip >}}

{{< tip >}}
This is a tip

with two paragraphs
{{< /tip >}}

{{< idea >}}
This is an idea
{{< /idea >}}

{{< idea >}}
This is an idea

with two paragraphs
{{< /idea >}}

{{< quote >}}
This is a quote
{{< /quote >}}

{{< quote >}}
This is a quote

with two paragraphs
{{< /quote >}}

## Callouts in list

1. Warning

    {{< warning >}}
    This is a warning
    {{< /warning >}}

    {{< warning >}}
    This is a warning

    with two paragraphs
    {{< /warning >}}

1. Tip

    {{< tip >}}
    This is a tip
    {{< /tip >}}

    {{< tip >}}
    This is a tip

    with two paragraphs
    {{< /tip >}}

1. Idea

    {{< idea >}}
    This is an idea
    {{< /idea >}}

    {{< idea >}}
    This is an idea

    with two paragraphs
    {{< /idea >}}

1. Quote

    {{< quote >}}
    This is a quote
    {{< /quote >}}

    {{< quote >}}
    This is a quote

    with two paragraphs
    {{< /quote >}}

## Text blocks

{{< text bash >}}
$ this is a text block
$ echo Foo \
Bar
Foo Bar
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
A test block with redirection
{{< /text >}}

{{< warning >}}
This is a warning with an embedded text block

{{< text plain >}}
A nested text block
{{< /text >}}

{{< /warning >}}

1. A bullet

    {{< text plain >}}
    A text block nested in a bullet
    {{< /text >}}

1. Another bullet

    {{< warning >}}
    A nested warning
    {{< /warning >}}

    {{< text plain >}}
    Another nested text block
    {{< /text >}}

1. Yet another bullet

    Second paragraph

1. Still another bullet

    {{< warning >}}
    This is a warning in a bullet.

    {{< text plain >}}
    This is a text block in a warning in a bullet
    {{< /text >}}

    {{< /warning >}}

## Boilerplate

Plain boilerplate:

{{< boilerplate "test-0" >}}

Boilerplate with some markdown and a short code

{{< boilerplate "test-1" >}}

Boilerplate with only a `shortcode`:

{{< boilerplate "test-2" >}}

Boilerplate with only a `shortcode` with a nested text block:

{{< boilerplate "test-3" >}}

## Boilerplate in list

1. Plain boilerplate:

    {{< boilerplate "test-0" >}}

1. Boilerplate with some markdown and a short code:

    {{< boilerplate "test-1" >}}

1. Boilerplate with only a `shortcode`:

    {{< boilerplate "test-2" >}}

1. Boilerplate with only a `shortcode` with a nested text block:

    {{< boilerplate "test-3" >}}

## Tabs

{{< tabset cookie-name="test" >}}

{{< tab name="One" cookie-value="one" >}}
One paragraph
{{< /tab >}}

{{< tab name="Two" cookie-value="two" >}}
Three

separate

paragraphs
{{< /tab >}}

{{< tab name="Three" cookie-value="three" >}}
{{< warning >}}
Warning in a tab
{{< /warning >}}
{{< /tab >}}

{{< tab name="Four" cookie-value="four" >}}
Simple text

{{< warning >}}
Warning in a tab
{{< /warning >}}
{{< /tab >}}

{{< tab name="Five" cookie-value="five" >}}
Simple text

{{< text plain >}}
Text block in a tab
{{< /text >}}

{{< /tab >}}

{{< tab name="Six" cookie-value="six" >}}
Simple text with _markdown_ in a tab

{{< warning >}}
Warning with _markdown_ in a tab

{{< text plain >}}
Text block in a warning in a tab
{{< /text >}}

And more _markdown_
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

## Tabs with lists

{{< tabset cookie-name="test" >}}

{{< tab name="One" cookie-value="one" >}}
1. One paragraph in a list in a tab
{{< /tab >}}

{{< tab name="Two" cookie-value="two" >}}
1. Three

1. separate

1. bullets in a list in a tab

    This last bullet with two paragraphs
{{< /tab >}}

{{< tab name="Three" cookie-value="three" >}}
1. Simple text in a list in a tab

    {{< warning >}}
    Warning in a list in a tab
    {{< /warning >}}
{{< /tab >}}

{{< tab name="Four" cookie-value="four" >}}
1. Simple text with _markdown_ in a list in a tab

    {{< warning >}}
    Warning in a list in a tab
    {{< /warning >}}
{{< /tab >}}

{{< tab name="Five" cookie-value="five" >}}
1. Simple text in a list in a tab

    {{< text plain >}}
    Text block in a list in a tab
    {{< /text >}}

{{< /tab >}}

{{< tab name="Six" cookie-value="six" >}}
1. Simple text with _markdown_ in a list in a tab

    {{< warning >}}
    Warning with _markdown_ in a list in a tab
    {{< /warning >}}

{{< /tab >}}

{{< /tabset >}}
