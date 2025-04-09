FROM node:18-alpine3.21 AS builder

ARG GITHUB_TOKEN
WORKDIR /tmp

RUN wget --header="Authorization: token ${GITHUB_TOKEN}"     -O ds.zip https://api.github.com/repos/gwos/next-grafana-datasource/zipball/GROUNDWORK-4412 \
 && unzip ds.zip \
 && mv gwos-next-grafana* gwos-next-grafana \
 && cd gwos-next-grafana \
 && yarn \
 && yarn build \
 && mv dist /tmp/.

FROM grafana/grafana:10.4.17-ubuntu

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

RUN mkdir -p  "$GF_PATHS_HOME/.aws" \
              "$GF_PATHS_LOGS" \
              "$GF_PATHS_PLUGINS" \
              "$GF_PATHS_PROVISIONING/alerting" \
              "$GF_PATHS_PROVISIONING/dashboards" \
              "$GF_PATHS_PROVISIONING/datasources" \
              "$GF_PATHS_PROVISIONING/notifiers" \
              "${GF_PATHS_PROVISIONING}/plugins" \
              "$GF_PATHS_DATA" && \
    chmod 777 "$GF_PATHS_HOME/.aws" \
              "$GF_PATHS_LOGS" \
              "$GF_PATHS_PLUGINS" \
              "$GF_PATHS_PROVISIONING/alerting" \
              "$GF_PATHS_PROVISIONING/dashboards" \
              "$GF_PATHS_PROVISIONING/datasources" \
              "$GF_PATHS_PROVISIONING/notifiers" \
              "${GF_PATHS_PROVISIONING}/plugins" \
              "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    rm -rf /var/lib/grafana/dashboards

# Note volumes mounts. So, process groundwork-datasource.yml by check-groundwork-plugin.sh
# volumes:
#   - grafana-etc:/etc/grafana
#   - grafana-provisioning:/etc/grafana/provisioning
#   - grafana-dashboards:/var/lib/grafana/dashboards

COPY ./check-groundwork-plugin.sh /check-groundwork-plugin.sh
COPY ./groundwork-datasource.yml /.groundwork-datasource.yml
COPY ./groundwork-datasource.yml "$GF_PATHS_PROVISIONING"/datasources/.
COPY --from=builder /tmp/dist /var/lib/grafana/plugins/groundwork-datasource
WORKDIR /var/lib/grafana/plugins
RUN tar -czvf groundwork-datasource.tgz groundwork-datasource \
    && chmod 664 /.groundwork-datasource.yml "$GF_PATHS_PROVISIONING/datasources/groundwork-datasource.yml" \
	&& chmod 775 /check-groundwork-plugin.sh \
    && sed -i '/export HOME/a \\nsource /check-groundwork-plugin.sh' /run.sh


RUN apt update -qy \
    && apt install -qy wget vim \
    && wget --no-verbose -O /tmp/google-chrome-stable_amd64.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt install -y /tmp/google-chrome-stable_amd64.deb \
    && apt install -qy fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* /tmp/google-chrome-stable_amd64.deb

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init \
    && grafana cli plugins install grafana-image-renderer v3.11.5

WORKDIR $GF_PATHS_HOME

EXPOSE 3000

USER grafana

ENTRYPOINT ["dumb-init"]

CMD ["/run.sh"]
