#!/bin/bash -e

source adapter.sh

check_input() {
  if [ -z "$SOURCE_API_URL" ]; then echo "Missing environment variable: SOURCE_API_URL"; exit 1; fi
  if [ -z "$SOURCE_API_TOKEN" ]; then echo "Missing environment variable: SOURCE_API_TOKEN"; exit 1; fi
  if [ -z "$TARGET_API_URL" ]; then echo "Missing environment variable: TARGET_API_URL"; exit 1; fi
  if [ -z "$TARGET_API_TOKEN" ]; then echo "Missing environment variable: TARGET_API_TOKEN"; exit 1; fi
  if [ -z "$CONFIG_CSV_PATH" ]; then echo "Missing environment variable: CONFIG_CSV_PATH"; exit 1; fi
  if [ "$PLAN_ONLY" != false ]; then PLAN_ONLY=true; fi
}

update_system_machine_image_versions() {
  PLAN="System Machine Image Name, System Machine Image ID, Builder Resource Name, Latest Image"

  get "$TARGET_API_URL"/systemMachineImages "$TARGET_API_TOKEN"
  if [ "$RESPONSE_CODE" != 200 ]; then response_error; fi
  SYSTEM_MACHINE_IMAGES="$RESPONSE"

  IFS=$'\n'
  for system_machine_image in $(cat "$CONFIG_CSV_PATH" | tail -n +2); do
    system_machine_image_name="$(echo $system_machine_image | cut -d "," -f 1)"
    builder_resource_name="$(echo $system_machine_image | cut -d "," -f 2)"
    image_prefix="$(echo $system_machine_image | cut -d "," -f 3)"

    # Get the image builder resource id.
    get "$SOURCE_API_URL"/resources?names="$builder_resource_name" "$SOURCE_API_TOKEN"
    if [ "$RESPONSE_CODE" != 200 ]; then response_error; fi
    builder_resource_id=$(echo "$RESPONSE" | jq ".[0].id")

    # Get the image builder resource version
    get "$SOURCE_API_URL""/versions?resourceIds=""$builder_resource_id""&limit=1&sortBy=createdAt&sortOrder=-1" "$SOURCE_API_TOKEN"
    if [ "$RESPONSE_CODE" != 200 ]; then response_error; fi
    version_name=$(echo "$RESPONSE" | jq -r ".[0].versionName")

    # Find the system machine image ID
    system_machine_image_id=$(echo "$SYSTEM_MACHINE_IMAGES" | jq -r ".[] | select (.name == \"$system_machine_image_name\") | .id")

    if [ "$PLAN_ONLY" == false ]; then
      put "$TARGET_API_URL""/systemMachineImages/""$system_machine_image_id" "$TARGET_API_TOKEN" "{ \"externalId\": \"$image_prefix$version_name\" }"
      if [ "$RESPONSE_CODE" != 200 ]; then response_error; fi
      echo "Updated $system_machine_image_name -> $(echo "$RESPONSE" | jq -r ".externalId")"
    else
      PLAN="$PLAN\n$system_machine_image_name, $system_machine_image_id, $builder_resource_name, $image_prefix$version_name"
    fi
  done

  if [ "$PLAN_ONLY" == true ]; then
    echo -e $PLAN | column -s "," -t
  fi
}

check_input
update_system_machine_image_versions
