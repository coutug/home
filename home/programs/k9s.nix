{ pkgs, ... }:
{
  programs.k9s = {
    enable = true;

    aliases = {
      aliases = {
        dp  = "deployments";
        sec = "v1/secrets";
        jo  = "jobs";
        cr  = "clusterroles";
        crb = "clusterrolebindings";
        ro  = "roles";
        rb  = "rolebindings";
        np  = "networkpolicies";
      };
    };

    plugin = {
      debug = {
        shortCut = "Shift-D";
        description = "Add debug container";
        scopes = [ "containers" ];
        command = "bash";
        background = false;
        confirm = true;
        args = [
          "-c"
          "kubectl debug -it -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.11 --share-processes -- bash"
        ];
      };

      "toggle-helmrelease" = {
        shortCut = "Shift-T";
        confirm = true;
        scopes = [ "helmreleases" ];
        description = "Toggle to suspend or resume a HelmRelease";
        command = "bash";
        background = false;
        args = [
          "-c"
          ''
            suspended=$(kubectl --context $CONTEXT get helmreleases -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
            verb=$([ $suspended = "true" ] && echo "resume" || echo "suspend");
            flux $verb helmrelease --context $CONTEXT -n $NAMESPACE $NAME | less -K
          ''
        ];
      };

      "toggle-kustomization" = {
        shortCut = "Shift-T";
        confirm = true;
        scopes = [ "kustomizations" ];
        description = "Toggle to suspend or resume a Kustomization";
        command = "bash";
        background = false;
        args = [
          "-c"
          ''
            suspended=$(kubectl --context $CONTEXT get kustomizations -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
            verb=$([ $suspended = "true" ] && echo "resume" || echo "suspend");
            flux $verb kustomization --context $CONTEXT -n $NAMESPACE $NAME | less -K
          ''
        ];
      };

      "reconcile-git" = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "gitrepositories" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ''flux reconcile source git --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-hr" = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "helmreleases" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ''flux reconcile helmrelease --with-source --reset --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-helm-repo" = {
        shortCut = "Shift-Z";
        description = "Flux reconcile";
        scopes = [ "helmrepositories" ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''flux reconcile source helm --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-oci-repo" = {
        shortCut = "Shift-Z";
        description = "Flux reconcile";
        scopes = [ "ocirepositories" ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''flux reconcile source oci --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-ks" = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "kustomizations" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ''flux reconcile kustomization --with-source --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-ir" = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "imagerepositories" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          ''flux reconcile image repository --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      "reconcile-iua" = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "imageupdateautomations" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          ''flux reconcile image update --context $CONTEXT -n $NAMESPACE $NAME | less -K''
        ];
      };

      trace = {
        shortCut = "Shift-P";
        confirm = false;
        description = "Flux trace";
        scopes = [ "all" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ''
            resource=$(echo $RESOURCE_NAME | sed -E 's/ies$/y/' | sed -E 's/ses$/se/' | sed -E 's/(s|es)$//g');
            flux trace \
              --context $CONTEXT \
              --kind $resource \
              --api-version $RESOURCE_GROUP/$RESOURCE_VERSION \
              --namespace $NAMESPACE $NAME | less -K
          ''
        ];
      };

      # credits: https://github.com/fluxcd/flux2/discussions/2494
      "get-suspended-helmreleases" = {
        shortCut = "Shift-S";
        confirm = false;
        description = "Suspended Helm Releases";
        scopes = [ "helmrelease" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          ''
            kubectl get --context $CONTEXT --all-namespaces helmreleases.helm.toolkit.fluxcd.io -o json \
              | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.namespace,.metadata.name,.spec.suspend] | @tsv' \
              | less -K
          ''
        ];
      };

      "get-suspended-kustomizations" = {
        shortCut = "Shift-S";
        confirm = false;
        description = "Suspended Kustomizations";
        scopes = [ "kustomizations" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          ''
            kubectl get --context $CONTEXT --all-namespaces kustomizations.kustomize.toolkit.fluxcd.io -o json \
              | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.name,.spec.suspend] | @tsv' \
              | less -K
          ''
        ];
      };

      "vector-top" = {
        shortCut = "h";
        confirm = false;
        description = "Execute `vector top`";
        scopes = [ "pods" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          "kubectl exec --context=$CONTEXT --namespace=$NAMESPACE --stdin --tty $NAME -- vector top"
        ];
      };

      "vector-top-container" = {
        shortCut = "h";
        confirm = false;
        description = "Execute `vector top`";
        scopes = [ "containers" ];
        command = "sh";
        background = false;
        args = [
          "-c"
          "kubectl exec --context=$CONTEXT --namespace=$NAMESPACE --stdin --tty $POD --container=$NAME -- vector tap"
        ];
      };
    };

    settings = {
      k9s = {
        liveViewAutoRefresh = false;
        screenDumpDir = "/home/gabriel/.local/state/k9s/screen-dumps";

        refreshRate = 2;
        maxConnRetry = 5;
        readOnly = false;
        noExitOnCtrlC = false;

        ui = {
          enableMouse = false;
          headless = false;
          logoless = true;
          crumbsless = false;
          reactive = true;
          noIcons = false;
          skin = "kanagawaSkin"; # active le skin défini plus bas
        };

        skipLatestRevCheck = false;
        disablePodCounting = false;

        shellPod = {
          image = "busybox:1.35.0";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "100Mi";
          };
        };

        imageScans = {
          enable = false;
          exclusions = {
            namespaces = [ ];
            labels = { };
          };
        };

        logger = {
          tail = 100;
          buffer = 5000;
          sinceSeconds = -1;
          fullScreen = false;
          textWrap = false;
          showTime = false;
        };

        thresholds = {
          cpu = { critical = 90; warn = 70; };
          memory = { critical = 90; warn = 70; };
        };
      };
    };

    skins = let
      colors = {
        foreground = "#EAF2F7";
        background = "#0B0C10";
        black = "#050508";
        blue = "#677ec9";
        green = "#02f2d2";
        grey = "#A4A9B6";
        orange = "#ff66cc";
        purple = "#a985d6";
        red = "#ff4d6d";
        yellow = "#02c6f2";
        yellow_bright = "#FFFFFF";
      };
    in {
      kanagawaSkin = {
        k9s = {
          body = {
            fgColor = colors.foreground;
            bgColor = colors.background;
            logoColor = colors.green;
          };
          prompt = {
            fgColor = colors.foreground;
            bgColor = colors.background;
            suggestColor = colors.orange;
          };
          info = {
            fgColor = colors.grey;
            sectionColor = colors.green;
          };
          help = {
            fgColor = colors.foreground;
            bgColor = colors.background;
            keyColor = colors.yellow;
            numKeyColor = colors.blue;
            sectionColor = colors.purple;
          };
          dialog = {
            fgColor = colors.black;
            bgColor = colors.background;
            buttonFgColor = colors.foreground;
            buttonBgColor = colors.green;
            buttonFocusFgColor = colors.black;
            buttonFocusBgColor = colors.blue;
            labelFgColor = colors.orange;
            fieldFgColor = colors.blue;
          };
          frame = {
            border = {
              fgColor = colors.green;
              focusColor = colors.green;
            };
            menu = {
              fgColor = colors.grey;
              keyColor = colors.yellow;
              numKeyColor = colors.yellow;
            };
            crumbs = {
              fgColor = colors.black;
              bgColor = colors.green;
              activeColor = colors.yellow;
            };
            status = {
              newColor = colors.blue;
              modifyColor = colors.green;
              addColor = colors.grey;
              pendingColor = colors.orange;
              errorColor = colors.red;
              highlightColor = colors.yellow;
              killColor = colors.purple;
              completedColor = colors.grey;
            };
            title = {
              fgColor = colors.blue;
              bgColor = colors.background;
              highlightColor = colors.purple;
              counterColor = colors.foreground;
              filterColor = colors.blue;
            };
          };
          views = {
            charts = {
              bgColor = colors.background;
              defaultDialColors = [ colors.green colors.red ];
              defaultChartColors = [ colors.green colors.red ];
            };
            table = {
              fgColor = colors.yellow;
              bgColor = colors.background;
              cursorFgColor = colors.black;
              cursorBgColor = colors.blue;
              markColor = colors.yellow_bright;
              header = {
                fgColor = colors.grey;
                bgColor = colors.background;
                sorterColor = colors.orange;
              };
            };
            xray = {
              fgColor = colors.blue;
              bgColor = colors.background;
              cursorColor = colors.foreground;
              graphicColor = colors.yellow_bright;
              showIcons = false;
            };
            yaml = {
              keyColor = colors.red;
              colonColor = colors.grey;
              valueColor = colors.grey;
            };
            logs = {
              fgColor = colors.grey;
              bgColor = colors.background;
              indicator = {
                fgColor = colors.blue;
                bgColor = colors.background;
                toggleOnColor = colors.red;
                toggleOffColor = colors.grey;
              };
            };
            help = {
              fgColor = colors.grey;
              bgColor = colors.background;
              indicator = { fgColor = colors.blue; };
            };
          };
        };
      };
    };
  };
}