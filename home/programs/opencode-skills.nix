{ lib, opencodeSkillSources, ... }:
let
  localDir = ../config/opencode/skills;
  localSkills = lib.mapAttrs (name: _: localDir + "/${name}") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (localDir + "/${name}/SKILL.md")
    ) (builtins.readDir localDir)
  );
  externalSkills = {
    # mattpocock
    grilling = "${opencodeSkillSources.skills-mattpocock}/skills/productivity/grilling";
    grill-me = "${opencodeSkillSources.skills-mattpocock}/skills/productivity/grill-me";
    teach = "${opencodeSkillSources.skills-mattpocock}/skills/productivity/teach";
    writing-for-agents = "${opencodeSkillSources.skills-mattpocock}/skills/productivity/writing-for-agents";
    grill-with-docs = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/grill-with-docs";
    domain-modeling = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/domain-modeling";
    to-spec = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/to-spec";
    to-tickets = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/to-tickets";
    implement = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/implement";
    implement-spec = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/implement-spec";
    code-review = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/code-review";
    retro = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/retro";
    pr = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/pr";
    codebase-design = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/codebase-design";
    tdd = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/tdd";
    triage = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/triage";
    improve-codebase-architecture = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/improve-codebase-architecture";
    research = "${opencodeSkillSources.skills-mattpocock}/skills/engineering/research";
  };
  collisions = lib.intersectLists (builtins.attrNames localSkills) (
    builtins.attrNames externalSkills
  );
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
