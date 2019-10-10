#use multi build stage, this step below to build the project
FROM java:8-jdk-alpine AS build

# Install Maven
RUN apk add --no-cache curl tar bash
ARG MAVEN_VERSION=3.3.9
ARG USER_HOME_DIR="/root"
RUN mkdir -p /usr/share/maven && \
curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1 && \
ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

ENTRYPOINT ["/usr/bin/mvn"]

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY pom.xml /usr/src/app
RUN mvn -T 1C install && rm -rf target

COPY src /usr/src/app/src

#this build below to build the image, copy only the file that we needed to our image
FROM openjdk:8-jdk-alpine

ARG DEPENDENCY=/usr/src/app

COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
COPY --from=build ${DEPENDENCY}/config.properties /app/
COPY --from=build ${DEPENDENCY}/src /app/src

EXPOSE 8080

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080 || exit 1

ENTRYPOINT ["java","-cp","app:app/lib/*","your.Application"]