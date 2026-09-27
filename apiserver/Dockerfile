FROM dependencytrack/apiserver:5.1.1

# Root for the entrypoint to take ownership of the Railway volume (mounted
# root-owned); Dependency-Track itself still runs as its own user.
USER root
RUN apk add --no-cache su-exec
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "railway-entrypoint.sh"]
CMD []
