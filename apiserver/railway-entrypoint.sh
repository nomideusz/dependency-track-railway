#!/bin/sh
# Railway entrypoint: own the volume, set the admin password on first boot,
# then serve the API on Railway's private network (IPv6).
set -eu
chown -R 1000:0 /data

# Upstream's launch command, as the dtrack user.
dtrack() {
  exec su-exec 1000:0 java $JAVA_OPTIONS $EXTRA_JAVA_OPTIONS \
    --add-opens java.base/java.util.concurrent=ALL-UNNAMED \
    --enable-native-access=ALL-UNNAMED \
    --sun-misc-unsafe-memory-access=allow \
    -Djdk.http.auth.tunneling.disabledSchemes= \
    -cp 'dependency-track-apiserver.jar:lib/*' \
    org.dependencytrack.Application -context "$CONTEXT" "$@"
}

# Dependency-Track seeds admin/admin and has the first login choose a new
# password, so whoever opened a fresh deploy first would own it. Change it to
# DTRACK_ADMIN_PASSWORD while the API only listens on localhost.
marker=/data/.railway-admin-password-set
if [ ! -f "$marker" ]; then
  echo "First boot: setting the admin password before opening the API"
  (dtrack -host 127.0.0.1) &
  pid=$!
  until curl -sf -o /dev/null http://127.0.0.1:8080/api/version; do
    kill -0 "$pid" 2>/dev/null || { echo "Dependency-Track exited during first boot" >&2; exit 1; }
    sleep 2
  done
  status=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/v1/user/forceChangePassword \
    --data-urlencode username=admin --data-urlencode password=admin \
    --data-urlencode "newPassword=$DTRACK_ADMIN_PASSWORD" \
    --data-urlencode "confirmPassword=$DTRACK_ADMIN_PASSWORD")
  case "$status" in
    200) echo "Admin password set from DTRACK_ADMIN_PASSWORD"
      # Upstream only mirrors NVD, which matches components by CPE; most SBOMs
      # carry package URLs instead. Turn on OSV so uploads show findings, and
      # queue its first mirror (a durable run, it resumes after the restart).
      token=$(curl -sf http://127.0.0.1:8080/api/v1/user/login \
        --data-urlencode username=admin --data-urlencode "password=$DTRACK_ADMIN_PASSWORD") &&
      curl -sf -o /dev/null -X PUT http://127.0.0.1:8080/api/v2/extension-points/vuln-data-source/extensions/osv/config \
        -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
        -d '{"config":{"enabled":true,"dataUrl":"https://storage.googleapis.com/osv-vulnerabilities","ecosystems":["Maven","Go","npm","PyPI","NuGet"],"aliasSyncEnabled":false,"incrementalMirroringEnabled":true}}' &&
      curl -sf -o /dev/null -X POST http://127.0.0.1:8080/api/v2/vuln-data-sources/osv/mirror-runs \
        -H "Authorization: Bearer $token" &&
      echo "OSV vulnerability source enabled" ||
      echo "Enabling OSV failed, turn it on under Administration > Vulnerability Sources" >&2 ;;
    401) echo "admin/admin no longer valid, leaving users as they are" ;;
    *) echo "Setting the admin password failed (HTTP $status)" >&2; kill "$pid"; exit 1 ;;
  esac
  kill "$pid"; wait "$pid" || true
  touch "$marker"
fi

dtrack -host ::
