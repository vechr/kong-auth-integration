FROM kong/kong-gateway:latest

COPY ./config/kong.conf /etc/kong/

USER root

RUN apt-get update && apt-get install curl -y

# Add custom plugin to the image
COPY ./ /usr/local/bin/kong-auth-integration

WORKDIR /usr/local/bin/kong-auth-integration

RUN luarocks make

RUN luarocks list

ENV KONG_PLUGINS=bundled,kong-auth-integration

WORKDIR /

# Ensure kong user is selected for image execution
USER kong

# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8001 8001 8003 8004
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "start", "-c", "/etc/kong/kong.conf", "--vv"]
