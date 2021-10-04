FROM golang:1.17 AS builder

COPY main.go main.go

RUN CGO_ENABLED=0 go build -o /app main.go

FROM scratch

COPY --from=builder /app /app

CMD [ "/app" ]
