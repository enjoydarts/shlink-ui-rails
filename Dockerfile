# Dockerfile
FROM ruby:3.4.5-bullseye

# 必要パッケージ: mysql2ビルド用に MariaDB Connector(C) を使う
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl \
    libmariadb-dev-compat libmariadb-dev \
    libyaml-dev libreadline-dev zlib1g-dev pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN gem install bundler foreman

EXPOSE 3000
CMD ["bash","-lc","[ -x bin/dev ] && bin/dev || bundle exec rails s -b 0.0.0.0 -p 3000"]

