if grafana cli plugins ls | grep -q 'groundwork-grafana-datasource @ 0.0.2' ; then
    rm -f "$GF_PATHS_PROVISIONING/datasources/groundwork-datasource.yml"
fi
