FROM gradle as builder

ADD --chown=gradle . /home/gradle/project
WORKDIR /home/gradle/project
RUN gradle clean build

FROM websphere-liberty:javaee8-java11

USER root
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade
USER default

ENV SERVERDIRNAME reviews

COPY --from=builder /home/gradle/project/reviews-wlpcfg/servers/LibertyProjectServer /opt/ibm/wlp/usr/servers/defaultServer/

RUN /opt/ibm/wlp/bin/installUtility install  --acceptLicense /opt/ibm/wlp/usr/servers/defaultServer/server.xml

CMD /opt/ibm/wlp/bin/server run defaultServer
