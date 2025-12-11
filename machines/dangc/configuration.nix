{
  pkgs,
  ...
}:

{
  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  networking.hostName = "dangc";
  networking.firewall.enable = true;
  networking = {
    interfaces.ens3.ipv4.addresses = [
      {
        address = "141.98.199.68";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "141.98.199.1";
      interface = "ens3";
    };
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
}
