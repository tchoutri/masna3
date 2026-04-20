# libpq-compatible connection string
export MASNA3_DB_HOST="masna3-database"
export MASNA3_DB_PORT="5432"
export MASNA3_DB_USER="postgres"
export MASNA3_DB_PASSWORD="postgres"
export PGPASSWORD=${MASNA3_DB_PASSWORD}
export MASNA3_DB_DATABASE="masna3_dev"

export MASNA3_DB_CONNSTRING="host=${MASNA3_DB_HOST} dbname=${MASNA3_DB_DATABASE} port=${MASNA3_DB_PORT} \
  user=${MASNA3_DB_USER} password=${MASNA3_DB_PASSWORD}"

export JOBS_DB_CONNSTRING=$MASNA3_DB_CONNSTRING

# Number of connections across all sub-pools
export MASNA3_DB_POOL_CONNECTIONS="50"
#Timeout for each connection
export MASNA3_DB_TIMEOUT="10"
# `true` if the service is deployed somewhere, `false` for local development / tests
export MASNA3_DEPLOYED="false"
# URL domain
export MASNA3_DOMAIN="localhost"
# HTTP port
export MASNA3_HTTP_PORT="8085"
# Where do the logs go
export MASNA3_LOGGING_DESTINATION="stdout"
# Is Prometheus metrics export enabled (default false)
export MASNA3_PROMETHEUS_ENABLED="true"
# Public key for Biscuit authorisation
export MASNA3_PUBLIC_KEY="13febd37461779105379c813e826bceeb0098347bef0e4799b3e998f9cfb51f3"
# Secret key for Biscuit authorisation
export MASNA3_SECRET_KEY="b17b436d9e2b60028a2a6bc58b5a4223c4927c829408d37ee82fc358b92166b1"
# Is Zipkin trace collection enabled? (default false)
export MASNA3_ZIPKIN_ENABLED="false"
# The hostname of the Zipkin collection agent
export MASNA3_ZIPKIN_AGENT_HOST="localhost"
# The port of the Zipkin collection agent
export MASNA3_ZIPKIN_AGENT_PORT="8028"

export MASNA3_AWS_KEY_ID="fake-key-id"

export MASNA3_AWS_SECRET_KEY="fake-id"

export MASNA3_AWS_REGION="Paris"

export MASNA3_AWS_BUCKET="masna3-dev"
# Allowed Origins for CORS
export MASNA3_ALLOWED_ORIGINS="http://localhost:1234"

export DOCKER_BUILDKIT=1
