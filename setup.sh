#!/usr/bin/env bash
#
# .devcontainer/setup.sh
#
# Runs ONCE, automatically, the first time the Codespace is created
# (wired up via "postCreateCommand" in devcontainer.json).
#
# What it does:
#   1. Installs PHP dependencies (Composer) and, if present, front-end
#      dependencies (npm) for a custom theme.
#   2. Installs a brand-new, empty Drupal site using SQLite — no separate
#      database container required.
#   3. Creates a known admin username/password and prints a one-time login
#      link so a non-developer can just click straight into the site.
#   4. Builds the theme once so the CSS is ready to preview immediately.
#
# Safe to re-run: if Drupal is already installed, step 2 is skipped.

set -euo pipefail # Exit immediately on any error, undefined variable, or failed pipe.

# Tee all output to a log so it's readable after the creation panel closes.
exec > >(tee /tmp/setup.log) 2>&1

# ── Configuration ────────────────────────────────────────────────────────────
# Adjust these to match your project's actual structure/theme name, or expose
# them as Codespaces environment variables (Settings > Codespaces > Secrets)
# if you want them to differ per-project without editing this script.
DOCROOT="web"                              # Path to Drupal's docroot in this repo.
SITE_NAME="${SITE_NAME:-Drupal Sandbox}"   # Site name shown in the admin UI.
ADMIN_USER="${ADMIN_USER:-admin}"          # Admin username created on install.
THEME_PATH="${THEME_PATH:-$DOCROOT/themes/custom}" # Where custom themes live.

echo "── Installing PHP dependencies (composer) ──────────────────────────"
composer install --no-interaction --no-progress

# ── Front-end dependencies (only if a custom theme exists) ──────────────────
# We look for the first package.json under the custom themes directory so this
# script doesn't need to know the theme's name in advance.
THEME_DIR="$(find "$THEME_PATH" -maxdepth 2 -name package.json -exec dirname {} \; 2>/dev/null | head -n 1 || true)"

if [ -n "$THEME_DIR" ]; then
  echo "── Installing Node dependencies for theme: $THEME_DIR ────────────"
  (cd "$THEME_DIR" && npm install)
else
  echo "── No custom theme with package.json found — skipping npm install ─"
fi

# ── Drupal install (skipped if the site is already installed) ──────────────
cd "$DOCROOT"

if vendor/bin/drush status --field=bootstrap 2>/dev/null | grep -q "Successful"; then
  echo "── Drupal is already installed — skipping site-install ────────────"
else
  echo "── Installing a fresh, empty Drupal site (SQLite) ─────────────────"

  # Generate a random, readable password instead of hard-coding one, so every
  # Codespace gets a unique credential rather than a shared default password.
  ADMIN_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)"

  vendor/bin/drush site:install standard \
    --site-name="$SITE_NAME" \
    --account-name="$ADMIN_USER" \
    --account-pass="$ADMIN_PASS" \
    --db-url=sqlite://sites/default/files/.ht.sqlite \
    --yes

  # Persist the credentials somewhere the non-dev can find them again after
  # the initial banner has scrolled off-screen (e.g. after a reboot).
  cat > /tmp/drupal-credentials.txt <<EOF
Drupal admin login
-------------------
URL:      (see the "Drupal site" forwarded port / preview tab)
Username: $ADMIN_USER
Password: $ADMIN_PASS
EOF

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo " Drupal is installed! Admin credentials (saved to"
  echo " /tmp/drupal-credentials.txt):"
  echo ""
  echo "   Username: $ADMIN_USER"
  echo "   Password: $ADMIN_PASS"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
fi

cd - >/dev/null

# ── Build the theme once so CSS is visible on first preview ────────────────
if [ -n "$THEME_DIR" ]; then
  echo "── Running initial theme build ─────────────────────────────────────"
  (cd "$THEME_DIR" && npm run build 2>/dev/null || echo "  (no 'build' script defined — skipping)")
fi

echo "── Setup complete ──────────────────────────────────────────────────"
