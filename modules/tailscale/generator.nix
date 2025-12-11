{
  clan.core.vars.generators.tailscale = {
    prompts.authKey.type = "line";
    prompts.authKey.description = "Tailscale/Headscale auth key (tskey-auth-xyz or headscale preauthkey)";
    prompts.authKey.display = {
      label = "Tailscale Auth Key";
      required = true;
      helperText = "Create from Tailscale admin console, or for Headscale: headscale preauthkeys create --user <username>";
    };
  };
}
