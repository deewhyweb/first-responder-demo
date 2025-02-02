# First Responder Demo

The First Responder Demo application is meant to act as a test application for gauging the impact of OpenTelemetry tracing on a 
typical WildFly/EAP workload. The application is still in early stages, so more details on the performance tests -- the results, how
to run them locally, etc -- will be added soon.

### Setting up WildFly
To download and install WildFly, copy and paste the following into your shell:
``` 
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.5/postgresql-42.2.5.jar
wget https://github.com/wildfly/wildfly/releases/download/26.1.1.Final/wildfly-26.1.1.Final.zip
unzip -q wildfly-26.1.1.Final.zip
wildfly-26.1.1.Final/bin/standalone.sh
wildfly-26.1.1.Final/bin/jboss-cli.sh -c << EOF
batch
/extension=org.wildfly.extension.microprofile.reactive-messaging-smallrye:add
/extension=org.wildfly.extension.microprofile.reactive-streams-operators-smallrye:add
/subsystem=microprofile-reactive-streams-operators-smallrye:add
/subsystem=microprofile-reactive-messaging-smallrye:add
module add --name=org.postgres --resources=postgresql-42.2.5.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=postgres:add(driver-name="postgres",driver-module-name="org.postgres",driver-class-name=org.postgresql.Driver)
data-source add --jndi-name=java:/FRDemoDS --name=FRDemoDS --connection-url=jdbc:postgresql://localhost/frdemo --driver-name=postgres --user-name=frdemo --password=frdemo
run-batch
reload
EOF
```

### Starting Kafka
To download and install Kafka, perform the steps below. For more information on Kafka, see the
[Apache Kafka Quickstart](https://kafka.apache.org/quickstart).
```
$ wget https://dlcdn.apache.org/kafka/3.2.1/kafka_2.13-3.2.1.tgz
$ tar xf kafka_2.13-3.2.1.tgz
$ cd kafka_2.13-3.2.1.tgz
(In separate terminal windows/tabs)
$ bin/zookeeper-server-start.sh config/zookeeper.properties
$ bin/kafka-server-start.sh config/server.properties
(This next is optional)
$ bin/kafka-console-consumer.sh --topic IncidentReportedEvent --from-beginning --bootstrap-server localhost:9092
```

### Deploying the application

```
$ mvn clean install wildfly:deploy
```

### Arquillian tests

The First Responder Demo has a number of basic integration tests using [Arquillian](https://arquillian.org/). The tests and coverage
are not exhaustive, but are meant to be a quick check of the application's basic functionality. To make running these tests as simple
as possible, PostgreSQL and Kafka are managed in Docker containers via the [testcontainers](https://testcontainers.org) project, so
a [working Docker/Podman environment will be required](https://www.testcontainers.org/supported_docker_environment/).

To run the tests, execute this command:

```
mvn clean compile verify -Parq-managed 
```

## OpenShift deployment

### Backend service and dependencies

Create a new project

``` oc new-project erdemo ```

Create postgresql database by running the following

``` oc apply -f ./deploy/openshift/resources/psql.yml ```

Deploy AMQ streams operator

``` oc apply -f ./deploy/openshift/operators/amq-operator.yml ```

Wait for the operators to to be deployed (waiting until their ClusterServiceVersion's PHASE is set to Suceeded)

```oc get csv -w```

Once they are installed, it will display:

```
NAME                  DISPLAY       VERSION   REPLACES              PHASE
amqstreams.v2.3.0-3   AMQ Streams   2.3.0-3   amqstreams.v2.3.0-2   Succeeded

```

Create AMQ streams cluster called frdemo

``` oc apply -f ./deploy/openshift/resources/amq-cluster.yml ```

create config map from cm.yml

``` oc apply -f ./deploy/openshift/apps/backend-cm.yml ```

From the developer UI, click on "+Add", then "Helm Chart", and select the "JBoss EAP XP 4" Helm chart.

Paste the contents of deploy/openshift/apps/backend-helm.yml as the config.

Wait for the application image to be built

```
oc get build -w
The application image is built when the eap74-2 build is complete:

NAME                      TYPE     FROM          STATUS    STARTED         DURATION
eap-xp4-2                   Docker   Dockerfile    Complete   About a minute ago   1m2s

```

Deploy the JBoss EAP operator

``` oc apply -f ./deploy/openshift/operators/eap-operator.yml ```

Wait for the operators to to be deployed (waiting until their ClusterServiceVersion's PHASE is set to Suceeded)

```oc get csv -w```

Once they are installed, it will display:

```
NAME                  DISPLAY       VERSION   REPLACES              PHASE
eap-operator.v2.3.10  JBoss EAP    2.3.10   eap-operator.v2.3.9   Succeeded

```

Deploy the backend application

``` oc apply -f ./deploy/openshift/apps/deploy-backend.yml ```

### Console and dependencies

Create config from console-cm.yml

``` oc apply -f ./deploy/openshift/apps/console-cm.yml ```

Deploy console with deploy-console.yml

``` oc apply -f ./deploy/openshift/apps/deploy-console.yml ```