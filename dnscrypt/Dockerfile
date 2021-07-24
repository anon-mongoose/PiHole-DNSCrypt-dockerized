# Debian based
FROM debian:10.9-slim


# Installing dependencies
RUN apt-get update && apt-get install wget dnsutils -y && rm -rf /var/lib/apt/lists/*


# Adding a service user
RUN useradd dnscryptuser


# Installing Dnscrypt
RUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
RUN tar xvzf dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
RUN mv linux-x86_64/ /usr/local/dnscrypt-proxy
RUN chown dnscryptuser:dnscryptuser -R /usr/local/dnscrypt-proxy


# Dnscrypt configuration
WORKDIR /usr/local/dnscrypt-proxy/
COPY ./dnscrypt-proxy.toml /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
RUN chown dnscryptuser:dnscryptuser dnscrypt-proxy.toml && chmod 500 dnscrypt-proxy.toml


# Exposing IPv4 ports
EXPOSE 5353/udp
EXPOSE 5353/tcp

# Exposing IPv6 ports
EXPOSE 53530/udp
EXPOSE 53530/tcp


# Healthcheck
HEALTHCHECK --interval=1m --timeout=5s --retries=2 \
  CMD dig @127.0.0.1 -p 5353 eff.org || exit 1


USER dnscryptuser
ENTRYPOINT ["./dnscrypt-proxy"]
