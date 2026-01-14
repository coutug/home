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

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    cp ${./tsconfig.build.json} tsconfig.build.json
  '';

  nodejs = nodejs_20;
  npmDepsHash = "sha256-Pw9SdM/Ek0VvGIjWLBN32Cmb+OpbQPb2tc+SHK9pw70=";

  nativeBuildInputs = [
    bun
    cargo
    rustc
  ];

  dontNpmBuild = true;

  buildPhase = ''
    runHook preBuild
    bun build src/index.ts --outdir dist --target bun --format esm --external @ast-grep/napi
    ./node_modules/.bin/tsc --emitDeclarationOnly --project tsconfig.build.json
    bun build src/cli/index.ts --outdir dist/cli --target bun --format esm --external @ast-grep/napi
    bun run build:schema
    runHook postBuild
  '';

  meta = {
    description = "Batteries-included OpenCode plugin with multi-model orchestration";
    homepage = "https://github.com/code-yeongyu/oh-my-opencode";
    license = lib.licenses.unfree;
  };
}
