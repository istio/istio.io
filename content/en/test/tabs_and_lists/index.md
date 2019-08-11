---
title: Tabs and Lists
description: Composing tabs and lists.
skip_sitemap: true
---

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

    A paragraph

    {{< warning >}}
    Warning in a list in a tab
    {{< /warning >}}

    And another

1. Second bullet

1. Third bullet
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

1. Second bullet
{{< /tab >}}

{{< tab name="Seven" cookie-value="seven" >}}
1. Simple text with _markdown_ in a list in a tab

    {{< text_hack bash >}}
    $ NoIndent:
        FourIndent:
            - EightIndent
        FourIndentAgain:
            - EightIndentAgain
    {{< /text_hack >}}

1. Second bullet
{{< /tab >}}

{{< /tabset >}}
