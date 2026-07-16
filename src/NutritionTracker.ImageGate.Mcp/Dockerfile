FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/NutritionTracker.ImageGate.Mcp/NutritionTracker.ImageGate.Mcp.csproj
RUN dotnet publish src/NutritionTracker.ImageGate.Mcp/NutritionTracker.ImageGate.Mcp.csproj -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "NutritionTracker.ImageGate.Mcp.dll"]
