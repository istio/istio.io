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
    bash \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted gnu-libiconv

ENV HUGO_VERSION=0.51
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp
RUN tar -xf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp \
    && mkdir -p /usr/local/sbin \
    && mv /tmp/hugo /usr/local/sbin/hugo \
    && rm -rf /tmp/hugo_${HUGO_VERSION}_linux_amd64 \
    && rm -rf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
    && rm -rf /tmp/LICENSE.md \
    && rm -rf /tmp/README.md

COPY package.json .
COPY package-lock.json .

RUN npm install

RUN gem install \
    mdl \
    html-proofer

ENV PATH /usr/bin:$PATH

# TODO: replace with your ENTRYPOINT or CMD.
CMD [ "/usr/bin/ruby", "-v"]
