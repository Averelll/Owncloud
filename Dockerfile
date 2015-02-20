FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export version='8.0.0' && \
    export sha256sum='0c62cb06fe4c3eb107bccc4302f2bb3b9f7e5373cf7c9dd307fe' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 curl php5 php5-gd \
                php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl \
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick \
                php5-cgi php5-json smbclient lighttpd && \
    apt-get clean && \
    curl -LOC- -ks \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    echo '$HTTP["url"] =~ "^/owncloud/data/" {' >>/etc/lighttpd/lighttpd.conf&&\
    echo '\turl.access-deny = ("")'  >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    echo '$HTTP["url"] =~ "^/owncloud($|/)" {' >>/etc/lighttpd/lighttpd.conf &&\
    echo '\tdir-listing.activate = "disable"' >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    sed -i '/CHILDREN/s/[0-9][0-9]*/16/' \
                /etc/lighttpd/conf-available/15-fastcgi-php.conf && \
    sed -i '/max-procs/a \ \t\t"idle-timeout" => 20,'\
                /etc/lighttpd/conf-available/15-fastcgi-php.conf && \
    lighttpd-enable-mod fastcgi-php && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2

# Config files
COPY owncloud.sh /usr/bin/

VOLUME ["/var/www/owncloud"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
