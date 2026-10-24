{ config, pkgs, ... }:
let
  version = "0.14.6";
  app = pkgs.appimageTools.wrapType2 {
    pname = "agent-orchestrator";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/OrchestratorInc/agent-orchestrator/releases/download/v${version}/agent-orchestrator-linux-x64.AppImage";
      # nix store prefetch-file --json "https://github.com/OrchestratorInc/agent-orchestrator/releases/download/v${VERSION}/agent-orchestrator-linux-x64.AppImage"
      hash = "sha256-uJ8nAtvzRguA6R1Hauag1JrsfNuvS4SuFlpXHwHoQxg=";
    };
  };
  wrappedApp = config.lib.nixGL.wrap app;
  launcher = pkgs.writeShellApplication {
    name = "agent-orchestrator";
    text = ''
      export AO_TELEMETRY_RENDERER=off
      export AO_TELEMETRY_EVENTS=off
      export AO_TELEMETRY_REMOTE=off
      exec ${wrappedApp}/bin/agent-orchestrator "$@"
    '';
  };
in
{
  home.packages = [ launcher ];

  xdg.desktopEntries.agent-orchestrator = {
    name = "Agent Orchestrator";
    comment = "Plan and supervise coding agents";
    exec = "${launcher}/bin/agent-orchestrator";
    terminal = false;
    categories = [ "Development" ];
  };
}
