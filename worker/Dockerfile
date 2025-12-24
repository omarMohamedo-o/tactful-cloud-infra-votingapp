# Multi-stage build for .NET Worker service
# Stage 1: Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

# Set working directory
WORKDIR /source

# Copy csproj and restore dependencies
COPY *.csproj .
RUN dotnet restore

# Copy source code and build
COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# Stage 2: Runtime stage
FROM mcr.microsoft.com/dotnet/runtime:10.0-alpine

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Set working directory
WORKDIR /app

# Copy published app from builder
COPY --from=builder /app .

# Switch to non-root user
USER appuser

# Run the application
CMD ["dotnet", "Worker.dll"]
