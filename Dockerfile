FROM node:16-alpine3.16 AS builder

ARG GITHUB_TOKEN
WORKDIR /tmp

RUN wget --header="Authorization: token ${GITHUB_TOKEN}"     -O ds.zip https://api.github.com/repos/gwos/next-grafana-datasource/zipball \
 && unzip ds.zip \
 && mv gwos-next-grafana* gwos-next-grafana \
 && cd gwos-next-grafana \
 && yarn \
 && yarn build \
 && mv dist /tmp/.

FROM grafana/grafana:9.4.7-ubuntu

ARG GF_UID="472"
ARG GF_GID="472"

ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

USER 0
    
RUN mkdir -p "$GF_PATHS_HOME/.aws" && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" &&\
    rm -rf /var/lib/grafana/dashboards

COPY docker_cmd.sh ./
COPY ./groundwork-datasource.yaml "$GF_PATHS_PROVISIONING"/datasources/.

COPY --from=builder /tmp/dist /var/lib/grafana/plugins/groundwork-datasource
WORKDIR /var/lib/grafana/plugins
RUN tar -czvf groundwork-datasource.tgz groundwork-datasource

WORKDIR $GF_PATHS_HOME

EXPOSE 3000

USER grafana

CMD [ "$GF_PATHS_HOME/docker_cmd.sh", "/run.sh" ]
