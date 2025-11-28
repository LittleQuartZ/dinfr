{
  clan.core.vars.generators.tailscale = {
    prompts.authKey.type = "line";
    prompts.authKey.description = "Tailscale auth key (tskey-auth-xyz)";
    prompts.authKey.display = {
      label = "Tailscale Auth Key";
      required = true;
      helperText = "You can create an auth key from the Tailscale admin console or your headscale instance.";
    };
  };
}
