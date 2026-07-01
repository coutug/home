{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.email = "coutug18@hotmail.com";
      user.name = "coutug";
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };
}
