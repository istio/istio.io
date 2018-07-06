---
title: Istio
---
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "Organization",
        "url": "https://istio.io",
        "logo": "https://istio.io/img/logo.png",
        "sameAs": [
            "https://twitter.com/IstioMesh",
            "https://istio.rocket.chat/"
        ]
    }
</script>
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "WebSite",
        "url": "https://istio.io/",
        "potentialAction": {
            "@type": "SearchAction",
            "target": "https://istio.io/search.html?q={search_term_string}",
            "query-input": "required name=search_term_string"
        }
    }
</script>
<script type="application/ld+json">
    {
      "@context": "http://schema.org/",
      "@type": "Product",
      "name": "Istio",
      "image": [
          "https://istio.io/img/logo.png"
       ],
      "description": "Istio is an open platform to connect, manage, and secure microservices."
    }
</script>

<main class="landing">
    <div class="hero">
        <div class="container">
            <h1 class="hero-label">Istio{{< site_suffix >}} {{< istio_version >}}</h1>
            <img class="hero-logo" alt="Istio Logo" src="/img/istio-logo.svg" />
            <h1 class="hero-lead">An open platform to connect, manage, and secure microservices</h1>
            <span onclick="getElementById('SCROLLME').scrollIntoView({block: 'start', inline: 'nearest', behavior: 'smooth'})" class="hero-down-arrow fa fa-2 fa-caret-down"></span>
            <span id="SCROLLME"></span>
        </div>
    </div>

    <div class="container-fluid traffic color1">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/routing-and-load-balancing.svg" >}}
            </div>
            <div class="col-12 col-md-5 landing-text">
                <h2>Intelligent Routing and Load Balancing</h2>
                <p>
                    Control traffic between services with dynamic route configuration,
                    conduct A/B tests, release canaries, and gradually upgrade versions using red/black deployments.
                    <a href="/docs/concepts/traffic-management/">Learn more...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid resilience color2">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/resiliency.svg" >}}
            </div>
            <div class="col-12 col-md-5 order-md-first landing-text">
                <h2>Resilience Across Languages and Platforms</h2>
                <p>
                    Increase reliability by shielding applications from flaky networks and cascading failures in adverse conditions.
                    <a href="/docs/concepts/traffic-management/#handling-failures">Learn more...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid policy color1">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/policy-enforcement.svg" >}}
            </div>
            <div class="col-12 col-md-5 landing-text">
                <h2>Fleet-Wide Policy Enforcement</h2>
                <p>
                    Apply organizational policies to the interaction between services, ensure access policies are enforced and resources are fairly distributed
                    among consumers.
                    <a href="/docs/concepts/policies-and-telemetry/">Learn more...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid reporting color2">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/telemetry-and-reporting.svg" >}}
            </div>
            <div class="col-12 col-md-5 order-md-first landing-text">
                <h2>In-Depth Telemetry</h2>
                <p>
                    Understand the dependencies between services, the nature and flow of traffic between them, and quickly identify issues with distributed tracing.
                    <a href="/docs/concepts/what-is-istio/">Learn more...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid call color1">
        <div class="row no-gutters">
            <div class="col-12 col-md-6">
                <h2>Want to learn more?</h2>
                <p>Get started by learning Istio concepts and running through our Bookinfo sample.</p>
                <a class="btn btn-istio" href="/docs/">GET STARTED</a>
            </div>

            <div class="col-12 col-md-6">
                <h2>Ready to get started?</h2>
                <p>Download the latest bits.</p>
                <a class="btn btn-istio" href="https://github.com/istio/istio/releases/">DOWNLOAD</a>
            </div>
        </div>
    </div>
</main>
