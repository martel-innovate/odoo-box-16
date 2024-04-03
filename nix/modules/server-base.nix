#
# Base Odoo server machine.
#
# This module brings together several other modules to
# - build our base OS (`odbox.base`);
# - enable SSH;
# - only open the ports we actually need;
# - run the Odoo service stack (`odbox.service-stack`).
#
# Each machine we build (dev VM, staging, prod) enables this module
# to bring in the bulk of the required functionality and then bolts
# on machine-specific tweaks like passwords, time zone, swap file,
# and so on.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    odbox.server.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install the base Odoo server machine.
      '';
    };
  };

  config = let
    enabled = config.odbox.server.enable;
    psql = config.services.postgresql.package;
  in (mkIf enabled
  {
    # Start from our OS base config.
    odbox.base = {
      enable = true;
      cli-tools = pkgs.odbox.linux-admin-shell.paths;
    };

    # Allow remote access through SSH, even for root.
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = mkForce "yes";                # (1)
    };

    # Set up a firewall to let in only SSH and HTTP traffic.
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };

    # Bring in our Odoo service stack.
    odbox.service-stack = {
      enable = true;
      # bootstrap-mode = true;
      odoo-db-name = "odoo_martel_14";
    };
  });

}
# NOTE
# ----
# 1. SSH root access. We only need it for remote deployments through
# `nixos-rebuild`. In theory we don't actually need this b/c we could
# ask `nixos-rebuild` to use `sudo` instead of logging in as root (see
# the `--use-remote-sudo` flag), but in practice support for `sudo` is
# kinda flaky at the moment---it definitely didn't work for me, despite
# the various workarounds suggested on the interwebs.
# See:
# - https://discourse.nixos.org/t/remote-nixos-rebuild-sudo-askpass-problem
#
# As a slight improvement, we could configure SSH to only let in root
# through a password-less login with an SSH key. (Set `PermitRootLogin`
# to `prohibit-password`.) But for now we'd like to keep the convenience.
# Notice we've got to use `mkForce` because the AWS image expression sets
# `PermitRootLogin` to `prohibit-password`:
# # - https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/virtualisation/amazon-image.nix#L84
# Since we'd also like to run on EC2 and to do that we need to import the
# AWS image expression, we've got to force our setting to stop Nix from
# moaning about
# > The option `services.openssh.settings.PermitRootLogin' has conflicting
# > definition values
#
