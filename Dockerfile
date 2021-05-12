FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS publish
WORKDIR /src
COPY tests.csproj ./

RUN dotnet restore "./tests.csproj" --runtime alpine-x64
COPY . .
RUN dotnet publish "tests.csproj" -c Release -o /app/publish \
  --no-restore \
  --runtime alpine-x64 \
  --self-contained true \
  /p:PublishTrimmed=true \
  /p:PublishSingleFile=true

FROM mcr.microsoft.com/dotnet/runtime-deps:5.0-alpine AS final

# create a new user and change directory ownership
RUN adduser --disabled-password \
  --home /app \
  --gecos '' dotnetuser && chown -R dotnetuser /app

# impersonate into the new user
USER dotnetuser
WORKDIR /app

# use port 5000 because
EXPOSE 5000
COPY --from=publish /app/publish .

# instruct Kestrel to expose API on port 5000
ENTRYPOINT ["./tests", "--urls", "http://0.0.0.0:5000"]