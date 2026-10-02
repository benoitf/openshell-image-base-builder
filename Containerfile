#
# Copyright (C) 2026 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

FROM registry.access.redhat.com/ubi10@sha256:454c3b22fd9dc97859df5a6bce662da1af5e3cf18313ef034190de3759392add AS builder
# curl to install claude and also run commands inside the sandbox
# tar is required by OpenShell
ARG PACKAGES="curl tar"

# create the root filesystem directory
RUN mkdir -p /mnt/rootfs
# Import the GPG key from the builder image so that redhat-release and later packages are verified
RUN \
    rpm --root=/mnt/rootfs --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release && \
    dnf install --installroot /mnt/rootfs \
        redhat-release \
        --releasever 10 --setopt install_weak_deps=false --nodocs -y

# install packages we want inside the image
RUN \
    dnf install --installroot /mnt/rootfs --setopt=reposdir=/etc/yum.repos.d/ \
        coreutils-single \
        glibc-minimal-langpack \
        ${PACKAGES} \
        --releasever 10 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all

# Add a kaiden user else we only have a root user and OpenShell denies root user
RUN chroot /mnt/rootfs /bin/bash -c "useradd -m -s /bin/bash kaiden"

RUN rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*
