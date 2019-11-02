---
title: Tabs
description: Basic tabs.
skip_sitemap: true
---

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

In two paragraphs

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

{{< tab name="Seven" cookie-value="seven" >}}
Simple text with _markdown_ in a tab

{{< text plain >}}
NoIndent:
    FourIndent:
        - EightIndent
    FourIndentAgain:
        - EightIndentAgain
{{< /text >}}

And more _markdown_
{{< /tab >}}

{{< /tabset >}}
