FROM swift:5.10.1 AS builder

WORKDIR /backup_daemon

COPY . ./

RUN swift build -c release

#Package
FROM swift:latest

WORKDIR /backup_daemon

# Copy the built executable from the builder stage
COPY --from=builder /backup_daemon/.build/release/backup_daemon .

# Set the entry point to the executable
CMD ["./backup_daemon"]
