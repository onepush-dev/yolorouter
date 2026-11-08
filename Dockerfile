# Yolorouter on Railway: the official image (yolorouter/yolorouter v0.2.9,
# Apache-2.0), unmodified, plus a small first-boot script that
#   - generates configs/config.yaml (incl. the provider master key) on the
#     /yolorouter volume, exactly like upstream's first run;
#   - creates the first admin account over loopback on a private bootstrap
#     port BEFORE the public port opens, so nobody can claim the setup screen;
#   - keeps server.port = $PORT and server.external_url = the Railway domain
#     (upstream: set external_url on any internet-exposed deployment).
FROM ghcr.io/yolorouter/yolorouter:v0.2.9@sha256:01b1fc738a3cd198e9584f9eec607eb675ac47ed8374f2a4cec155bba54945ac
COPY railway/start.sh /usr/local/bin/yolorouter-railway-start
ENV PORT=8080 \
    YOLOROUTER_ADMIN_USERNAME=admin \
    YOLOROUTER_BOOTSTRAP_PORT=18080
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD wget -q --spider "http://127.0.0.1:${PORT:-8080}/healthz" || exit 1
ENTRYPOINT ["/bin/sh", "/usr/local/bin/yolorouter-railway-start"]
