FROM ruby:3.3-slim-bookworm

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends build-essential git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /site

ENV BUNDLE_PATH=/bundle

RUN gem install bundler

EXPOSE 4000

CMD ["sh", "-c", "bundle check || bundle install && bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload"]
