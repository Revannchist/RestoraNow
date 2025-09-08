using EasyNetQ;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RestoraNow.Model.Messaging;

namespace RestoraNow.WebAPI.Background;

public sealed class EmailSentLoggingSubscriber : BackgroundService
{
    private readonly IBus _bus;
    private readonly ILogger<EmailSentLoggingSubscriber> _log;
    private IDisposable? _subscription; // keep handle so we can dispose on stop

    public EmailSentLoggingSubscriber(IBus bus, ILogger<EmailSentLoggingSubscriber> log)
    {
        _bus = bus;
        _log = log;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Yield(); // don't block app startup

        // Retry until we manage to subscribe or the host is stopping
        while (_subscription is null && !stoppingToken.IsCancellationRequested)
        {
            try
            {
                _log.LogInformation("EmailSentLoggingSubscriber: subscribing to UserWelcomeEmailSent…");

                _subscription = await _bus.PubSub.SubscribeAsync<UserWelcomeEmailSent>(
                    subscriptionId: "api.email-log.v1",
                    onMessage: msg =>
                    {
                        _log.LogInformation("📫 Welcome email SENT → UserId={UserId} Email={Email} At={AtUtc}",
                            msg.UserId, msg.Email, msg.SentAtUtc);
                        return Task.CompletedTask;
                    },
                    cancellationToken: stoppingToken
                );

                _log.LogInformation("EmailSentLoggingSubscriber: subscribed. Waiting for messages…");
            }
            catch (OperationCanceledException)
            {
                // normal shutdown
                break;
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "EmailSentLoggingSubscriber: subscribe failed (RabbitMQ not ready?). Retrying in 5s…");
                try { await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken); } catch { break; }
            }
        }

        // Park here until the service is asked to stop
        if (!stoppingToken.IsCancellationRequested)
        {
            try { await Task.Delay(Timeout.Infinite, stoppingToken); }
            catch (OperationCanceledException) { /* stopping */ }
        }

        _log.LogInformation("EmailSentLoggingSubscriber: stopping.");
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        // Clean up subscription
        _subscription?.Dispose();
        _subscription = null;
        return base.StopAsync(cancellationToken);
    }
}
