#!/bin/bash -e

readonly CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly EXEC_IMAGE_NAME="shipimg/genexec"

# Indicates whether the script has succeeded
export is_success=false

# Indicates if docker service should be restarted
export docker_restart=false

#
# Prints the command start and end markers with timestamps
# and executes the supplied command
#
exec_cmd() {
  cmd=$@
  cmd_uuid=$(python -c 'import uuid; print str(uuid.uuid4())')
  cmd_start_timestamp=`date +"%s"`
  echo "Running $cmd"
  eval $cmd
  cmd_status=$?
  if [ "$2" ]; then
    echo $2;
  fi

  cmd_end_timestamp=`date +"%s"`
  if [ $cmd_status == 0 ]; then
    echo "Completed $cmd"
    return $cmd_status
  else
    echo "Failed $cmd"
    exit 99
  fi
}

exec_grp() {
  group_name=$1
  group_uuid=$(python -c 'import uuid; print str(uuid.uuid4())')
  group_start_timestamp=`date +"%s"`
  echo "Starting $group_name"
  eval "$group_name"
  group_status=$?
  group_end_timestamp=`date +"%s"`
  echo "Completed $group_name"
}

_run_update() {
  is_success=false
  update_cmd="sudo apt-get update"
  exec_cmd "$update_cmd"
}

install_prereqs() {
  echo "Installing prerequisite binaries"
  _run_update
  is_success=true
}

parse_release_version() {
  echo "Most recent release version is : $REL_VER"
  readonly EXEC_IMAGE_NAME_WITH_TAG="$EXEC_IMAGE_NAME:$REL_VER"
  is_success=true
}

cleanCEXEC() {
  is_success=false
  if [ -d "$CEXEC_LOCATION_ON_HOST" ]; then
    exec_cmd "sudo rm -rf $CEXEC_LOCATION_ON_HOST"
  fi
  is_success=true
}

cloneCEXEC() {
  is_success=false
  exec_cmd "sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOCATION_ON_HOST"
  is_success=true
}

pull_exec() {
  is_success=false
  exec_cmd "sudo docker pull $EXEC_IMAGE_NAME_WITH_TAG"
  is_success=true
}

before_exit() {
  if [ "$is_success" == true ]; then
    echo "__SH__SCRIPT_END_SUCCESS__";
  else
    echo "__SH__SCRIPT_END_FAILURE__";
  fi
}

main() {
  trap before_exit EXIT
  exec_grp "install_prereqs"

  trap before_exit EXIT
  exec_grp "parse_release_version"

  trap before_exit EXIT
  exec_grp "cleanCEXEC"

  trap before_exit EXIT
  exec_grp "cloneCEXEC"

  trap before_exit EXIT
  exec_grp "pull_exec"
pwd
}

main
echo "AMI init script completed"
