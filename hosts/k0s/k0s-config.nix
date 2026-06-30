{
  api = {
    address = "192.168.0.12";
    sans = [ "192.168.0.12" ];
  };

  storage = {
    type = "etcd";
    etcd.peerAddress = "192.168.0.12";
  };

  network = {
    provider = "custom";
    kubeProxy.disabled = true;
  };

  telemetry.enabled = false;

  extensions.helm = {
    concurrencyLevel = 2;
    repositories = [
      {
        name = "prom-crds";
        url = "https://prometheus-community.github.io/helm-charts";
      }
      {
        name = "cilium";
        url = "https://helm.cilium.io";
      }
    ];
    charts = [
      {
        name = "prom-crds";
        chartname = "prom-crds/prometheus-operator-crds";
        version = "29.0.0";
        order = 1;
        values = ''
          crds:
            alertmanagerconfigs:
              enabled: false
            alertmanagers:
              enabled: false
            prometheuses:
              enabled: false
            thanosrulers:
              enabled: false
        '';
        namespace = "kube-system";
      }
      {
        name = "cilium";
        chartname = "cilium/cilium";
        version = "1.20.0-pre.3";
        order = 2;
        values = ''
          ipam:
            mode: "kubernetes"
          ipv6:
            enabled: false
          envoy:
            enabled: true
            rollOutPods: true
            prometheus:
              enabled: true
              serviceMonitor:
                enabled: true
          hubble:
            enabled: true
            listenAddress: ":4244"
            metrics:
              enabled:
                - dns
                - drop
                - tcp
                - flow
                - port-distribution
                - icmp
                - http
              serviceMonitor:
                enabled: true
            relay:
              enabled: true
              rollOutPods: true
              prometheus:
                enabled: true
                serviceMonitor:
                  enabled: true
            ui:
              enabled: true
              rollOutPods: true
          operator:
            replicas: 1
            rollOutPods: true
            prometheus:
              enabled: true
              metricsService: true
              serviceMonitor:
                enabled: true

          rollOutCiliumPods: true
          prometheus:
            enabled: true
            serviceMonitor:
              enabled: true

          l7Proxy: true
          gatewayAPI:
            enabled: true
            gatewayClass:
              create: auto
            externalTrafficPolicy: Cluster

          # kube-proxy replacement is required when using l2announcements
          kubeProxyReplacement: true
          l2announcements:
            enabled: true
            leaseDuration: 60s
            leaseRenewDeadline: 30s
          k8sServiceHost: 192.168.0.12
          k8sServicePort: 6443
          k8sClientRateLimit:
            qps: 5
            burst: 10

          # Enable native bandwidth management + BBR TCP algorith
          bandwidthManager:
            enabled: true
        '';
        namespace = "kube-system";
      }
    ];
  };
}
