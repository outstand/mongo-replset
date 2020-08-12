FROM mongo:4.2

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /sbin/tini.asc
RUN gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
  && gpg --batch --verify /sbin/tini.asc /sbin/tini \
  && rm -f /sbin/tini.asc \
  && chmod +x /sbin/tini

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
