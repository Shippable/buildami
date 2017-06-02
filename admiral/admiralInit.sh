#!/bin/bash -e

readonly ADMIRAL_DIR=/home/ubuntu/admiral
readonly ADMIRAL_REPO=https://github.com/Shippable/admiral.git
readonly CONFIG_DIR=/etc/shippable
readonly RUNTIME_DIR=/var/lib/shippable
readonly ADMIRAL_IP=127.0.0.1
readonly ADMIRAL_ENV=$CONFIG_DIR/admiral.env
readonly DB_IP=$ADMIRAL_IP
readonly DB_PORT=5432

__run_update() {
  sudo apt update
}

__print_runtime() {
  echo "Runtime env variables"
  echo "=================================================="
  echo "=================================================="
  echo "ADMIRAL_DIR: $ADMIRAL_DIR"
  echo "ADMIRAL_REPO: $ADMIRAL_REPO"
  if [ -z "$ACCESS_KEY" ] || [ "$ACCESS_KEY" == "" ]; then
    echo "ERROR!!! Missing ACCESS_KEY environment variable"
    exit 1
  else
    echo "ACCESS_KEY: $ACCESS_KEY"
  fi

  if [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" == "" ]; then
    echo "ERROR!!! Missing SECRET_KEY environment variable"
    exit 1
  else
    echo "SECRET_KEY : $SECRET_KEY "
  fi

  echo "=================================================="
  echo "=================================================="
}

__install_deps() {
  echo "Installing dependencies"
  __run_update

  sudo apt install -y git-core

  echo "Upgrading kernel"
  sudo apt install -y linux-generic-lts-vivid
}

__clone_admiral() {
  echo "Cloning Admiral"
  sudo rm -rf $ADMIRAL_DIR
  sudo mkdir -p $ADMIRAL_DIR
  sudo git clone --depth=1 $ADMIRAL_REPO $ADMIRAL_DIR
}

__update_env() {
  echo "Updating admiral.env"
  sudo mkdir -p $CONFIG_DIR

  local env_template=$ADMIRAL_DIR/common/scripts/configs/admiral.env.template
  sudo cp -vr $env_template $ADMIRAL_ENV

  echo "Admiral env created, updating values"

  echo "Updating ADMIRAL_IP: $ADMIRAL_IP"
  sudo sed -i 's#.*ADMIRAL_IP=.*#ADMIRAL_IP="'$ADMIRAL_IP'"#g' $ADMIRAL_ENV

  echo "Updating ACCESS_KEY: $ACCESS_KEY"
  sudo sed -i 's#.*ACCESS_KEY=.*#ACCESS_KEY="'$ACCESS_KEY'"#g' $ADMIRAL_ENV

  echo "Updating SECRET_KEY: $SECRET_KEY"
  sudo sed -i 's#.*SECRET_KEY=.*#SECRET_KEY="'$SECRET_KEY'"#g' $ADMIRAL_ENV

  echo "Updating DB_IP: $DB_IP"
  sudo sed -i 's#.*DB_IP=.*#DB_IP="'$DB_IP'"#g' $ADMIRAL_ENV

  echo "Updating DB_PORT: $DB_PORT"
  sudo sed -i 's#.*DB_PORT=.*#DB_PORT="'$DB_PORT'"#g' $ADMIRAL_ENV

  local temp_db_password="testing1234"
  echo "Updating DB_PASSWORD: $temp_db_password"
  sudo sed -i 's#.*DB_PASSWORD=.*#DB_PASSWORD="'$temp_db_password'"#g' $ADMIRAL_ENV

  echo "admiral.env"
  cat $ADMIRAL_ENV
}

__install() {
  echo "Running admiral installation"
  cd $ADMIRAL_DIR
  sudo ./admiral.sh install --silent
}

__setup_upstart() {
  echo "Copying upstart script"
  sudo cp -vr $ADMIRAL_DIR/common/scripts/admiral.conf /etc/init/admiral.conf

  echo "Copyting init script"
  sudo cp -vr $ADMIRAL_DIR/common/scripts/admiralInit.sh /etc/shippable/admiralInit.sh
}

__clear_secrets() {
  echo "Clearing secrets from admiral.env"

  echo "Clearing ADMIRAL_IP"
  sudo sed -i 's#.*ADMIRAL_IP=.*#ADMIRAL_IP=""#g' $ADMIRAL_ENV

  echo "Clearing ACCESS_KEY"
  sudo sed -i 's#.*ACCESS_KEY=.*#ACCESS_KEY=""#g' $ADMIRAL_ENV

  echo "Clearing SECRET_KEY"
  sudo sed -i 's#.*SECRET_KEY=.*#SECRET_KEY=""#g' $ADMIRAL_ENV

  echo "Clearing DB_IP"
  sudo sed -i 's#.*DB_IP=.*#DB_IP=""#g' $ADMIRAL_ENV

  echo "Clearing DB_PASSWORD"
  sudo sed -i 's#.*DB_PASSWORD=.*#DB_PASSWORD=""#g' $ADMIRAL_ENV

  echo "Clearing LOGIN_TOKEN"
  sudo sed -i 's#.*LOGIN_TOKEN=.*#LOGIN_TOKEN=""#g' $ADMIRAL_ENV

  echo "Updating DB install status"
  sudo sed -i 's#.*DB_INSTALLED=.*#DB_INSTALLED=false#g' $ADMIRAL_ENV

  sudo rm -rf $RUNTIME_DIR/db
}

__stop_services() {
  echo "Stopping services"

  echo "Stopping admiral"
  sudo docker rm -fv admiral || true


  echo "Stopping database"
  sudo docker rm -f db || true

}

main() {
  echo "Bootstrapping AMI to install Admiral"
  __print_runtime
  __install_deps
  __clone_admiral
  __update_env
  __install
  __setup_upstart
  __clear_secrets
  __stop_services
  echo "Admiral installation complete"
}

main
