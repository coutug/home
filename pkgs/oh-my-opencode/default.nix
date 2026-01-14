{
  lib,
  buildNpmPackage,
  bun,
  cargo,
  rustc,
  nodejs_20,
  src,
}:

buildNpmPackage {
  pname = "oh-my-opencode";
  version = "3.0.0-beta.7";

  inherit src;

  nodejs = nodejs_20;
  npmDepsHash = "sha256-Pw9SdM/Ek0VvGIjWLBN32Cmb+OpbQPb2tc+SHK9pw70=";

  nativeBuildInputs = [
    bun
    cargo
    rustc
  ];

  npmBuildScript = "build";

  meta = {
    description = "Batteries-included OpenCode plugin with multi-model orchestration";
    homepage = "https://github.com/code-yeongyu/oh-my-opencode";
    license = lib.licenses.unfree;
  };
}
