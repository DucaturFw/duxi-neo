# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.11

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ENV NEO_COMMIT=13773f78ae7f7ccc78ae0aca1c7ff2f86a499f40

# 1. dotnet install
RUN apt-get update
RUN apt-get -y install wget
RUN wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get -y install apt-transport-https
RUN apt-get update
RUN apt-get -y install dotnet-sdk-2.1

# 2. git install
RUN apt-get -y install git libleveldb-dev sqlite3 libsqlite3-dev libunwind8

# 3. neo-cli download
RUN git clone https://github.com/neo-project/neo-cli.git /neo-cli
WORKDIR /neo-cli
RUN git reset --hard $NEO_COMMIT

# 4. neo-cli build
RUN dotnet restore
RUN dotnet publish -c release -r linux-x64

WORKDIR /neo-cli/neo-cli

RUN ls -la
RUN ls -la bin
RUN ls -la bin/Release
RUN ls -la bin/Release/netcoreapp2.0/
RUN ls -la bin/Release/netcoreapp2.0/linux-x64

# 5. install screen (we need it to run neo-cli as a daemon)
RUN apt-get -y install screen
# `screen` inside docker won't work without discarding terminal session
RUN script /dev/null

# open NEO node ports
EXPOSE 10331-10334
EXPOSE 20331-20334
EXPOSE 30331-30334

# FINAL: NEO runs here
# RUN echo "script /dev/null" > start.sh
# RUN echo "screen -S neo dotnet bin/Release/netcoreapp2.0/linux-x64/neo-cli.dll --log --rpc" >> start.sh
# RUN chmod +x start.sh
# RUN cat start.sh

# ENTRYPOINT [ "./start.sh"]
ENTRYPOINT [ "screen", "-S", "neo", "dotnet", "bin/Release/netcoreapp2.0/linux-x64/neo-cli.dll", "--log", "--rpc" ]
# screen -S neo dotnet bin/Release/netcoreapp2.0/linux-x64/neo-cli.dll --log --rpc

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*