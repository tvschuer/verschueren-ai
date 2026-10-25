# Statische site: geen build-stap, enkel nginx + de HTML/CSS.
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="verschueren.ai" \
      org.opencontainers.image.description="Statische privésite + OAuth-brandingdocumenten" \
      org.opencontainers.image.source="https://github.com/tvschuer/verschueren-ai"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/

EXPOSE 80
