# Working with the Container registry - https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
# Creating a Docker container action - https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
# Manual deploy:
# --------------
#  docker build -t ghcr.io/bmivan/bm-sonarscan-dotnet:1.0.0 .
#  docker inspect ghcr.io/bmivan/bm-sonarscan-dotnet
#  docker image ls ghcr.io/bmivan/bm-sonarscan-dotnet
#  echo $Env:GH_PAT_CLASSIC | docker login ghcr.io/bmivan -u bmivan --password-stdin
#  docker push ghcr.io/bmivan/bm-sonarscan-dotnet:1.0.0
#  docker rmi ghcr.io/bmivan/bm-sonarscan-dotnet:1.0.0

# Build local Docker image
# docker build -t bm-sonarscan-dotnet .
# Execute Docker container
# docker run --name bm-sonarscan-dotnet -w /github/workspace --rm \
#   -e INPUT_SONARORGANIZATION \
#   -e INPUT_SONARPROJECTKEY \
#   -e INPUT_SONARPROJECTNAME \
#   -e INPUT_SONARHOSTNAME \
#   -e INPUT_SONARBEGINARGUMENTS \
#   -e INPUT_DOTNETPREBUILDCMD \
#   -e INPUT_DOTNETBUILDARGUMENTS \
#   -e INPUT_DOTNETTESTARGUMENTS \
#   -e INPUT_DOTNETDISABLETESTS \
#   -e GH_PAT_CLASSIC \
#   -e SONAR_TOKEN \
#   -e GITHUB_EVENT_NAME \
#   -e GITHUB_REPOSITORY \
#   -e GITHUB_REF \
#   -e GITHUB_HEAD_REF \
#   -e GITHUB_BASE_REF \
#   -v "/var/run/docker.sock":"/var/run/docker.sock" \
#   -v $(pwd):"/github/workspace" \
#   bm-sonarscan-dotnet

FROM mcr.microsoft.com/dotnet/sdk:7.0

LABEL com.github.actions.name bm-sonarscan-dotnet
LABEL com.github.actions.description "SonarScanner for .NET."
LABEL com.github.actions.icon check-square
LABEL com.github.actions.color blue
LABEL org.opencontainers.image.source https://github.com/BMIvan/bm-sonarscan-dotnet
LABEL org.opencontainers.image.description "SonarScanner for .NET."
LABEL org.opencontainers.image.version v1.0.0
LABEL org.opencontainers.image.licenses MIT
LABEL repository https://github.com/BMIvan/bm-sonarscan-dotnet
LABEL homepage https://github.com/BMIvan/bm-sonarscan-dotnet
LABEL maintainer BMIvan

# Version numbers of used software
ENV SONAR_SCANNER_DOTNET_TOOL_VERSION=5.14.0 \
    DOTNETCORE_RUNTIME_VERSION=7.0 \
    NODE_VERSION=21 \
    JRE_VERSION=17

# Add Microsoft Debian apt-get feed 
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb

# Update ans install HTTPS support
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y apt-transport-https

# Install gh (GitHub CLI)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  apt-get update -y

# Install gh (GitHub CLI) - https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN apt-get install --no-install-recommends -y gh

# Install jq
RUN apt-get install --no-install-recommends -y jq

# Fix JRE Install https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1

# Install the .NET Runtime for SonarScanner
RUN apt-get install --no-install-recommends -y aspnetcore-runtime-$DOTNETCORE_RUNTIME_VERSION

# Install NodeJS
RUN apt-get install --no-install-recommends -y ca-certificates gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -y && \
    apt-get install --no-install-recommends -y nodejs

# Install Java Runtime for SonarScanner
RUN apt-get install --no-install-recommends -y openjdk-$JRE_VERSION-jre

# Install SonarScanner .NET global tool
RUN dotnet tool install dotnet-sonarscanner --tool-path . --version $SONAR_SCANNER_DOTNET_TOOL_VERSION

# Cleanup
RUN apt-get -q -y autoremove && \
    apt-get -q clean -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
