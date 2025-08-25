get-nodes() {
  CLUSTER=$1      # cluster name
  echo "----------------------- $CLUSTER -----------------------"

  validate_args() {
    # Validate $CLUSTER existes
    curl --max-time 10 -s http://ops.dor.eosn.io:8081/config/k8s_cluster | grep $CLUSTER > /dev/null || { echo "Error curling k8s_cluster configs."; exit 1; }
  }

  get_nodes() {
    echo "controller nodes: "
    curl --max-time 10 -s http://ops.dor.eosn.io:8081/config/host | jq --arg CLUSTER $CLUSTER '.[] | select((.details.k8s_cluster == $CLUSTER) and (.details.template == "k0s-controller")) | {name: .name, ipv4_address: .details.ipv4_address}' | jq -s '.' | jq -c '.[]'
    echo "worker nodes: "
    curl --max-time 10 -s http://ops.dor.eosn.io:8081/config/host | jq --arg CLUSTER $CLUSTER '.[] | select((.details.k8s_cluster == $CLUSTER) and ((.details.template == "dom-k0s-worker") or (.details.template == "k0s-worker"))) | {name: .name, ipv4_address: .details.ipv4_address}' | jq -s '.' | jq -c '.[]'
  }


  ################## Main script ####################
  validate_args
  get_nodes

}
