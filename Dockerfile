FROM centos:7 as builder
ARG DATADOME_VERSION="1.16.1-2.36~94"
WORKDIR /tmp
COPY ./asset/nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum install nginx -y && yum clean all
RUN yum install iperl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel pcre-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel gcc make openssl-devel -y && yum clean all
RUN tmp_dir=$(mktemp -d -t datadome-XXXXXXXXXX) && \

# Get the Nginx version in use
nginx_version=$(nginx -v 2>&1 | grep -oP 'nginx\/\K([0-9.]*)') && \

# Download and untar the Nginx sources to compile dynamic module
curl -sLo ${tmp_dir}/nginx-${nginx_version}.tar.gz http://nginx.org/download/nginx-${nginx_version}.tar.gz && \
tar -C ${tmp_dir} -xzf ${tmp_dir}/nginx-${nginx_version}.tar.gz && \

# Download and untar DataDome module sources
curl -sLo ${tmp_dir}/datadome_nginx_module.tar.gz https://package.datadome.co/linux/DataDome-Nginx-latest.tgz && \
tar -C ${tmp_dir} -zxf ${tmp_dir}/datadome_nginx_module.tar.gz && \

# Get the name of the DataDome module directory
datadome_dir=$(basename $(ls ${tmp_dir}/DataDome-NginxDome-* -d1)) && \

# Get the compilation flags used during the compilation of nginx, and remove any --add-dynamic-module flag we find
# This is important because when compiling the modules, you have to use the same flags that have been used when compiling nginx
nginx_flags="$(nginx -V 2>&1 | grep -oP 'configure arguments: \K(.*)' | sed -e 's/--add-dynamic-module=\S*//g')" && \

# Launch the nginx configure script with same flags + the DataDome dynamic module
cd ${tmp_dir}/nginx-${nginx_version} && eval "./configure --add-dynamic-module=../${datadome_dir} ${nginx_flags}" && \

# Compile the modules
make -C ${tmp_dir}/nginx-${nginx_version} -f objs/Makefile modules && \

# Ensure Nginx module directory is created
mkdir -p /etc/nginx/modules && \

# Copy the .so modules to nginx configuration
cp ${tmp_dir}/nginx-${nginx_version}/objs/ngx_http_data_dome_*.so /etc/nginx/modules/ && \
rm -rf ${tmp_dir}
FROM centos:7
COPY ./asset/nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum install nginx -y && yum clean all
COPY --from=builder /etc/nginx/modules/ngx_http_data_dome_auth_module.so /etc/nginx/modules/
COPY --from=builder /etc/nginx/modules/ngx_http_data_dome_shield_module.so /etc/nginx/modules/
COPY --from=builder /etc/nginx/modules/ngx_http_data_dome_upstream_dynamic_servers_module.so /etc/nginx/modules/
