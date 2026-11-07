FROM dependencytrack/apiserver:5.2.1

# Root for the entrypoint to take ownership of the Railway volume (mounted
# root-owned); Dependency-Track itself still runs as its own user.
USER root
# 5.2 dropped curl from the image; the entrypoint uses it on first boot.
RUN apk add --no-cache su-exec curl
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "railway-entrypoint.sh"]
CMD []
