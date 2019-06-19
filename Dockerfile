FROM gradle as builder

ADD --chown=gradle . /home/gradle/project
WORKDIR /home/gradle/project
RUN gradle clean build

FROM websphere-liberty:19.0.0.4-javaee8

# WORKDIR reviews-wlpcfg
ENV SERVERDIRNAME reviews

COPY --from=builder /home/gradle/project/reviews-wlpcfg/servers/LibertyProjectServer /opt/ibm/wlp/usr/servers/defaultServer/
# ADD ./servers/LibertyProjectServer /opt/ibm/wlp/usr/servers/defaultServer/

RUN /opt/ibm/wlp/bin/installUtility install  --acceptLicense /opt/ibm/wlp/usr/servers/defaultServer/server.xml

ARG service_version
#MK ARG enable_ratings
#MK ARG star_color
ENV SERVICE_VERSION ${service_version:-v1}
#MK ENV ENABLE_RATINGS ${enable_ratings:-false}
#MK ENV STAR_COLOR ${star_color:-black}

CMD /opt/ibm/wlp/bin/server run defaultServer

