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

## Call out in list

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

## Tragic

1. Call the service with two concurrent connections (`-c 2`) and send 20 requests
(`-n 20`):

    {{< text bash >}}
    $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
    Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
    Starting at max qps with 2 thread(s) [gomax 2] for exactly 20 calls (10 per thread + 0)
    23:51:10 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 106.474079ms : 20 calls. qps=187.84
    Aggregated Function Time : count 20 avg 0.010215375 +/- 0.003604 min 0.005172024 max 0.019434859 sum 0.204307492
    # range, mid point, percentile, count
    >= 0.00517202 <= 0.006 , 0.00558601 , 5.00, 1
    > 0.006 <= 0.007 , 0.0065 , 20.00, 3
    > 0.007 <= 0.008 , 0.0075 , 30.00, 2
    > 0.008 <= 0.009 , 0.0085 , 40.00, 2
    > 0.009 <= 0.01 , 0.0095 , 60.00, 4
    > 0.01 <= 0.011 , 0.0105 , 70.00, 2
    > 0.011 <= 0.012 , 0.0115 , 75.00, 1
    > 0.012 <= 0.014 , 0.013 , 90.00, 3
    > 0.016 <= 0.018 , 0.017 , 95.00, 1
    > 0.018 <= 0.0194349 , 0.0187174 , 100.00, 1
    # target 50% 0.0095
    # target 75% 0.012
    # target 99% 0.0191479
    # target 99.9% 0.0194062
    Code 200 : 19 (95.0 %)
    Code 503 : 1 (5.0 %)
    Response Header Sizes : count 20 avg 218.85 +/- 50.21 min 0 max 231 sum 4377
    Response Body/Total Sizes : count 20 avg 652.45 +/- 99.9 min 217 max 676 sum 13049
    All done 20 calls (plus 0 warmup) 10.215 ms avg, 187.8 qps
    {{< /text >}}

    It's interesting to see that almost all requests made it through! The `istio-proxy`
    does allow for some leeway.

    {{< text plain >}}
    Code 200 : 19 (95.0 %)
    Code 503 : 1 (5.0 %)
    {{< /text >}}

1. Bring the number of concurrent connections up to 3:
