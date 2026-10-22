#!/bin/sh
# One-off EF migration run for knk-alpha (KNG-227). Reads the MySQL root password and the JWT
# secret from mounted files (the app's startup checks need the JWT secret even at design time),
# never from arguments, and never prints them.
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

DB_PASSWORD="$(read_secret /run/secrets/mysql_root_password mysql_root_password)"
JWT_SECRET="$(read_secret /run/secrets/jwt_secret jwt_secret)"

DB_PASSWORD_ESCAPED="$(printf '%s' "$DB_PASSWORD" | sed 's/"/""/g')"

: "${KNK_DB_HOST:=mysql}"
: "${KNK_DB_PORT:=3306}"
: "${KNK_DB_NAME:=knightsandkings_alpha}"
: "${KNK_DB_USER:=root}"

export ConnectionStrings__MySqlDbConnection="Server=${KNK_DB_HOST};Port=${KNK_DB_PORT};Database=${KNK_DB_NAME};User ID=${KNK_DB_USER};Password=\"${DB_PASSWORD_ESCAPED}\";Allow User Variables=True;"
export Security__Jwt__Secret="$JWT_SECRET"

unset DB_PASSWORD DB_PASSWORD_ESCAPED JWT_SECRET

cd /src
exec dotnet ef database update --no-build --project knkwebapi_v2.csproj --configuration Release
