FROM ruby:2.6.2-alpine

RUN echo 'gem: --no-document' >> /etc/gemrc

RUN apk add --no-cache \
    nodejs-current-npm \
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
    bash \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

ENV HUGO_VERSION=0.54.0
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
    sass-lint \
    typescript \
    tslint \
    markdown-spellcheck \
    svgstore-cli \
    svgo \
    @babel/cli \
    @babel/core
RUN npm install babel-preset-minify --save-dev

RUN gem install mdl
RUN gem install html-proofer -v 3.9.2

ENV PATH /usr/bin:$PATH

CMD [ "/usr/bin/ruby", "-v"]
