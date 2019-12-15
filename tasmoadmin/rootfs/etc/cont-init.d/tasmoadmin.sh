#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: TasmoAdmin
# Configures TasmoAdmin
# ==============================================================================

declare app_root_dir=/var/www/tasmoadmin/tasmoadmin
declare ingress_entry="$(bashio::addon.ingress_entry)"
declare ingress_dir="${app_root_dir}${ingress_entry}"

# Migrate from older installations
if bashio::fs.directory_exists "/data/sonweb"; then
    bashio::log.info 'Migrating data from sonweb to tasmoadmin...'

    # Rename data folder
    mv /data/sonweb /data/tasmoadmin

    # Ensure file permissions
    chown -R nginx:nginx /data/tasmoadmin
    find /data/tasmoadmin -not -perm 0644 -type f -exec chmod 0644 {} \;
    find /data/tasmoadmin -not -perm 0755 -type d -exec chmod 0755 {} \;
fi

# Ensure persistant storage exists
if ! bashio::fs.directory_exists "/data/tasmoadmin"; then
    bashio::log.debug 'Data directory not initialized, doing that now...'

    # Setup structure
    cp -R /var/www/tasmoadmin/tasmoadmin/data /data/tasmoadmin

    # Ensure file permissions
    chown -R nginx:nginx /data/tasmoadmin
    find /data/tasmoadmin -not -perm 0644 -type f -exec chmod 0644 {} \;
    find /data/tasmoadmin -not -perm 0755 -type d -exec chmod 0755 {} \;
fi

bashio::log.debug 'Symlinking data directory to persistent storage location...'
rm -f -r /var/www/tasmoadmin/tasmoadmin/data
ln -s /data/tasmoadmin /var/www/tasmoadmin/tasmoadmin/data

# Setup application filesystem as symlink to the app for the ingress
mkdir -p "$(dirname ${ingress_dir})"
ln -s "${app_root_dir}" "${ingress_dir}"

# Apply application patches
cd "${app_root_dir}" || bashio.exit.nok "Failed cd to ${app_root_dir} to apply patches"
patch -p2 < /etc/tasmoadmin/patches/tasmoadmin-disable-auth.patch
patch -p2 < /etc/tasmoadmin/patches/tasmoadmin-base-url.patch