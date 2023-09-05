# Dockerfile with main.go
FROM golang:1.21.0-alpine3.17 AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

EXPOSE 8080

ENTRYPOINT ["/app/main"]
