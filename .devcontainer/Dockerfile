# Install tools required by multiple build stages
FROM ubuntu:24.04 AS dev-tools
RUN apt update && apt install -y curl build-essential

# Use the same base image as the tagged image, so that we use the same version of perl when building sqitch.
# FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS sqitch-build
FROM dev-tools AS sqitch-build
WORKDIR /work
# Download the cpm perl module installer
# Download the sqitch release
# Extract the sqitch release

RUN curl -sL --compressed https://git.io/cpm > /usr/bin/cpm && chmod +x /usr/bin/cpm \
    && curl -sL https://github.com/sqitchers/sqitch/releases/download/v1.5.0/App-Sqitch-v1.5.0.tar.gz -o ./sqitch.tar.gz \
    && mkdir ./sqitch && tar xvzf ./sqitch.tar.gz --strip-components 1 -C ./sqitch
WORKDIR /work/sqitch
# Install the Build module
# Install the dependencies
# Specify where to install the sqitch app files and to include postgres
# Perform remaining build and isntall steps
RUN cpm install -L /app/lib/sqitch --verbose --no-test --show-build-log-on-failure Module::Build \
    && cpm install -L /app/lib/sqitch --verbose --no-test --show-build-log-on-failure --with-recommends --with-configure --cpanfile ./dist/cpanfile \
    && perl -I /app/lib/sqitch/lib/perl5 ./Build.PL --quiet --install_base /app --etcdir /etc/sqitch --with postgres \
    && ./Build installdeps && ./Build && ./Build install



# FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
FROM dev-tools
# Install dev tools
RUN apt install -y rsync git nano vim locales
# Generate the locale, which is used by perl.
RUN locale-gen en_US.UTF-8

# Install sqitch runtime dependencies for sqitch and clean up apt files
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man7 \
    && apt install -y --no-install-recommends perl-doc libpq5 postgresql-client libdbd-pg-perl \
    && apt clean && rm -rf /var/cache/apt/* /var/lib/apt/lists/* \
    # Let libcurl find certs. https://stackoverflow.com/q/3160909/79202
    && mkdir -p /etc/pki/tls && ln -s /etc/ssl/certs /etc/pki/tls/

# Copy the sqitch files
COPY --from=sqitch-build /etc/sqitch /etc/sqitch/
COPY --from=sqitch-build /app /tmp/sqitch-app

# Merge the sqitch files into the /usr directory
# Modify the 1st line of sqitch script to add the locations of its module dependencies to perl's @INC
# Remove temporary files
RUN rsync -av /tmp/sqitch-app/ /usr/ && \
    sed -i "1s|.*|& -I /usr/lib/sqitch/lib/perl5 -I /usr/lib/perl5|" /usr/bin/sqitch \
    && rm -rf /tmp/sqitch-app

ENV SQITCH_EDITOR=nano SQITCH_PAGER=less LESS=-R LC_ALL=en_US.UTF-8



RUN useradd dev -m -s /bin/bash

USER dev
# Execute the CMD and loop for infinity.
ENTRYPOINT [ "/bin/sh", "-c",  "echo Container started\ntrap \"exit 0\" 15\n\nexec \"$@\"\nwhile sleep 1 & wait $!; do :; done" ]
# Open a shell. Note: the CMD must be an array with a single element. Multiple elements are interpreted wrongly by the entrypoint.
# If CMD needs multiple options, then put all the options in a single string in a single array element.
CMD [ "/bin/bash" ]
LABEL com.tyrusaudio="dev container"
