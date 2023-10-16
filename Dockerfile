# Gunakan gambar Debian Buster sebagai dasar
ARG BASE_DEBIAN=buster
FROM debian:${BASE_DEBIAN}

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
  sed -ri 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Salin konfigurasi Supervisor untuk OpenSSH server
COPY supervisord-openssh-server.conf /etc/supervisor/conf.d/supervisord-openssh-server.conf

# Salin script startup
COPY startup.sh /startup.sh

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Atur PATH untuk mengakses Composer
ENV PATH="/usr/local/bin:${PATH}"

# Tentukan volume
VOLUME [ "/var/log/mysql/", "/var/log/apache2/", "/www", "/opt/lampp/apache2/conf.d/" ]

# Ekspos port
EXPOSE 3306
EXPOSE 22
EXPOSE 80

# Jalankan script startup
CMD ["sh", "/startup.sh"]
