# Gunakan gambar Debian Buster sebagai dasar
FROM debian:buster

# Tambahkan argumen untuk URL XAMPP dan informasi pemeliharaan
ARG XAMPP_URL=https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.2.4/xampp-linux-x64-8.2.4-0-installer.run?from_af=true
LABEL maintainer="Tomas Jasek<tomsik68 (at) gmail (dot) com>"

# Set environment variable untuk non-interactive mode
ENV DEBIAN_FRONTEND noninteractive

# Atur kata sandi root ke "root"
RUN echo 'root:root' | chpasswd

# Perbarui paket dan instal perangkat yang diperlukan
RUN apt-get update --fix-missing && \
  apt-get upgrade -y && \
  apt-get -y install curl net-tools && \
  apt-get -yq install openssh-server supervisor && \
  apt-get -y install nano vim less --no-install-recommends && \
  apt-get clean

# Unduh dan instal XAMPP
RUN curl -Lo xampp-linux-installer.run ${XAMPP_URL} && \
  chmod +x xampp-linux-installer.run && \
  bash -c './xampp-linux-installer.run' && \
  ln -sf /opt/lampp/lampp /usr/bin/lampp && \
  sed -i.bak s'/Require local/Require all granted/g' /opt/lampp/etc/extra/httpd-xampp.conf && \
  sed -i.bak s'/display_errors=Off/display_errors=On/g' /opt/lampp/etc/php.ini && \
  mkdir /opt/lampp/apache2/conf.d && \
  echo "IncludeOptional /opt/lampp/apache2/conf.d/*.conf" >> /opt/lampp/etc/httpd.conf && \
  mkdir /www && \
  ln -s /opt/lampp/htdocs /www && \
  mkdir -p /var/run/sshd && \
  chmod -R 777 /opt/lampp/htdocs && \
  sed -ri 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Salin konfigurasi Supervisor untuk OpenSSH server
COPY supervisord-openssh-server.conf /etc/supervisor/conf.d/supervisord-openssh-server.conf

# Salin script startup
COPY startup.sh /startup.sh

# Tambahkan /opt/lampp/bin ke dalam PATH
ENV PATH="/opt/lampp/bin:${PATH}"

# Unduh dan instal Composer
RUN /opt/lampp/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    /opt/lampp/bin/php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    /opt/lampp/bin/php -r "unlink('composer-setup.php');"

# Tentukan volume
VOLUME [ "/var/log/mysql/", "/var/log/apache2/", "/www", "/opt/lampp/apache2/conf.d/" ]

# Ekspos port
EXPOSE 3306
EXPOSE 22
EXPOSE 80

# Jalankan script startup
CMD ["sh", "/startup.sh"]
