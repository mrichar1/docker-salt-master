FROM ubuntu:xenial-20181005

LABEL maintainer="carlos.alvaro@citelan.es"
LABEL description="SaltStack master"
LABEL version="2018.3.3"

# https://github.com/saltstack/salt/releases
ENV SALT_VERSION="2018.3.3"

ENV SALT_DOCKER_DIR="/etc/docker-salt" \
    SALT_ROOT_DIR="/etc/salt" \
    SALT_USER="salt" \
    SALT_HOME="/home/salt"

ENV SALT_BUILD_DIR="${SALT_DOCKER_DIR}/build" \
    SALT_RUNTIME_DIR="${SALT_DOCKER_DIR}/runtime" \
    SALT_DATA_DIR="${SALT_HOME}/data"

ENV SALT_CONFS_DIR="${SALT_DATA_DIR}/config" \
    SALT_KEYS_DIR="${SALT_DATA_DIR}/keys" \
    SALT_BASE_DIR="${SALT_DATA_DIR}/srv"

# Set non interactive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p ${SALT_BUILD_DIR}
WORKDIR ${SALT_BUILD_DIR}

# Install packages
RUN apt-get update
RUN apt-get install --yes --quiet --no-install-recommends \
    ca-certificates wget apt-transport-https git locales \
    openssh-client python3 python-git

# Configure locales
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
    locale-gen en_US.UTF-8 \
    dpkg-reconfigure locales

# Install saltstack
COPY assets/build ${SALT_BUILD_DIR}
RUN bash ${SALT_BUILD_DIR}/install.sh

# Shared resources
EXPOSE 4505/tcp 4506/tcp
RUN mkdir -p ${SALT_DATA_DIR} ${SALT_BASE_DIR} ${SALT_KEYS_DIR} ${SALT_CONFS_DIR}
VOLUME [ "${SALT_BASE_DIR}" "${SALT_KEYS_DIR}" "${SALT_CONFS_DIR}" ]

COPY assets/runtime ${SALT_RUNTIME_DIR}
RUN chmod -R +x ${SALT_RUNTIME_DIR}

# Cleaning tasks
RUN apt-get clean --yes
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf ${SALT_BUILD_DIR}/*

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh
WORKDIR ${SALT_HOME}

ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "app:start" ]
