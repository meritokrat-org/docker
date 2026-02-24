#!/bin/bash
set -e

export PGPASSWORD=RRcylF0M
export POSTGRES_HOST=postgres
export POSTGRES_DB=meritokrat
export POSTGRES_USER=meritokrat

declare dataStore=aistor
declare hostDir
declare remoteDir=${dataStore}/backups
declare hostFile
declare remoteFile
declare filename
declare credentialsFile=/credentials.json
declare debugMode=1

main() {
  hostDir="$(mktemp -d /tmp/bkppr.XXXXXX)"

  test -e "${credentialsFile}" || {
    echo -e "\e[31m[ERROR]: ${credentialsFile}: The credentials file doesn't exist.\e[0m"
    exit 1
  }

  case "$1" in
    init) init ;;
    backup) backup ;;
    restore) restore ;;
  esac
}

key() {
  jq -r ."$1" ${credentialsFile}
}

last_backup() {
  local status

  status="$(mc alias list --json ${dataStore} | jq -r '.status')"
  [[ "$status" == "success" ]] &&
    mc ls --json ${remoteDir}/ |
    jq -sr 'sort_by(.lastModified) | .[-1:] | .[]?.key'
}

backup_file() {
  export filename="$1"
  export hostFile="${hostDir}/${filename}"
  export remoteFile="${remoteDir}/${filename}"

  [[ ${debugMode} -eq 1 ]] && cat <<EOL
  ${filename}
    Host file:   ${hostFile}
    Remote file: ${remoteFile}
EOL
}

init() {
  local url accessKey secretKey api path

  url="$(key url)"
  accessKey="$(key accessKey)"
  secretKey="$(key secretKey)"
  api="$(key api)"
  path="$(key path)"

  [[ ${debugMode} -eq 1 ]] && cat <<EOL
  ${url}
    Access Key:   ${accessKey}
    Secret key:   ${secretKey}
    Api option:   ${api}
    Path option:  ${path}
EOL

  mc alias set \
    "${dataStore}" \
    "${url}" \
    "${accessKey}" \
    "${secretKey}" \
    --api "${api}" \
    --path "${path}"
}

size() {
  gzip -l "${hostFile}" |
    jq -sRr 'trim | split("\\s+"; "x") | .[-3:][0]'
}

restore() {
  backup_file "$(last_backup)"
  mc get "${remoteFile}" "${hostFile}"
  pv -petraf "${hostFile}" |
    pg_restore -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} \
      >/var/log/pg_restore.log 2>&1
  rm -rf "${hostDir}"
}

backup() {
  backup_file "${POSTGRES_DB}_pgsql.$(date +'%y%m%dT%H%M%S').dump"
  pg_dump -Fc \
    -h ${POSTGRES_HOST} \
    -U ${POSTGRES_USER} \
    -d ${POSTGRES_DB} |
    pv -petraf >"${hostFile}"
  mc put "${hostFile}" "${remoteDir}/" #--parallel 8 --part-size 20MiB
  rm -rf "${hostDir}"
}

main "$@"
