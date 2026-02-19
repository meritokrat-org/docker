#!/bin/bash
set -e

exec "$@"
exit

# Простий CLI для backup'у PostgreSQL та MySQL
# Підтримка збереження на Google Drive через rclone
# Використання:
#   backupper pg_dump dbname user host output_file [gdrive:folder]
#   backupper mysql_dump dbname user host output_file [gdrive:folder]

destDir="$(mktemp -d /tmp/bkppr.XXXXXX)"
originFile="$(rclone lsjson xdrive: --files-only --max-depth 2 | jq -r 'sort_by(.ModTime) | .[-1:][] | .Path')"
targetFile="${destDir}/${originFile#**/}"

echo rclone copy xdrive:"${originFile}" "${targetFile}"
#gunzip -c "${destDir}/${originFile}" | psql -d meritokrat

#
#COMMAND=$1
#DB_NAME=$2
#DB_USER=$3
#DB_HOST=$4
#OUTPUT_FILE=$5
#REMOTE_PATH=$6 # Наприклад: gdrive:backups
#
#if [[ -z "$COMMAND" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_HOST" || -z "$OUTPUT_FILE" ]]; then
#  echo "Usage:"
#  echo "  backupper pg_dump <dbname> <user> <host> <output_file> [gdrive:folder]"
#  echo "  backupper mysql_dump <dbname> <user> <host> <output_file> [gdrive:folder]"
#  exit 1
#fi
#
#case "$COMMAND" in
#  # download > untar  > import
#  -d | --deploy)
#
#    #    rclone lsjson xdrive:mysql --files-only
#    #    rclone lsjson xdrive:meritokrat-2026_02_16_05_26_40-pgsql.zip/ --files-only --max-depth 2 | jq
#    ;;
#
#  # export > tar > uploadZ
#  -b | --backup) ;;
#
#esac
#
## Робимо дамп
#case "$COMMAND" in
#  pg_dump)
#    echo "Backing up PostgreSQL database '$DB_NAME' from $DB_HOST..."
#    PGPASSWORD="${PGPASSWORD:-}" pg_dump -U "$DB_USER" -h "$DB_HOST" -F c "$DB_NAME" >"$OUTPUT_FILE"
#    ;;
#  mysql_dump)
#    echo "Backing up MySQL database '$DB_NAME' from $DB_HOST..."
#    mysqldump -u"$DB_USER" -h"$DB_HOST" -p"${MYSQL_PWD:-}" "$DB_NAME" >"$OUTPUT_FILE"
#    ;;
#  *)
#    echo "Unknown command: $COMMAND"
#    exit 1
#    ;;
#esac
#
#echo "Backup saved locally to $OUTPUT_FILE"
#
## Завантажуємо на Google Drive, якщо вказано
#if [[ -n "$REMOTE_PATH" ]]; then
#  echo "Uploading $OUTPUT_FILE to $REMOTE_PATH..."
#  rclone copy "$OUTPUT_FILE" "$REMOTE_PATH" --progress
#  echo "Upload completed."
#fi
