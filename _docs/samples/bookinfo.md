---
title: Sample application - BookInfo
overview: This sample application consists of four separate microservices that will be deployed in different configurations in the subsequent samples.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

This sample application consists of four separate microservices that will be deployed in different configurations in the subsequent samples.

## Overview

The Bookinfo application displays information about a
book, similar to a single catalog entry of an online book store. Displayed
on the page is a description of the book, book details (ISBN, number of
pages, and so on), and a few book reviews.

The BookInfo application is broken into four separate microservices:

* *productpage*. The productpage microservice calls the *details* and *reviews* microservices to populate the page.
* *details*. The details microservice contains book information.
* *reviews*. The reviews microservice contains book reviews. It also calls the *ratings* microservice.
* *ratings*. The ratings microservice contains book ranking information that accompanies a book review.

There are 3 versions of the reviews microservice:

* Version v1 doesn't call the ratings service.
* Version v2 calls the ratings service, and displays each rating as 1 to 5 black stars.
* Version v3 calls the ratings service, and displays each rating as 1 to 5 red stars.

The end-to-end architecture of the application is shown below.

<figure><img src="./img/bookinfo/noistio.svg" alt="BookInfo Application without Istio" title="BookInfo Application without Istio" />
<figcaption>BookInfo Application without Istio</figcaption></figure>

This application is polyglot, i.e., the microservices are written in different languages.

After installing Istio sidecars in the application in each pod (in
kubernetes environment) or the container (in simple docker compose
environment), all of the microservices are now packaged with an Envoy
sidecar that manages incoming and outgoing calls for the service. The
updated diagram looks like this:

<figure><img src="./img/bookinfo/withistio.svg" alt="BookInfo Application" title="BookInfo Application" />
<figcaption>BookInfo Application with Istio</figcaption></figure>
