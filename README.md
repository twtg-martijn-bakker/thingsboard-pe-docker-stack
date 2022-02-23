# Thingsboard stack for TWTG

based off of [this git repository](https://github.com/thingsboard/thingsboard-pe-docker-compose.git)

## Quick start
1. Create / update `thingsboard-license.env`: _TODO_
2. generate `docker-compose.yml`:
```sh
make docker-compose.yml
```
3. Log in to Docker Hub for access to store items
  * Fill in your Docker Hub credentials when asked.
  * You will only need to do this once.

  ```sh
docker login
```
4. Pull all images
```sh
docker-compose pull
```
5. Start the stack:
```sh
docker-compose up -d
```

## Differences with existing stack (planned)
* make use of docker-compose's `network.alias` to assign roles to services / use single haproxy config for any scenario.
* less duplication of code

## Known deviations
* "advanced" deployment strategy only has 1 instance of tb-core etc.
*

## TODO
* [X] cover all deployments strategies from original repo
  * [X] monolith
  * [X] basic
  * [X] advanced
* [X] "hybrid" (adds cassandra for time-series)
* [X] "monitoring" (adds prometheus and grafana)
    [ ] add `/etc/grafana/provisioning/` somehow
* [X] transports
  * [X] HTTP
  * [X] MQTT
  * [X] LWM2M
  * [X] COAP
  * [X] SNMP
* [ ] Queues
  * [ ] Kafka _(done for monolith and advanced)_
  * [ ] RabbitMQ _(done for advanced)_
  * [ ] Confluent
  * [ ] AWS SQS
  * [ ] Google Cloud Pub/Sub
  * [ ] Azure Service-bus

## Notes on TB-provided stack

### ports
port/proto | service | published / proxied | method | description
- | - | - | - | -
7070/tcp | tb-core | 7070/tcp (via haproxy) | TCP | Edges RPC in
8080/tcp | tb-core | 80 (via haproxy) | HTTP:`/api/*` | tb-api-backend
|| 443 (via haproxy) | HTTPS:`/api/*` | tb-api-backend
8080/tcp | tb-rule-engine | - | | ?
8080/tcp | tb-web-ui | 80 (via haproxy) | HTTP:`/` | TB web frontend
|| 443 (via haproxy) | HTTPS:`/` | TB web frontend
8383/tcp | tb-web-report | 8383 (via haproxy) | HTTP:`/` | Web reporting engine (?)
1883/tcp | tb-mqtt-transport | 1883 (via haproxy) | TCP | MQTT transport
8081/tcp | tb-http-transport | 80 (via haproxy) | HTTP:`/api/v1/*` | HTTP transport
|| 443 (via haproxy) | HTTPS:`/api/v1/*` | HTTP transport
5683/udp | tb-coap-transport | 5683/udp | direct | CoAP transport
5685/udp | tb-lwm2m-transport | 5685/udp | direct | LWM2M transport
2181/tcp | zookeeper | - | - | Zookeeper
6379/tcp | redis | - | - | Redis 4.x
9092/tcp | kafka | 9092/tcp | direct | Kafka message broker / queues
5432/tcp | postgres | - | - | Postgresql database
9042/tcp | cassandra | - | - | Cassandra time-series database
9090/tcp | prometheus | 9090/tcp | direct | Prometheus
3000/tcp | grafana | 3000/tcp | direct | Grafana dashboarding
9999/tcp | haproxy | 9999/tcp | HTTP:`/stats/` | haproxy stats

### HAProxy load balancer
* All ports in column 1 are published except for 8383/tcp
* rules for HTTP -> HTTPS redirect on port 80 (all must be true)
  - if not letsencrypt
  - if not a request to `/api/v1/**`
  - if the `FORCE_HTTPS_REDIRECT` env var is "true"

port/proto | path | to service | to port | frontend | backend
- | - | - | - | - | -
80/tcp | /.well-known/acme-challenge/ | | | http-in | letsencrypt_http
| /api/v1/,<br>**!** /api/v1/integrations | tb-http-transport | 8081 | | tb-http-backend
| /api/ | tb-core | 8080 | | tb-api-backend
| / | tb-web-ui | 8080 | | tb-web-backend
443/tcp | /api/v1/,<br>**!** /api/v1/integrations | tb-http-transport | 8081 | https_in | tb-http-backend
| /api/ | tb-core | 8080 | | tb-api-backend
| / | tb-web-ui | 8080 | | tb-web-backend
8383/tcp | / | tb-web-report | 8383 | web-report-in | tb-web-report-backend
1883/tcp | | tb-mqtt-transport | 1883 | mqtt-in | (mode tcp)
7070/tcp | | tb-core | 7070 | edges-rpc-in | (mode tcp)
9999/tcp | /stats | | | stats | (stats enable)


### Monolith vs basic vs advanced
#### monolith
* service `tb-monolith` implements:
  * tb-core
  * tb-web-ui
  * tb-rule-engine
  * tb-http-transport
  * tb-mqtt-transport
  * tb-lwm2m-transport
  * tb-coap-transport
  * tb-snmp-transport

#### basic
* service `tb-monolith` implements:
  * tb-core
  * tb-web-ui
  * tb-rule-engine
* service `tb-http-transport` is separate
* service `tb-mqtt-transport` is separate
* service `tb-lwm2m-transport` is separate
* service `tb-coap-transport` is separate
* service `tb-snmp-transport` is separate

#### advanced
* service `tb-core` is separate
* service `tb-web-ui` is separate
* service `tb-rule-engine` is separate
* service `tb-http-transport` is separate
* service `tb-mqtt-transport` is separate
* service `tb-lwm2m-transport` is separate
* service `tb-coap-transport` is separate
* service `tb-snmp-transport` is separate
