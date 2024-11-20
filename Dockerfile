FROM --platform=${BUILDPLATFORM} archlinux:base-devel AS gobuilder
WORKDIR /yarr

RUN pacman --noconfirm -Syu
RUN pacman --noconfirm -S go

COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY etc ./etc
COPY src ./src
COPY vendor ./vendor

ARG TARGETARCH
RUN GOOS=linux GOARCH=${TARGETARCH} CGO_ENABLED=1 go build -tags "sqlite_foreign_keys" -buildvcs=false -ldflags="-w -s -extldflags '-static'" -o ./yarr ./cmd/yarr

FROM scratch
LABEL maintainer="wn@neessen.dev"
COPY ["docker-files/passwd", "/etc/passwd"]
COPY ["docker-files/group", "/etc/group"]
COPY --from=gobuilder ["/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/cert.pem"]

WORKDIR /yarr
COPY --from=gobuilder /yarr/yarr ./

EXPOSE 7070
ENTRYPOINT ["./yarr", "-addr", "0.0.0.0:7070"]
