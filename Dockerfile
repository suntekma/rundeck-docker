# Dockerfile for rundeck
# https://github.com/jjethwa/rundeck

FROM debian:stretch

MAINTAINER Jude.X.Zhu@newegg.com

ENV SERVER_URL=https://localhost:4443 \
    RUNDECK_STORAGE_PROVIDER=file \
    RUNDECK_PROJECT_STORAGE_TYPE=file \
    NO_LOCAL_MYSQL=false \
    LOGIN_MODULE=RDpropertyfilelogin \
    JAAS_CONF_FILE=jaas-loginmodule.conf \
    KEYSTORE_PASS=adminadmin \
    TRUSTSTORE_PASS=adminadmin \
    CLUSTER_MODE=false

RUN export DEBIAN_FRONTEND=noninteractive && \
    echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qqy install -t stretch-backports --no-install-recommends bash openjdk-8-jre-headless ca-certificates-java supervisor procps sudo ca-certificates openssh-client mysql-server mysql-client postgresql-9.6 postgresql-client-9.6 pwgen curl git uuid-runtime parallel jq && \
    cd /tmp/ && \
    curl -Lo /tmp/rundeck.deb https://dl.bintray.com/rundeck/rundeck-deb/rundeck_3.0.11.20181221-1.201812212337_all.deb && \
    echo 'b627d6e5d3cdaaa6d0a6e67d995daf92739a1dc1472a8efdc1ce1b46398f5d0c  rundeck.deb' > /tmp/rundeck.sig && \
    shasum -a256 -c /tmp/rundeck.sig && \
    curl -Lo /tmp/rundeck-cli.deb https://github.com/rundeck/rundeck-cli/releases/download/v1.1.1/rundeck-cli_1.1.1-1_all.deb && \
    echo 'c861a8ad7e8629cb9b22674a6d24bfe8d796f0e8ae84f47faba07742fa942302  rundeck-cli.deb' > /tmp/rundeck-cli.sig && \
    shasum -a256 -c /tmp/rundeck-cli.sig && \
    cd - && \
    dpkg -i /tmp/rundeck*.deb && rm /tmp/rundeck*.deb && \
    chown rundeck:rundeck /tmp/rundeck && \
    mkdir -p /var/lib/rundeck/.ssh && \
    chown rundeck:rundeck /var/lib/rundeck/.ssh && \
    sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile && \
    curl -Lo /var/lib/rundeck/libext/rundeck-slack-incoming-webhook-plugin-0.6.jar https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v0.6.dev/rundeck-slack-incoming-webhook-plugin-0.6.jar && \
    curl -Lo /var/lib/rundeck/libext/rundeck-httppost-plugin-0.1-1.jar https://repo1.maven.org/maven2/be/fluid-it/tools/rundeck/plugins/rundeck-httppost-plugin/0.1-1/rundeck-httppost-plugin-0.1-1.jar && \
    curl -Lo /var/lib/rundeck/libext/http-step-1.0.12.jar https://github.com/rundeck-plugins/http-step/releases/download/1.0.12/http-step-1.0.12.jar && \
    curl -Lo /var/lib/rundeck/libext/rundeck-salt-plugin-0.4.jar https://github.com/rundeck-plugins/salt-step/releases/download/0.4/rundeck-salt-plugin-0.4.jar && \
    echo 'd23b31ec4791dff1a7051f1f012725f20a1e3e9f85f64a874115e46df77e00b5  rundeck-slack-incoming-webhook-plugin-0.6.jar' > /tmp/rundeck-slack-plugin.sig && \
    cd /var/lib/rundeck/libext/ && \
    shasum -a256 -c /tmp/rundeck-slack-plugin.sig && \
    cd - && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD content/ /
RUN chmod u+x /opt/run && \
    mkdir -p /var/log/supervisor && mkdir -p /opt/supervisor && \
    chmod u+x /opt/supervisor/rundeck && chmod u+x /opt/supervisor/mysql_supervisor && chmod u+x /opt/supervisor/fatalservicelistener

EXPOSE 4440 4443

VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/opt/run"]
