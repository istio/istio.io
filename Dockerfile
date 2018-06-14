FROM alpine:latest

RUN apk add --no-cache \
    nodejs \
    ruby \
    ruby-dev \
    hugo \
    build-base \
    gcc \
    libc-dev \
    zlib-dev \
    libxslt-dev \
    libxml2-dev \
    git && \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted gnu-libiconv

RUN npm install -g \
    html-minifier \
    sass \
    uglify-js \
    markdown-spellcheck

RUN gem install --no-ri --no-rdoc \
    mdl \
    html-proofer

ENV PATH /usr/bin:$PATH

# TODO: replace with your ENTRYPOINT or CMD.
CMD [ "/usr/bin/ruby", "-v"]
