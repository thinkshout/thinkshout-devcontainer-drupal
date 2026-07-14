# Base: Microsoft's official Devcontainer PHP image. It already includes git,
# curl, unzip, and a non-root "vscode" user with sudo — all the plumbing
# Codespaces expects, so we only need to layer Drupal-specific tools on top.
FROM mcr.microsoft.com/devcontainers/php:1-8.3-bookworm

# PHP extensions Drupal needs that aren't in the base image by default.
# (gd = image handling, zip = module installs, pdo_sqlite = our DB driver,
# opcache = meaningfully faster page loads even in a throwaway sandbox.)
RUN docker-php-ext-install gd zip pdo_sqlite opcache

# Composer is already in this base image, but pin it explicitly so a future
# Composer major version bump upstream can't silently break installs here.
RUN composer self-update 2.7.7

# Install Drush globally so it's available project-wide without a per-project
# composer require — keeps this image reusable across many repos.
RUN composer global require drush/drush:^12 \
    && echo 'export PATH="$PATH:/home/vscode/.composer/vendor/bin"' >> /home/vscode/.bashrc

# Make sure the non-root user owns its own Composer home (avoids permission
# errors the first time `composer install` runs inside the Codespace).
RUN chown -R vscode:vscode /home/vscode/.composer || true

USER vscode
