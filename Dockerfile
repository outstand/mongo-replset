FROM outstand/tini as tini
FROM mongo:4.4.18

COPY --from=tini /sbin/tini /sbin/

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
