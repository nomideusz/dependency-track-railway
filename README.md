# Deploy and Host Dependency-Track on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/dependency-track?utm_medium=integration&utm_source=button&utm_campaign=dependency-track)

[OWASP Dependency-Track](https://dependencytrack.org/) tracks what your software is made of. Your CI uploads an SBOM for each build, and Dependency-Track flags components with known vulnerabilities, risky licenses and policy violations across all your projects, and alerts you when a new CVE hits something you ship. This template runs Dependency-Track 5.1.1 with Postgres, sets the admin password on first boot and turns on OSV, so your first SBOM already shows its vulnerabilities.

## About Hosting Dependency-Track

There are three services: Dependency-Track (the web UI), API and Postgres.

- **One URL.** The UI service proxies `/api` to the API service over Railway's private network. The browser, the REST API and your CI all use the same domain, and the API itself has no public domain.
- **Admin ready on boot.** A fresh Dependency-Track has `admin`/`admin`, and whoever logs in first picks the new password. Here the first boot sets it to a generated password before the API opens to the network, so there is nothing to claim.
- **Findings from the first upload.** Upstream only mirrors the NVD, which matches components by CPE, and most SBOMs identify packages by package URL instead. This template also turns on OSV (Maven, npm, PyPI, Go and NuGet), which matches by package URL and includes the GitHub advisories.
- **Version 5.** This is the new PostgreSQL-only architecture: no Kafka, and no separate workers to run. Database migrations run on every boot, so upgrades apply themselves.

## Common Use Cases

- Know within a day which of your services ship a newly published CVE, such as the next Log4Shell
- Keep an SBOM inventory for customers, audits or the EU Cyber Resilience Act
- Enforce license and security policies across every project, with alerts to Slack, Teams, email or webhooks

## Dependencies for Dependency-Track Hosting

- Postgres 17 (included, private network only)

### Deployment Dependencies

- [Official documentation](https://docs.dependencytrack.org/)
- [CycloneDX SBOM generators](https://cyclonedx.org/tool-center/) for your build tools
- [Template source on GitHub](https://github.com/nomideusz/dependency-track-railway)

### Implementation Details

**Sign in** at the Dependency-Track service's Railway domain. The username is `admin` and the password is `DTRACK_ADMIN_PASSWORD` from the Dependency-Track service's Variables tab. The first boot takes under a minute. Change the password afterwards under your profile, because the variable is only read on first boot.

**Vulnerability data.** On first boot Dependency-Track downloads the NVD and OSV databases, about 570,000 records. OSV takes two to four minutes and the NVD five to ten. Both refresh daily. SBOMs uploaded before the download finishes are analyzed again on the daily schedule; to see findings sooner, re-run the analysis from the project's Audit Vulnerabilities tab. Change the sources and OSV ecosystems under Administration → Vulnerability Sources.

**Uploads from CI.** Create an API key under Administration → Access Management → Teams → Automation. Then upload a CycloneDX SBOM from your pipeline:

```sh
curl -X POST https://<your-domain>/api/v1/bom \
  -H "X-Api-Key: $DTRACK_API_KEY" \
  -F autoCreate=true -F projectName=my-app -F projectVersion=1.0.0 \
  -F bom=@bom.json
```

`autoCreate` needs the Automation team to have the PROJECT_CREATION_UPLOAD permission. Otherwise create the project in the UI first. BOMs up to 100 MB are accepted.

**Notifications.** Railway only allows outbound SMTP on the Pro plan. On other plans, send alerts to Slack, Microsoft Teams, Mattermost or a webhook under Administration → Notifications.

**Memory and storage.** Around 600 MB for the API and a few MB for the UI. Postgres itself needs about 250 MB, but Linux keeps the database files it has written in memory, and Railway counts that cache as usage. After the first download that would be 3 GB, so this template caps Postgres at 1 GB (Postgres service → Settings → Resource Limits). The vulnerability data and Postgres's write-ahead log take about 3 GB of storage.

**Backups.** Projects, findings and settings are in Postgres. The API volume holds the key that encrypts the secrets you save in Dependency-Track, such as integration tokens. Turn on Railway's volume backups for both services.

**Custom domain.** Add it in the Dependency-Track service's Settings → Networking. The UI calls the API on whatever domain it is served from, so nothing else needs to change.

**Telemetry.** Dependency-Track sends anonymous usage statistics to its developers by default. Turn it off under Administration → Configuration → Telemetry.

## Why Deploy Dependency-Track on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Dependency-Track on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
