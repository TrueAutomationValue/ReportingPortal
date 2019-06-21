FROM alpine/git as clone
WORKDIR /app
RUN git clone https://github.com/VladislavKostyukevich/rbback.git
RUN git clone https://github.com/VladislavKostyukevich/rpfront.git

FROM maven:3.5-jdk-8-alpine as build-back
COPY --from=clone /app/rbback /app
WORKDIR /app
ARG DB_USER=root
ARG DB_PASS
RUN mvn package -f pom.xml  -P !run-migration -Ddb.username="$DB_USER" -Ddb.password="$DB_PASS" -Ddb.host=db -Ddb.publicPort=3306 -Ddb.port=3306 -Ddb.publicHost=db

FROM node:10-alpine as build-front
WORKDIR /app
COPY --from=clone /app/rpfront /app
RUN apk add --no-cache git
RUN npm i
RUN npm run build:prod

FROM maven:3.5-jdk-8-alpine as results
WORKDIR /result/back
COPY --from=build-back /app /result/back/
COPY --from=build-back /app/target/api.war /result/webapps/
COPY --from=build-front /app/dist/ /result/webapps/ROOT/
ARG DB_USER=root
ARG DB_PASS
ENV DB_USER root
ENV DB_PASS ${DB_PASS}
CMD mvn resources:resources liquibase:update -Ddb.username=${DB_USER} -Ddb.password=${DB_PASS} -Ddb.host=db -Ddb.publicPort=3306 -Ddb.port=3306 -Ddb.publicHost=db ; cp -r /result/webapps/ /app
