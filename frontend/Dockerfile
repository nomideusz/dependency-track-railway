FROM dependencytrack/frontend:5.1.1

# Serves the UI and proxies /api to the API server over Railway's private
# network, so the browser and CI pipelines use one URL.
COPY default.conf.template /etc/nginx/templates/default.conf.template
# Lets the template use Railway's internal DNS server for the API's address.
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1
USER root
# `auto` starts one worker per host CPU, 48 on Railway. Access logs off: every
# asset and API call would fill the log view.
RUN sed -i 's/^worker_processes .*/worker_processes 2;/; s#^\(\s*\)access_log .*#\1access_log off;#' /etc/nginx/nginx.conf
USER 101
