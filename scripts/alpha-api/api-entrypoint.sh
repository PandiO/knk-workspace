#!/bin/sh
# knk-alpha API entrypoint: the image's knk-api-entrypoint plus optional secrets (Phase 9, KNG-216).
# Mounted over the image's copy from config/api/; later images bake it in.
set -eu
read_secret()
{
    secret_path="$1"
    secret_name="$2"
    if [ ! -r "$secret_path" ]; then
        printf 'Required secret is not readable: %s\n' "$secret_name" >&2
        exit 1
    fi
    secret_value="$(cat "$secret_path")"
    if [ -z "$secret_value" ]; then
        printf 'Required secret is empty: %s\n' "$secret_name" >&2
        exit 1
    fi
    printf '%s' "$secret_value"
}
MYSQL_PASSWORD="$(read_secret /run/secrets/mysql_app_password mysql_app_password)"
PLUGIN_API_KEY="$(read_secret /run/secrets/plugin_api_key plugin_api_key)"
JWT_SECRET="$(read_secret /run/secrets/jwt_secret jwt_secret)"
MYSQL_PASSWORD_ESCAPED="$(printf '%s' "$MYSQL_PASSWORD" | sed 's/"/""/g')"
: "${KNK_DB_HOST:=mysql}"
: "${KNK_DB_PORT:=3306}"
: "${KNK_DB_NAME:=knightsandkings_alpha}"
: "${KNK_DB_USER:=knk_alpha_app}"
export ConnectionStrings__MySqlDbConnection="Server=${KNK_DB_HOST};Port=${KNK_DB_PORT};Database=${KNK_DB_NAME};User ID=${KNK_DB_USER};Password=\"${MYSQL_PASSWORD_ESCAPED}\";Allow User Variables=True;"
export Security__PluginApiKey="$PLUGIN_API_KEY"
export Security__Jwt__Secret="$JWT_SECRET"
# Optional: the Cloudflare API token for the Access list sync. The API reads it only from the environment.
if [ -e /run/secrets/cloudflare_api_token ]; then
    export CloudflareAccess__ApiToken="$(read_secret /run/secrets/cloudflare_api_token cloudflare_api_token)"
fi
unset MYSQL_PASSWORD MYSQL_PASSWORD_ESCAPED PLUGIN_API_KEY JWT_SECRET
exec dotnet /app/knkwebapi_v2.dll
