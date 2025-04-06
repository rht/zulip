{
  description = "Hello world flake using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      process-compose-flake,
      services-flake,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # Load a uv workspace from a workspace root.
      # Uv2nix treats all uv projects as workspace projects.
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      # Create package overlay from workspace.
      overlay = workspace.mkPyprojectOverlay {
        # Prefer prebuilt binary wheels as a package source.
        # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
        # Binary wheels are more likely to, but may still require overrides for library dependencies.
        sourcePreference = "wheel"; # or sourcePreference = "sdist";
        # Optionally customise PEP 508 environment
        # environ = {
        #   platform_release = "5.10.65";
        # };
      };

      pyprojectOverridesNativeOnly =
        _final: _prev:
        let
          inherit (_final) resolveBuildSystem;
          inherit (builtins) mapAttrs;

          # Build system dependencies specified in the shape expected by resolveBuildSystem
          # The empty lists below are lists of optional dependencies.
          #
          # A package `foo` with specification written as:
          # `setuptools-scm[toml]` in pyproject.toml would be written as
          # `foo.setuptools-scm = [ "toml" ]` in Nix
          buildSystemOverrides = {
            asgiref.setuptools = [ ];
            django-bitfield.setuptools = [ ];
            django-bmemcached.setuptools = [ ];
            html2text.setuptools = [ ];
            peewee.setuptools = [ ];
            pyinotify.setuptools = [ ];
            pyoembed.setuptools = [ ];
            pyvips.setuptools = [ ];
            zulint.setuptools = [ ];
            uwsgi.setuptools = [ ];
          };

        in
        mapAttrs (
          name: spec:
          _prev.${name}.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ resolveBuildSystem spec;
          })
        ) buildSystemOverrides;

      # Extend generated overlay with build fixups
      #
      # Uv2nix can only work with what it has, and uv.lock is missing essential metadata to perform some builds.
      # This is an additional overlay implementing build fixups.
      # See:
      # - https://pyproject-nix.github.io/uv2nix/FAQ.html
      pyprojectOverrides = _final: _prev: {
        # Implement build fixups here.
        # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
        # It's using https://pyproject-nix.github.io/pyproject.nix/build.html

        lxml = _prev.lxml.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [
            pkgs.python311Packages.cython
            pkgs.libxml2
            pkgs.libxslt
            pkgs.zlib
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });
        psycopg2 = _prev.psycopg2.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.postgresql_16 ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });
        python-ldap = _prev.python-ldap.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [
            pkgs.openldap
            pkgs.cyrus_sasl
            pkgs.python311Packages.distutils-extra
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });
        talon-core = _prev.talon-core.overrideAttrs (old: {
          preBuild = [
            old.preBuild or ""
            ''
              cd talon-core
            ''
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });
        xmlsec = _prev.xmlsec.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [
            pkgs.pkg-config
            pkgs.xmlsec
            pkgs.libxml2
            pkgs.libtool_1_5
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
              pkgconfig = [ ];
              lxml = [ ];
            })
          ];
        });
        zulip = _prev.zulip.overrideAttrs (old: {
          preBuild = [
            old.preBuild or ""
            ''
              cd zulip
            ''
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });
        zulip-bots = _prev.zulip-bots.overrideAttrs (old: {
          preBuild = [
            old.preBuild or ""
            ''
              cd zulip_bots
            ''
          ];
          nativeBuildInputs = old.nativeBuildInputs ++ [
            (_final.resolveBuildSystem {
              setuptools = [ ];
            })
          ];
        });

      };

      # This example is only using x86_64-linux
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # Use Python 3.11 from nixpkgs
      # https://github.com/TyberiusPrime/uv2nix_hammer_overrides/blob/a583ff5a32c581698538c902d6c3beb8dbe32b32/overrides/python-ldap/3.4.4/rules.toml#L3C1-L3C25
      python = pkgs.python311;

      # Construct package set
      pythonSet =
        # Use base package set from pyproject.nix builders
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              overlay
              pyprojectOverridesNativeOnly
              pyprojectOverrides
            ]
          );

      # Services
      servicesMod = (import process-compose-flake.lib { inherit pkgs; }).evalModules {
        modules = [
          services-flake.processComposeModules.default
          {
            services.postgres."pg1".enable = true;
          }
        ];
      };

    in
    {
      # Package a virtual environment as our main application.
      #
      # Enable no optional dependencies for production build.
      #packages.x86_64-linux.default = pythonSet.mkVirtualEnv "zulip-server-env" workspace.deps.default;
      packages.x86_64-linux.default = servicesMod.config.outputs.package;

      # Make hello runnable with `nix run`
      #apps.x86_64-linux = {
      #  default = {
      #    type = "app";
      #    program = "${self.packages.x86_64-linux.default}/bin/hello";
      #  };
      #};

      # This example provides two different modes of development:
      # - Impurely using uv to manage virtual environments
      # - Pure development using uv2nix to manage virtual environments
      devShells.x86_64-linux = {
        # It is of course perfectly OK to keep using an impure virtualenv workflow and only use uv2nix to build packages.
        # This devShell simply adds Python and undoes the dependency leakage done by Nixpkgs Python infrastructure.
        impure = pkgs.mkShell {
          inputsFrom = [ servicesMod.config.services.outputs.devShell ];

          packages = [
            python
            pkgs.uv
          ];
          env =
            {
              # Prevent uv from managing Python downloads
              UV_PYTHON_DOWNLOADS = "never";
              # Force uv to use nixpkgs Python interpreter
              UV_PYTHON = python.interpreter;
            }
            // lib.optionalAttrs pkgs.stdenv.isLinux {
              # Python libraries often load native shared objects using dlopen(3).
              # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
              LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
            };
          shellHook = ''
            unset PYTHONPATH
          '';
        };

        # This devShell uses uv2nix to construct a virtual environment purely from Nix, using the same dependency specification as the application.
        # The notable difference is that we also apply another overlay here enabling editable mode ( https://setuptools.pypa.io/en/latest/userguide/development_mode.html ).
        #
        # This means that any changes done to your local files do not require a rebuild.
        #
        # Note: Editable package support is still unstable and subject to change.
        uv2nix =
          let
            # Enable all optional dependencies for development.
            virtualenv = pythonSet.mkVirtualEnv "hello-world-dev-env" workspace.deps.all;

          in
          pkgs.mkShell {
            inputsFrom = [ servicesMod.config.services.outputs.devShell ];

            packages = [
              pkgs.memcached
              pkgs.rabbitmq-server
              pkgs.python311Packages.supervisor
              pkgs.git
              pkgs.redis
              pkgs.hunspellDicts.en_US
              pkgs.puppet-lint
              pkgs.jre8_headless # Required by vnu-jar
              pkgs.curl # Used for testing our API documentation
              pkgs.puppet # Used by lint (`puppet parser validate`)
              pkgs.gettext # Used by makemessages i18n
              pkgs.moreutils # Used for sponge command
              pkgs.unzip # Needed for Slack import
              pkgs.crudini # Used for shell tooling w/ zulip.conf
              # Puppeteer dependencies from here
              pkgs.xdg-utils
              pkgs.freefont_ttf
              #"libatk-bridge2.0-0", todo
              pkgs.libgbm
              pkgs.gtk3
              pkgs.xorg.libxcb
              #"libxcb-dri3-0", todo
              #"libxss1", todo
              pkgs.xorg.xvfb
              # Puppeteer dependencies end here.
              pkgs.postgresql_16
              pkgs.postgresql16Packages.pgroonga

              virtualenv
              pkgs.uv
            ];

            env = {
              # Don't create venv using uv
              UV_NO_SYNC = "1";

              # Force uv to use Python interpreter from venv
              UV_PYTHON = "${virtualenv}/bin/python";

              # Prevent uv from downloading managed Python's
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              # Undo dependency propagation by nixpkgs.
              unset PYTHONPATH

              # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
      };
    };
}
