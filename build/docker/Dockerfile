FROM milung/book-builder as book-builder
LABEL maintainer="milan.unger@siemens-healthineers.com"
ARG version=latest
ARG title="Skriptá WAC"
ARG description="Skriptá k predmetu Vývoj webových aplikácií v prostredí cloud"
ARG author="Milan Unger"
ARG email="milan.unger@siemens-healthineers.com"
ARG figure_caption="Obrázok %d."

WORKDIR /usr/src/app
COPY book-src/ book-src/
COPY favicon.ico ./src/assets/icon/favicon.ico
COPY favicon.png ./src/assets/icon/favicon.png

#generate book
RUN node ./build/makehtml/makehtml.mjs  --verbose --version ${version} 

RUN npm run build

# generate index.html
RUN node build/makehtml/version.js \
     --version ${version} \
     --title "${title}" \
     --description "${description}" \
     --author "${author}" \
     --email "${email}" \
     --image-caption "${figure_caption}" 

## build SPA server executable
FROM milung/spa-server as spa-builder

COPY --from=book-builder /usr/src/app/www public
RUN ./build.sh

## final sever image
FROM scratch

COPY --from=spa-builder /app/server /server
EXPOSE 8080
CMD ["/server"] 
