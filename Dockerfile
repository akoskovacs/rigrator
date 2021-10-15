FROM crystallang/crystal:1.0.0

# Install Dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libsqlite3-dev libmysqlclient-dev libreadline-dev git curl vim netcat

WORKDIR /opt/rigrator

# Build Amber
ENV PATH /opt/rigrator/bin:$PATH
COPY . /opt/rigrator
RUN shards build rigrator

CMD ["rigrator", "up"]
