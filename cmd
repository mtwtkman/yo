#! /bin/sh

d="docker-compose"
dexec="${d} exec"
webexec="${dexec} -u `id -u`:`id -g` web"
drun="${d} run --rm -ti"
cmd=$1
shift
run_cmd() {
  echo "$@"
  eval "$@"
}
case $cmd in
  diesel) run_cmd "${webexec} diesel $@";;
  migration) ./cmd diesel migration $@;;
  m:gen) ./cmd migration generate $@;;
  m:run) ./cmd migration run;;
  m:redo) ./cmd migration redo;;
  psql) run_cmd "${dexec} -u postgres db psql";;
  *) $cmd $@;;
esac
