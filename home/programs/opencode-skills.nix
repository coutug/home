{ lib, opencodeSkillSources, ... }:
let
  localDir = ../config/opencode/skills;
  localSkills = lib.mapAttrs (name: _: localDir + "/${name}") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (localDir + "/${name}/SKILL.md")
    ) (builtins.readDir localDir)
  );
  externalSkills = {
    grilling = "${opencodeSkillSources.skills-mattpocock}/skills/productivity/grilling";
  };
  collisions = lib.intersectLists (builtins.attrNames localSkills) (builtins.attrNames externalSkills);
in
{
  assertions = [
    {
      assertion = collisions == [ ];
      message = "OpenCode local and external skills have duplicate IDs: ${lib.concatStringsSep ", " collisions}";
    }
  ]
  ++ lib.mapAttrsToList (name: path: {
    assertion = builtins.pathExists (path + "/SKILL.md");
    message = "OpenCode external skill '${name}' is missing SKILL.md at ${path}";
  }) externalSkills;

  xdg.configFile = lib.mapAttrs' (
    name: source:
    lib.nameValuePair "opencode/skills/${name}" {
      inherit source;
      recursive = true;
    }
  ) (localSkills // externalSkills);
}
