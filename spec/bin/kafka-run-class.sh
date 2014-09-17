#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ $# -lt 1 ];
then
  echo "USAGE: $0 classname [opts]"
  exit 1
fi

if [-z "$SCALA_VERSION" ]; then
  SCALA_VERSION=2.8.0
fi

# assume all dependencies have been packaged into one jar with sbt-assembly's task "assembly-package-dependency"
for file in $KAFKA_PATH/core/target/scala-$SCALA_VERSION/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

for file in $KAFKA_PATH/perf/target/scala-$SCALA_VERSION/kafka*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

# classpath addition for release
for file in $KAFKA_PATH/libs/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

for file in $KAFKA_PATH/kafka*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

if [ -z "$KAFKA_JMX_OPTS" ]; then
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false "
fi

if [ -z "$KAFKA_OPTS" ]; then
  KAFKA_OPTS="-Xmx512M -server  -Dlog4j.configuration=file:$KAFKA_PATH/config/log4j.properties"
fi

if [  $JMX_PORT ]; then
  KAFKA_JMX_OPTS="$KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT "
fi

if [ -z "$JAVA_HOME" ]; then
  JAVA="java"
else
  JAVA="$JAVA_HOME/bin/java"
fi

exec $JAVA $KAFKA_OPTS $KAFKA_JMX_OPTS -cp $CLASSPATH "$@"
