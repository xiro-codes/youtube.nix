{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosModules = rec {
      default = youtube-dl;
      youtube-dl = {
        config,
        pkgs,
        lib,
        ...
      }: let
        cfg = config.services.youtube-dl;
        inherit (lib) getExe mkOption mkIf mkMerge types mkDefault;
      in {
        imports = [];
        options.services.youtube-dl = {
          delay = mkOption {
            default = "5m";
            type = types.str;
          };
          user = mkOption {
            default = "tod";
            type = types.str;
          };
          group = mkOption {
            default = "users";
            type = types.str;
          };
          freq = mkOption {
            default = "2h";
            type = types.str;
          };
          scanDepth = mkOption {
            default = "4";
            type = types.str;
          };
          targets = mkOption {
            default = [];
            type = with types;
              listOf (submodule {
                options = {
                  name = mkOption {type = types.str;};
                  channel = mkOption {type = types.str;};
                  dest = mkOption {type = types.str;};
                };
              });
          };
        };
        config.systemd = let
          services =
            map (t: {
              services."youtube-dl-${t.name}" = {
                script = ''
                  mkdir -p ${t.dest}/$(date -d "today" "+%Y%m%d")
                  cd ${t.dest}/$(date -d "today" "+%Y%m%d")
                  ${getExe pkgs.yt-dlp} ${t.channel} --playlist-end ${self.scanDepth} --dateafter today --no-cache-dir
                        rmdir ${t.dest}/$(date -d "today" "+%Y%m%d") 2> /dev/null || true
                '';
                serviceConfig = {
                  User = self.user;
                  Group = self.group;
                  Type = "oneshot";
                };
              };
              timers."youtube-dl-${t.name}" = {
                wantedBy = ["timers.target"];
                timerConfig = {
                  OnBootSec = "${self.delay}";
                  OnUnitInactiveSec = "${self.freq}";
                  Unit = "youtube-dl-${t.name}.service";
                };
              };
            })
            config.services.youtube-dl.targets;
        in
          mkMerge services;
      };
    };
  };
}
