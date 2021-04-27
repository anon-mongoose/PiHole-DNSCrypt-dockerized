FROM debian

#Container update
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install wget -y

#Installing Dnscrypt
RUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
RUN tar xvzf dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
RUN mv linux-x86_64/ /usr/local/dnscrypt-proxy
RUN chown root:root -R /usr/local/dnscrypt-proxy

#Dnscrypt configuration
WORKDIR /usr/local/dnscrypt-proxy/
COPY ./dnscrypt-proxy.toml /usr/local/dnscrypt-proxy/dnscrypt-proxy.toml
RUN chmod +x dnscrypt-proxy

#IPv4
EXPOSE 5353/udp
EXPOSE 5353/tcp
#IPv6
EXPOSE 53530/udp
EXPOSE 53530/tcp

CMD ["./dnscrypt-proxy"]
