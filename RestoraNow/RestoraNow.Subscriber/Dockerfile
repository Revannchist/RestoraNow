# =========================
# Build stage
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy only what we need for the subscriber build cache
COPY RestoraNow.Subscriber/RestoraNow.Subscriber.csproj RestoraNow.Subscriber/
COPY RestoraNow.Model/RestoraNow.Model.csproj           RestoraNow.Model/
COPY RestoraNow.Services/RestoraNow.Services.csproj     RestoraNow.Services/
# (Add more COPY lines if the Subscriber references any other projects)

# Restore the SUBSCRIBER PROJECT (not the whole solution)
RUN dotnet restore RestoraNow.Subscriber/RestoraNow.Subscriber.csproj

# Now copy the rest of the source
COPY . .

# Publish subscriber
WORKDIR /src/RestoraNow.Subscriber
RUN dotnet publish RestoraNow.Subscriber.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

# =========================
# Runtime stage
# =========================
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "RestoraNow.Subscriber.dll"]
