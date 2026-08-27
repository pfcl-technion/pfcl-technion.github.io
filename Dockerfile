FROM ruby:3.3-bookworm

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
      build-essential \
      git \
      curl \
      nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local path "vendor/bundle" && \
    bundle install

EXPOSE 4000 35729

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload"]
