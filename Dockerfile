ARG BASE_IMAGE_VERSION=22.04
ARG GHC_VERSION=9.10.2
ARG HLS_VERSION=2.11.0.0
ARG CABAL_VERSION=3.14.1.1
ARG FOURMOLU_VERSION=0.18.0.0
ARG HLINT_VERSION=3.10
ARG APPLY_REFACT_VERSION=0.15.0.0
ARG GHC_TAGS_VERSION=1.9
ARG POSTGRESQL_MIGRATION_VERSION=0.2.1.8

# This stage installs libraries required to install GHC and other tools
FROM ubuntu:$BASE_IMAGE_VERSION AS base
USER "root"
ENV LANG="en_GB.UTF-8"

RUN apt update && \
  apt install -y  \
    build-essential \
    curl \
    git \
    libffi-dev \
    libffi8 \
    libgmp-dev \
    libgmp10 \
    libncurses-dev \
    libncurses5 \
    libpq-dev \
    libtinfo5 \
    locales \
    pkg-config \
    postgresql-client \
    zlib1g-dev
RUN localedef -i en_GB -c -f UTF-8 -A /usr/share/locale/locale.alias en_GB.UTF-8
RUN rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# This stage installs ghcup, ghc and cabal
FROM base AS ghcup
ARG CABAL_VERSION

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE="YES"
ENV BOOTSTRAP_HASKELL_MINIMAL="YES"
ENV GHCUP_INSTALL_BASE_PREFIX="/out/ghcup"
ENV PATH="/out/ghcup/.ghcup/bin:$PATH"

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
RUN ghcup install cabal $CABAL_VERSION

# This stage installs haskell tools
FROM base as setup-haskell-tools
ARG POSTGRESQL_MIGRATION_VERSION
ARG FOURMOLU_VERSION
ARG HLINT_VERSION
ARG APPLY_REFACT_VERSION
ARG GHC_TAGS_VERSION
ARG GHC_VERSION

ENV PATH="/opt/ghcup/.ghcup/bin:$PATH"
ENV GHCUP_INSTALL_BASE_PREFIX="/opt/ghcup"

COPY --from=ghcup /out/ghcup /opt/ghcup

RUN ghcup install ghc $GHC_VERSION
RUN ghcup install ghc 9.6.7
RUN ghcup set ghc $GHC_VERSION

RUN cabal update

RUN cabal install --install-method=copy --installdir=out/ --semaphore -j postgresql-migration-$POSTGRESQL_MIGRATION_VERSION
RUN cabal install --install-method=copy --installdir=out/ --semaphore -j fourmolu-$FOURMOLU_VERSION
RUN cabal install --install-method=copy --installdir=out/ --semaphore -j hlint-$HLINT_VERSION
RUN ghcup run --ghc 9.6.7 -- cabal install --install-method=copy --installdir=out/ -j apply-refact-$APPLY_REFACT_VERSION
RUN cabal install --install-method=copy --installdir=out/ --semaphore -j ghc-tags-$GHC_TAGS_VERSION

# This stage is the development environment
FROM base AS devel
USER root

ARG GID
ARG UID
ARG USER
ENV USER=$USER

COPY --from=ghcup /out/ghcup /opt/ghcup
COPY --from=setup-haskell-tools /out /opt/bin

ENV PATH="/opt/ghcup/.ghcup/bin:$PATH"

RUN ghcup install ghc $GHC_VERSION
RUN ghcup set ghc $GHC_VERSION

RUN apt update
RUN apt install -y libpq-dev wget tmux postgresql-client direnv

RUN groupadd -g "$GID" -o "$USER" \
  && useradd -l -r -u "$UID" -g "$GID" -m -s /bin/bash "$USER"

RUN mkdir /home/$USER/.cabal
RUN chown -R $UID:$GID /home/$USER

USER $USER

RUN chown -R $UID:$GID /home/$USER
RUN mkdir -p /home/$USER/masna3 \
  && chown -R $UID:$GID /home/$USER/masna3

RUN echo 'export PATH="$PATH:/home/$USER/.cabal/bin"' >> ~/.bashrc
RUN echo "source /opt/ghcup/.ghcup/env" >> ~/.bashrc
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
RUN echo 'direnv allow' >> ~/.bashrc
