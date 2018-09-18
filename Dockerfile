# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM microsoft/dotnet:2.2-sdk

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ARG NEO_COMMIT=13773f78ae7f7ccc78ae0aca1c7ff2f86a499f40
ARG NEO_PLUGINS_COMMIT=10a348b94374e5ae92c5b2204ff908753b2273dd

####### INSTALL NEO #######

# 1. dotnet install
RUN apt-get update

# 2. git install
RUN apt-get -y install git libleveldb-dev sqlite3 libsqlite3-dev libunwind8

# 3. neo-cli download
RUN git clone https://github.com/neo-project/neo-cli.git /neo-cli
WORKDIR /neo-cli
RUN git reset --hard ${NEO_COMMIT}

# 4. neo-cli build
RUN dotnet restore
RUN dotnet publish -c release -r linux-x64

####### NEO PLUGINS #######

RUN git clone https://github.com/neo-project/neo-plugins.git /neo-plugins
WORKDIR /neo-plugins
RUN git reset --hard ${NEO_PLUGINS_COMMIT}

WORKDIR /neo-plugins/ApplicationLogs
RUN dotnet restore
RUN dotnet publish -c release -r linux-x64 -f netstandard2.0

RUN ls -la

WORKDIR /neo-cli/neo-cli/bin/Release/netcoreapp2.0/linux-x64
RUN mkdir ./Plugins
RUN mkdir ./Plugins/ApplicationLogs
RUN cp -r /neo-plugins/ApplicationLogs/bin/release/netstandard2.0/linux-x64/* ./Plugins/

####### RUN NEO-CLI #######

WORKDIR /neo-cli/neo-cli

# 5. install screen (we need it to run neo-cli as a daemon)
RUN apt-get -y install screen
# `screen` inside docker won't work without discarding terminal session
RUN script /dev/null

# open NEO node ports
EXPOSE 10331-10334
EXPOSE 20331-20334
EXPOSE 30331-30334

# FINAL: NEO runs here

ENTRYPOINT [ "screen", "-L", "-S", "neo", "dotnet", "bin/Release/netcoreapp2.0/linux-x64/neo-cli.dll", "--log", "--rpc" ]
# screen -S neo dotnet bin/Release/netcoreapp2.0/linux-x64/neo-cli.dll --log --rpc

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*