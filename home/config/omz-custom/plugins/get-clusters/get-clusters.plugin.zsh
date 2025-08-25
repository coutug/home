get-clusters() {
    curl --max-time 10 -s http://ops.dor.eosn.io:8081/config/k8s_cluster | jq -r '.[].name'
}
