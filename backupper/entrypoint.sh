#!/usr/bin/env bash

backupper init

if [[ $1 = @(init|restore|backup) ]]; then
  backupper "${1}"
  exit 0
fi

exec "$@"
