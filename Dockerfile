ARG BASE_IMAGE=postgres:18
ARG PGBIGM_VERSION=1.2-20250903

FROM ${BASE_IMAGE} AS builder
ARG PGBIGM_VERSION
ENV PGBIGM_TAG=v${PGBIGM_VERSION}
ENV INSTALL_DIR=/tmp/install

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-server-dev-18 \
        make \
        gcc \
        wget \
        ca-certificates \
        libicu-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget -O pg_bigm.tar.gz \
        https://github.com/pgbigm/pg_bigm/archive/refs/tags/${PGBIGM_TAG}.tar.gz \
    && tar -xzf pg_bigm.tar.gz \
    && cd pg_bigm-${PGBIGM_VERSION} \
    && make USE_PGXS=1 \
    && make USE_PGXS=1 DESTDIR=${INSTALL_DIR} install

FROM ${BASE_IMAGE}
COPY --from=builder /tmp/install/usr/lib/postgresql/ /usr/lib/postgresql/
COPY --from=builder /tmp/install/usr/share/postgresql/ /usr/share/postgresql/

RUN echo "shared_preload_libraries = 'pg_bigm'" >> /usr/share/postgresql/postgresql.conf.sample
