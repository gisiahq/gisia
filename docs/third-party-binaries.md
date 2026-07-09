# Third-Party Binaries Notice

The Docker distribution of Gisia ships with a set of prebuilt third-party binaries in `coms/bin`. These are included purely for convenience so you can get up and running quickly.

## Bundled binaries

| Binary | Component | Purpose |
|--------|-----------|---------|
| `gitaly` | Gitaly | Git RPC service that handles all Git repository access |
| `praefect` | Gitaly (Praefect) | Router and transaction manager for Gitaly clusters |
| `workhorse` | GitLab Workhorse | Smart reverse proxy that handles large HTTP requests (Git over HTTP, uploads, downloads) |
| `gisia-shell` | GitLab Shell | Handles Git over SSH sessions and authorized key management |

The exact versions bundled with each release are recorded in the `vendor/` directory of the Docker setup.

## Building them yourself

You are not required to use the prebuilt binaries. All of the components above are open-source projects maintained by their respective upstreams, and you can build each of them from source by following the build instructions published on their official sites. Once built, replace the corresponding files in `coms/bin` with your own binaries.

These components are third-party software and are distributed under their own licenses. See the `NOTICE` and `.licenses` folders in the Docker setup for details.
