# ===== Base (runtime) =====
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
# Expose the port you actually bind to in compose
EXPOSE 5205
# The aspnet image already uses a non-root user ("app") by default,
# no need to re-declare unless you changed it.

# ===== Build =====
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# 1) Copy solution & project files first for better restore caching
COPY *.sln ./
COPY RestoraNow.WebAPI/RestoraNow.WebAPI.csproj RestoraNow.WebAPI/
COPY RestoraNow.Services/RestoraNow.Services.csproj RestoraNow.Services/
COPY RestoraNow.Model/RestoraNow.Model.csproj RestoraNow.Model/
# (Add any other project csproj lines here if referenced)

# 2) Restore
RUN dotnet restore RestoraNow.WebAPI/RestoraNow.WebAPI.csproj

# 3) Copy the rest of the source
COPY . .

# 4) Build
WORKDIR /src/RestoraNow.WebAPI
RUN dotnet build RestoraNow.WebAPI.csproj -c $BUILD_CONFIGURATION -o /app/build

# ===== Publish =====
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish RestoraNow.WebAPI.csproj -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# ===== Final (runtime) =====
FROM base AS final
WORKDIR /app
# Kestrel bind is set via compose: ASPNETCORE_URLS=http://+:5205
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "RestoraNow.WebAPI.dll"]
