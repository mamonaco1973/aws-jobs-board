# ==============================================================================
# JobBoard Rails Application — Docker Image
# ==============================================================================
# Single-stage build; bundle install runs at build time and the gem cache is
# baked into the layer so runtime startup is fast.
# ==============================================================================

FROM ruby:3.3-slim

# System dependencies for pg gem and image processing
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      curl \
      git \
      libvips \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems before copying app code — improves Docker layer caching
COPY Gemfile ./
RUN bundle install --jobs 4 --retry 3

# Copy application source
COPY . .

# Create directories Rails expects at runtime
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log

# Precompile Sprockets assets with a dummy key (real key injected at runtime)
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile 2>/dev/null || true

EXPOSE 3000

# startup.sh runs migrations then starts Puma + Sidekiq
RUN chmod +x startup.sh
ENTRYPOINT ["./startup.sh"]
