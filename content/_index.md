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
      "description": "Istio lets you connect, secure, control, and observe services."
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
                <h1 class="hero-lead">Connect, secure, control, and observe services.
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
                    <h5 class="card-title text-center">Connect</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Intelligently control the flow of traffic and API calls between services, conduct a range of tests, and upgrade gradually with
                        red/black deployments.
                    </p>
                </div>
            </div>

            <div id="card2" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/resiliency.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Secure</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Automatically secure your services through managed authentication, authorization, and encryption of communication between
                        services.
                    </p>
                </div>
            </div>

            <div id="card3" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/policy-enforcement.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Control</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        Apply policies and ensure that they’re enforced, and that resources are fairly distributed among consumers.
                    </p>
                </div>
            </div>

            <div id="card4" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">Observe</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        See what's happening with rich automatic tracing, monitoring, and logging of all your services.
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
