﻿using DotNetEnv;
using EasyNetQ;
using EasyNetQ.Serialization.SystemTextJson;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RestoraNow.Subscriber;
using RestoraNow.Subscribers;

var builder = Host.CreateApplicationBuilder(args);

// Load Subscribers/.env if present (local runs only)
var localEnvPath = Path.Combine(builder.Environment.ContentRootPath, ".env");
if (File.Exists(localEnvPath)) Env.Load(localEnvPath);

// ENV ONLY (friend's approach)
builder.Configuration.Sources.Clear();
builder.Configuration.AddEnvironmentVariables();

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.SetMinimumLevel(LogLevel.Information);

// Bind/validate SMTP + Email
builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.Configure<EmailOptions>(builder.Configuration.GetSection("Email"));

var smtp = builder.Configuration.GetSection("Smtp").Get<SmtpOptions>()
          ?? throw new InvalidOperationException("Missing Smtp__* env vars.");
if (string.IsNullOrWhiteSpace(smtp.Host)) throw new ArgumentException("Smtp__Host is required.");
if (smtp.Port <= 0) throw new ArgumentException("Smtp__Port is required.");
// User/Pass optional; required if your SMTP demands auth

// RabbitMQ connection (friend-style: parts → build a string)
var rabbitHost = builder.Configuration["Rabbit:Host"] ?? "localhost";
var rabbitUser = builder.Configuration["Rabbit:User"] ?? "guest";
var rabbitPass = builder.Configuration["Rabbit:Pass"] ?? "guest";
var rabbitPort = builder.Configuration["Rabbit:Port"];        // optional
var rabbitVh = builder.Configuration["Rabbit:VirtualHost"]; // optional

var parts = new List<string> { $"host={rabbitHost}", $"username={rabbitUser}", $"password={rabbitPass}" };
if (!string.IsNullOrWhiteSpace(rabbitPort)) parts.Add($"port={rabbitPort}");
if (!string.IsNullOrWhiteSpace(rabbitVh)) parts.Add($"virtualHost={rabbitVh}");
parts.Add("publisherConfirms=true");
parts.Add("timeout=10");

var rabbitConnString = string.Join(";", parts);

// EasyNetQ bus (System.Text.Json)
builder.Services.AddSingleton<IBus>(_ =>
    RabbitHutch.CreateBus(rabbitConnString, cfg => cfg.EnableSystemTextJson())
);

// Worker
builder.Services.AddHostedService<EmailSubscriber>();

await builder.Build().RunAsync();
