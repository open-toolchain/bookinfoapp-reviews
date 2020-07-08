#
# hadolint ignore=DL3006
FROM gradle as builder

# hadolint ignore=DL3020
ADD --chown=gradle . /home/gradle/project
WORKDIR /home/gradle/project
RUN gradle clean build

FROM websphere-liberty:javaee8-java11

USER root
# hadolint ignore=DL3005,DL3009
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade
USER default

ENV SERVERDIRNAME reviews

COPY --from=builder /home/gradle/project/reviews-wlpcfg/servers/LibertyProjectServer /opt/ibm/wlp/usr/servers/defaultServer/

RUN /opt/ibm/wlp/bin/installUtility install  --acceptLicense /opt/ibm/wlp/usr/servers/defaultServer/server.xml

# hadolint ignore=DL3025
CMD /opt/ibm/wlp/bin/server run defaultServer
