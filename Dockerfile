# Statische site: geen build-stap, enkel nginx + de HTML/CSS.
# De repo-root is tegelijk de site-root, zodat GitHub Pages (branch main, path /)
# en deze image exact dezelfde bestanden serveren.
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="verschueren.ai" \
      org.opencontainers.image.description="Statische privésite + OAuth-brandingdocumenten" \
      org.opencontainers.image.source="https://github.com/tvschuer/verschueren-ai"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY index.html style.css /usr/share/nginx/html/
COPY privacy/ /usr/share/nginx/html/privacy/
COPY terms/ /usr/share/nginx/html/terms/

EXPOSE 80
