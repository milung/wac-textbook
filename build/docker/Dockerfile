FROM milung/book-builder as book-builder
ARG version=0.0.0
WORKDIR /usr/src/app

COPY book-src/ book-src/

RUN npm run makehtml
RUN npm run build
RUN node build/makehtml/version.js --version ${version}

FROM milung/spa-server as spa-builder

COPY --from=book-builder /usr/src/app/www public
RUN ./build.sh

FROM scratch

COPY --from=spa-builder /app/server /server
CMD ["/server"] 
