#!/usr/bin/env bash

# https://medium.com/bright-days/basic-docker-image-dockerfile-sql-server-with-custom-prefill-db-script-8f12f197867a

script_dir=$(readlink -f $(dirname $0))
. "$script_dir/../library.sh"

. "$script_dir/env.sh"
if [[ -f "$script_dir/../../docker-env.sh" ]]; then
    . "$script_dir/../../docker-env.sh"
fi

instance_name="mssql-$MSSQL_VERSION"
if [[ ! -z "$DOCKER_PROJECT" ]]; then
  pname=$(echo "$DOCKER_PROJECT" | tr '[:upper:]' '[:lower:]')
  instance_name="$pname-mssql-$MSSQL_VERSION"
fi

instace=$(docker_ls | grep ^$instance_name)
id=$(echo $instace | cut -d';' -f2)
running=false
if [[ "$(echo $instace | cut -d';' -f3)" == "running" ]]; then
  running=true
fi

# this is a windows docker work around for mount paths
MSSQL_DATA_DIR=$(normalize_windows_path "$MSSQL_DATA_DIR")

cat <<-EOF
CONFIG
================================================================================
MSSQL_VERSION:           $MSSQL_VERSION
MSSQL_LISTEN_PORT:       $MSSQL_LISTEN_PORT
MSSQL_SA_PASSWORD:       $MSSQL_SA_PASSWORD
MSSQL_DATA_DIR:          $MSSQL_DATA_DIR
MSSQL_RESET_STATE_DATA:  $MSSQL_RESET_STATE_DATA
================================================================================

EOF

# stop if it's running
if [[ $running == true ]]; then
  echo "Stopping running instance ..."
  docker container stop "$instance_name" >/dev/null || true
fi

# try to remove if it exists and has to be recycled
if [[ $MSSQL_RESET_STATE_DATA == true ]] && [[ ! -z "$id" ]]; then
  echo "Deleting existing instance ..."
  docker container rm "$instance_name" >/dev/null 2>/dev/null || true
fi

# create container and import data if we:
# - do not recycle (reuse old state data) or ...
# - if the instance does not yet exist
if [[ $MSSQL_RESET_STATE_DATA == true ]] || [[ -z "$id" ]]; then
  echo "Starting fresh instance ..."
  id=$(docker run --name "$instance_name" \
      --detach \
      -p $MSSQL_LISTEN_PORT:1433 \
      -e 'TZ=Europe/Zurich' \
      -e "MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD" \
      -e 'ACCEPT_EULA=Y' \
      -v "$MSSQL_DATA_DIR":/src/import \
      mssql-provider-$MSSQL_VERSION )
else
  echo "Starting existing instance ..."
  out=$(docker start "$instance_name")
fi

echo docker run --name "$instance_name" \
      --detach \
      -p $MSSQL_LISTEN_PORT:1433 \
      -e 'TZ=Europe/Zurich' \
      -e "MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD" \
      -e 'ACCEPT_EULA=Y' \
      -v "$MSSQL_DATA_DIR":/src/import \
      mssql-provider-$MSSQL_VERSION

cat <<-EOF

================================================================================
MSSQL $MSSQL_VERSION is starting, you can access the service here:

Instance Id:   $id
Instance Name: $instance_name
SA:            $MSSQL_SA_PASSWORD
port:          $MSSQL_LISTEN_PORT
PID:           Developer

Connect String:
"Server=localhost,:$MSSQL_LISTEN_PORT;Database=eTest;Integrated Security=false;\
User Id=sa;password=$MSSQL_SA_PASSWORD;Trusted_Connection=False;\
MultipleActiveResultSets=true;"


EOF

if [[ $MSSQL_RESET_STATE_DATA == true ]]; then
cat <<-EOF

With every reload, realm data is imported from this folder:
$MSSQL_DATA_DIR

Set \$MSSQL_RESET_STATE_DATA=false in docker_env.sh to disable this
behaviour.

EOF
fi