FROM outstand/tini as tini
FROM mongo:4.2.10

COPY --from=tini /sbin/tini /sbin/

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
