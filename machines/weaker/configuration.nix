{
  config,
  lib,
  pkgs,
  ...
}:

{
  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  networking.hostName = "weaker";
  networking.firewall.enable = false;
  networking = {
    interfaces.ens18.ipv4.addresses = [
      {
        address = "10.26.11.192";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "10.26.11.97";
      interface = "ens18";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
