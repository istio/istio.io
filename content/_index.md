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
      "description": "Istio is an open platform to streamline service development and operation through sophisticated traffic management, end-to-end security, and automated telemetry collection."
    }
</script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.getElementById('card1').style.opacity = 1;

        window.setTimeout(function() {
            document.getElementById('card2').style.opacity = 1;
        }, 375);

        window.setTimeout(function() {
            document.getElementById('card3').style.opacity = 1;
        }, 750);

        window.setTimeout(function() {
            document.getElementById('card4').style.opacity = 1;
        }, 1125);

        window.setTimeout(function() {
            document.getElementById('buttons').style.opacity = 1;
        }, 1500);
    });
</script>

<main class="landing">
    <div class="container-fluid">
        <div class="row justify-content-center">
            {{< inline_image "landing/istio-logo.svg" >}}
            <div style="width: 20rem; margin-left: 3rem">
                <h1 class="hero-label">Istio</h1>
                <h1 class="hero-lead">An open platform to streamline service development and operation through sophisticated traffic management, end-to-end security, and automated telemetry collection.</h1>
            </div>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row justify-content-center">
            <div id="card1" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/routing-and-load-balancing.svg" >}}
                 </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Intelligent Routing and Load Balancing</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Control traffic between services with dynamic route configuration,
                        conduct A/B tests, release canaries, and gradually upgrade versions using red/black deployments.
                    </p>
                </div>
            </div>

            <div id="card2" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/resiliency.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Resilience Across Languages and Platforms</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Increase reliability by shielding applications from flaky networks and cascading failures in adverse conditions.
                    </p>
                </div>
            </div>

            <div id="card3" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/policy-enforcement.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Fleet-Wide Policy Enforcement</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Apply organizational policies to the interaction between services, ensure access policies are enforced and resources are fairly distributed
                        among consumers.
                    </p>
                </div>
            </div>

            <div id="card4" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">In-Depth Telemetry</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Understand the dependencies between services, the nature and flow of traffic between them, and quickly identify issues with distributed tracing.
                    </p>
                </div>
            </div>
        </div>
    </div>

    <div id="buttons" class="buttons container-fluid">
        <div class="row justify-content-center">
            <a class="btn btn-istio" href="/docs/concepts/what-is-istio/">LEARN MORE</a>
            <a class="btn btn-istio" href="https://github.com/istio/istio/releases/">DOWNLOAD</a>
        </div>
    </div>
</main>
