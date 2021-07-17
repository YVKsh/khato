FROM alpine:3.14.0

ARG VCS_REF
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG CURL_CA_BUNDLE
ARG GIT_SSL_CAINFO
ARG VCS_REF
ARG BUILD_DATE

ARG KUBE_LATEST_VERSION="v1.20.5"
ARG HELM_VERSION="v3.5.3"
ARG YQ_VERSION="v4.6.2"
ARG KUBEVAL_VERSION=0.15.0

ARG SOPS_VERSION=v3.6.1
ARG HELM_SECRETS_VERSION=v3.5.0
ARG HELM_DIFF_VERSION=v3.1.3

ARG ANSIBLE_VERSION=2.10.7
# setup systemd deps 

RUN set -x \
    && apk update \
    && apk upgrade \
    && apk --no-cache add \
           ca-certificates \
           bash \
           git \
           openssh \
           openssh-client \ 
           curl \
           gnupg \
           jq \
           libintl \
           coreutils \
           python3 \
           py3-pip \
           python3-dev \
           sshpass \
           rsync \ 
           libffi-dev \
           musl-dev \ 
           gcc \
           cargo \
           openssl \
           openssl-dev \
           libressl-dev \
           build-base \
           bind-tools \
           vim \
    && apk add --no-cache --virtual envsubst_tmp gettext \
    && install /usr/bin/envsubst /usr/local/bin/envsubst \
    && curl -fsSL -o /usr/local/bin/yq \
          "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64" \
    && chmod 0755 /usr/local/bin/yq \
    && curl -fsSL \ 
          "https://github.com/instrumenta/kubeval/releases/download/$KUBEVAL_VERSION/kubeval-linux-amd64.tar.gz" | \
           tar xzO kubeval >/usr/local/bin/kubeval \
    && chmod 0755 /usr/local/bin/kubeval \
    && apk del envsubst_tmp \
    && rm -rf /var/cache/apk/*

#get helm and kubectl

RUN set -x \
    && curl -fsSL \ 
          "https://storage.googleapis.com/kubernetes-release/release/$KUBE_LATEST_VERSION/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL \
          "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && chmod g+rwx /root \
    && mkdir /config \
    && chmod g+rwx /config \
    && helm repo add "stable" "https://charts.helm.sh/stable" --force-update

#get plugins

RUN set -x \
    && curl -fsSL -o /usr/local/bin/sops \
          "https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux" \
    && chmod 0755 /usr/local/bin/sops \
    && env SKIP_SOPS_INSTALL=true helm plugin install --version "${HELM_SECRETS_VERSION}" \
           https://github.com/jkroepke/helm-secrets \
    && helm plugin install --version "${HELM_DIFF_VERSION}" \
           https://github.com/databus23/helm-diff \
    && helm plugin install https://github.com/marckhouzam/helm-fullstatus

RUN set -x \
    && pip3 install --upgrade pip cffi wheel \
    && pip3 install ansible==$ANSIBLE_VERSION \
    && pip3 install mitogen ansible-lint jmespath \
    && pip3 install --upgrade pywinrm \
#    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && rm -rf /root/.cache/pip \
    && rm -rf /root/.cargo \
    && mkdir /ansible \
    && mkdir -p /etc/ansible \
    && echo 'localhost' > /etc/ansible/hosts

WORKDIR /config
