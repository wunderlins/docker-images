# find image versions here:
# https://quay.io/repository/keycloak/keycloak?tab=tags&tag=latest
ARG IMAGE_VERSION=latest

# https://www.keycloak.org/server/containers
FROM quay.io/keycloak/keycloak:$IMAGE_VERSION as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# disable strict hostname checking for dev server
#ENV KC_HOSTNAME_STRICT=false

# Configure a database vendor
#ENV KC_DB=postgres

WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:$IMAGE_VERSION
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# change these values to point to a running postgres instance
#ENV KC_DB_URL=<DBURL>
#ENV KC_DB_USERNAME=<DBUSERNAME>
#ENV KC_DB_PASSWORD=<DBPASSWORD>
#ENV KC_HOSTNAME=localhost

# start script
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]