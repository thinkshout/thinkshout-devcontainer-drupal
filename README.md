# ThinkShout Drupal Codespaces starter

Drop-in `.devcontainer/` setup so a non-developer can open a project in
**GitHub Codespaces**, get a working Drupal site with no local install, make
a CSS change, and open a PR — all from the browser.

## What's in here

| File                 | Purpose                                                            |
| -------------------- | ------------------------------------------------------------------ |
| `Dockerfile`         | PHP 8.3, Composer, Drush — pinned versions, shared across projects. |
| `devcontainer.json`  | Wires up the container, Node feature, forwarded port, and scripts.  |
| `setup.sh`           | Runs once: `composer install`, installs Drupal (SQLite), prints admin login. |
| `start-server.sh`    | Runs on every start: boots PHP's built-in webserver on port 8080.   |

No MySQL/MariaDB container — Drupal installs against **SQLite**, which
removes a whole service (and its startup race conditions) from the sandbox.
Fine for CSS/theme preview work; swap `--db-url` in `setup.sh` if a project
later needs to test against real data.

## Adding this to a project (submodule pattern)

Rather than copy these files into every repo (and then having to update them
N times), add this repo as a git submodule at `.devcontainer`:

```bash
# One-time, per project:
git submodule add git@github.com:thinkshout/thinkshout-devcontainer-drupal.git .devcontainer
git commit -m "Add Codespaces devcontainer"
```

To pick up updates later (new PHP/Node version, bug fixes) in any project:

```bash
git submodule update --remote .devcontainer
git commit -m "Update devcontainer"
```

## The non-dev workflow this enables

1. On the GitHub repo, click **Code → Codespaces → Create codespace on main**.
2. Wait for the one-time setup (a few minutes) — a banner prints the admin
   username/password when it's done.
3. Open the "Drupal site" preview tab, log in, browse to the CSS file (or
   open it directly in the VS Code file tree under the theme's `css/` folder).
4. Edit, save — refresh the preview tab to see the change.
5. Use the Source Control panel (or `git checkout -b`, `git commit`, `git push`)
   to push the change to a new branch, then click **Compare & pull request**
   on GitHub.

## Notes / next steps

- `setup.sh` assumes a Composer-managed Drupal site with docroot at `web/`
  and looks for a custom theme with a `package.json` under
  `web/themes/custom/*` — adjust `DOCROOT` / `THEME_PATH` at the top of the
  script if a project's layout differs.
- If a project's theme needs a different Node version, change it in
  `devcontainer.json` under `features` rather than in the Dockerfile.
- Consider adding a GitHub Action that lints CSS/Twig on the PR, since a
  non-dev won't be running local linters.
