FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS dotnet-sdk
FROM mcr.microsoft.com/dotnet/core/runtime:3.0-alpine AS dotnet-runtime

FROM dotnet-sdk AS base
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    make \
    mono-devel \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
ENV FrameworkPathOverride /usr/lib/mono/4.5/
ENV PATH="${PATH}:/root/.dotnet/tools"

# Install .Net Core 2.1
RUN wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && apt-get update  --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    dotnet-sdk-2.1=2.1.801-1 \
  && apt-get clean --quiet \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf packages-microsoft-prod.deb

# Install .Net Core 1.1
RUN wget -q https://download.visualstudio.microsoft.com/download/pr/3aaaa9ad-577b-4127-bee8-3a25d447ac17/9259d8dbfef4dc85d65d0d08261ffacd/dotnet-dev-ubuntu.16.04-x64.1.1.14.tar.gz -O dotnet-dev-ubuntu.16.04-x64.1.1.14.tar.gz \
  && mkdir -p $HOME/dotnet \
  && tar zxf dotnet-dev-ubuntu.16.04-x64.1.1.14.tar.gz -C $HOME/dotnet \
  && export PATH=$PATH:$HOME/dotnet \
  && rm -rf dotnet-dev-ubuntu.16.04-x64.1.1.14.tar.gz
  
FROM base AS builder
WORKDIR /build
COPY . /build
RUN make deps restore


FROM builder AS publisher
RUN make publish


FROM dotnet-runtime AS app
WORKDIR /app
COPY --from=publisher /build/out/published /app
ENTRYPOINT ["dotnet", "jaytwo.ejson.CommandLine.dll"]
