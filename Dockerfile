FROM node:16-alpine3.16 AS builder

ARG GITHUB_TOKEN
WORKDIR /tmp

RUN wget --header="Authorization: token ${GITHUB_TOKEN}"     -O ds.zip https://api.github.com/repos/gwos/next-grafana-datasource/zipball/8.7.5 \
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
COPY ./check-groundwork-plugin.sh "$GF_PATHS_HOME"/.
COPY --from=builder /tmp/dist /var/lib/grafana/plugins/groundwork-datasource
WORKDIR /var/lib/grafana/plugins
RUN tar -czvf groundwork-datasource.tgz groundwork-datasource \
	&& chmod 777 "$GF_PATHS_HOME/check-groundwork-plugin.sh"

RUN apt update -qy \
    && apt install -qy wget \
    && wget --no-verbose -O /tmp/google-chrome-stable_amd64.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_116.0.5845.110-1_amd64.deb \
    && apt install -y /tmp/google-chrome-stable_amd64.deb \
    && apt install -qy fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* /tmp/google-chrome-stable_amd64.deb

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init \
    &&   grafana cli plugins install grafana-image-renderer v3.7.2
  
RUN line=`grep -n "exec" /run.sh | awk -F  ":" '{print $1}'` \
	&& sed -i "$line"'i exec /usr/share/grafana/check-groundwork-plugin.sh &' /run.sh 
      

WORKDIR $GF_PATHS_HOME

EXPOSE 3000

USER grafana

CMD [ "$GF_PATHS_HOME/docker_cmd.sh", "/run.sh" ]
