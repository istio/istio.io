FROM ruby:2.4-alpine

RUN echo 'gem: --no-document' >> /etc/gemrc

RUN apk add --no-cache \
    nodejs \
    ruby \
    ruby-dev \
    build-base \
    gcc \
    libc-dev \
    zlib-dev \
    libxslt-dev \
    libxml2-dev \
    libcurl \
    git \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted gnu-libiconv

ENV HUGO_VERSION=0.48
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp
RUN tar -xf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp \
    && mkdir -p /usr/local/sbin \
    && mv /tmp/hugo /usr/local/sbin/hugo \
    && rm -rf /tmp/hugo_${HUGO_VERSION}_linux_amd64 \
    && rm -rf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
    && rm -rf /tmp/LICENSE.md \
    && rm -rf /tmp/README.md

RUN npm install -g \
    sass \
    uglify-js \
    markdown-spellcheck

RUN gem install \
    mdl \
    html-proofer

ENV HELM_VERSION=2.10.0
ADD https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz /tmp
RUN tar -xf /tmp/helm-v${HELM_VERSION}-linux-amd64.tar.gz -C /tmp \
    && mkdir -p /usr/local/sbin \
    && mv /tmp/linux-amd64/helm /usr/local/sbin/helm \
    && rm -rf /tmp/linux-amd64

# TODO: replace with your ENTRYPOINT or CMD.
CMD [ "/usr/bin/ruby", "-v"]
