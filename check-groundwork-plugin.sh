if grafana cli plugins ls | grep -q 'groundwork-grafana-datasource @ 0.0.2' ; then
    rm -f "$GF_PATHS_PROVISIONING/datasources/groundwork-datasource.yml"
else

    mkdir -p    "$GF_PATHS_HOME/.aws" \
                "$GF_PATHS_LOGS" \
                "$GF_PATHS_PLUGINS" \
                "$GF_PATHS_PROVISIONING/alerting" \
                "$GF_PATHS_PROVISIONING/dashboards" \
                "$GF_PATHS_PROVISIONING/datasources" \
                "$GF_PATHS_PROVISIONING/notifiers" \
                "$GF_PATHS_DATA"

    chmod 777   "$GF_PATHS_HOME/.aws" \
                "$GF_PATHS_LOGS" \
                "$GF_PATHS_PLUGINS" \
                "$GF_PATHS_PROVISIONING/alerting" \
                "$GF_PATHS_PROVISIONING/dashboards" \
                "$GF_PATHS_PROVISIONING/datasources" \
                "$GF_PATHS_PROVISIONING/notifiers" \
                "$GF_PATHS_DATA"

    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG"
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml
    rm -rf /var/lib/grafana/dashboards
    cp /.groundwork-datasource.yml "$GF_PATHS_PROVISIONING/datasources/groundwork-datasource.yml"

fi
