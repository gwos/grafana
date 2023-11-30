# we want to removre below file after plugin installation, assuming that it wont go beyond 30 sec.
if test -f /etc/grafana/provisioning/datasources/groundwork-datasource.yaml ; then
   sleep 30
   rm -f /etc/grafana/provisioning/datasources/groundwork-datasource.yaml
fi
