{
  lib,
  pkgs,
  config,
  ...
}:
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home = {
    username = "dan";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "25.11";
  };

  home.packages = lib.attrValues {
    inherit (pkgs)
      nodejs
      bun
      ripgrep
      httpie
      jq
      fd
      bat
      git
      jujutsu
      ;
  };

  xdg.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Syahdan";
        email = "syahdanhafizzz@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    defaultKeymap = "viins";
    history = {
      save = 10000;
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };

  programs.gh.enable = true;
}
