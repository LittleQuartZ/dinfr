{ self, ... }:
{
  imports = [ self.inputs.home-manager.nixosModules.default ];

  home-manager.users.dan = {
    imports = [
      ./home.nix
    ];
  };
}
