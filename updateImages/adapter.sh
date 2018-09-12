# Source this where required.
RESPONSE_FILE=/tmp/response

request() {
  REQUEST_TYPE="$1"
  URL="$2"
  AUTHORIZATION_HEADER="$3"
  DATA="$4"

  {
    RESPONSE_CODE=$(curl \
      -H "Content-Type: application/json" \
      -H "Authorization: $AUTHORIZATION_HEADER" \
      -X "$REQUEST_TYPE" "$URL" \
      -d "$DATA" \
      --silent \
      --write-out "%{http_code}\n" \
      --output $RESPONSE_FILE \
    )
  } || {
    ERROR=$(echo $?)
  }
  RESPONSE=$(cat $RESPONSE_FILE)
  rm $RESPONSE_FILE
}

# get <url> <authorization>"
get() {
  echo "GET $1"
  request "GET" "$1" "$2"
}

# put <url> <authorization> <body>
put() {
  echo "PUT $1"
  request "PUT" "$1" "$2" "$3"
}

response_error() {
  echo "|__ Failure"
  echo "    |__ Status Code: $RESPONSE_CODE"
  echo "    |__ Response: $RESPONSE"
  exit 1
}
