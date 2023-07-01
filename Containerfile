FROM registry.fedoraproject.org/fedora:latest AS builder

ENV UBLUE_ROOT=/app/output

WORKDIR /app 

ADD . /app

RUN dnf install \
    --disablerepo='*' \
    --enablerepo='fedora,updates' \
    --setopt install_weak_deps=0 \
    --nodocs \
    --assumeyes \
    'dnf-command(builddep)' \
    rpmlint \
    rpm-build  && \
    dnf builddep -y ublue-update.spec

RUN make

# Dump a file list for each RPM for easier consumption
RUN \
    for RPM in ${UBLUE_ROOT}/rpmbuild/RPMS/*/*.rpm; do \
        NAME="$(rpm -q $RPM --queryformat='%{NAME}')"; \
        mkdir -p "${UBLUE_ROOT}/ublue-os/files/${NAME}"; \
        rpm2cpio "${RPM}" | cpio -idmv --directory "${UBLUE_ROOT}/ublue-os/files/${NAME}"; \
        mkdir -p ${UBLUE_ROOT}/ublue-os/rpms/; \
        cp "${RPM}" "${UBLUE_ROOT}/ublue-os/rpms/$(rpm -q "${RPM}" --queryformat='%{NAME}.%{ARCH}.rpm')"; \
    done

FROM scratch

ENV UBLUE_ROOT=/app/output

# Copy RPMs
COPY --from=builder ${UBLUE_ROOT}/ublue-os/rpms /rpms
# Copy dumped contents
COPY --from=builder ${UBLUE_ROOT}/ublue-os/files /files
