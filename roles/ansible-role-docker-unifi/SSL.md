
Adding SSL Cert to container

# On IPA host:
ipa host-add unifi.core.home.gatwards.org
ipa service-add HTTP/unifi.core.home.gatwards.org
ipa service-add-host --hosts ipa1.ipa.home.gatwards.org HTTP/unifi.core.home.gatwards.org
ipa-getcert request -g 2048 \
  -k /etc/pki/tls/private/unifi.core.home.gatwards.org.key \
  -f /etc/pki/tls/certs/unifi.core.home.gatwards.org.pem \
  -N CN='unifi.core.home.gatwards.org' \
  -D unifi.core.home.gatwards.org \
  -K HTTP/unifi.core.home.gatwards.org

openssl pkcs12 -export \
  -in /etc/pki/tls/certs/unifi.core.home.gatwards.org.pem \
  -inkey /etc/pki/tls/private/unifi.core.home.gatwards.org.key \
  -out unifi.p12 \
  -name unifi \
  -password pass:aircontrolenterprise

# Copy resulting unifi.p12 to docker host unifi volume (/volume2/docker/unifi/data)

# On docker host (NAS):
/volume1/@appstore/Java8/j2sdk-image/bin/keytool -importkeystore \
  -deststorepass aircontrolenterprise \
  -destkeypass aircontrolenterprise \
  -destkeystore keystore \
  -srckeystore unifi.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass aircontrolenterprise \
  -alias unifi \
  -noprompt

docker restart unifi
