FROM docker.io/library/postgres:17

# Install the pgtap postgres extension.
RUN apt update \
    && apt install -y --no-install-recommends postgresql-17-pgtap make \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK CMD pg_isready --dbname=postgres