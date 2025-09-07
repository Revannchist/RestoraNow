using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace RestoraNow.Services.Payments
{
    public sealed class PayPalGateway
    {
        private readonly HttpClient _http;
        private readonly string _baseUrl;
        private readonly string _clientId;
        private readonly string _clientSecret;
        private readonly string _defaultCurrency;
        private readonly string _returnUrl;
        private readonly string _cancelUrl;

        public PayPalGateway(HttpClient http)
        {
            _http = http;

            string mode = GetEnv("PayPal__Mode", required: false)?.ToLowerInvariant() ?? "sandbox";
            _baseUrl = GetEnv("PayPal__BaseUrl", required: false)
                       ?? (mode == "live" ? "https://api-m.paypal.com"
                                          : "https://api-m.sandbox.paypal.com");

            _clientId = GetEnv("PayPal__ClientId");
            _clientSecret = GetEnv("PayPal__ClientSecret");
            _defaultCurrency = GetEnv("PayPal__Currency", required: false) ?? "EUR";
            _returnUrl = GetEnv("PayPal__ReturnUrl");
            _cancelUrl = GetEnv("PayPal__CancelUrl");
        }

        private static string? GetEnv(string key, bool required = true)
        {
            var v = Environment.GetEnvironmentVariable(key);
            if (required && string.IsNullOrWhiteSpace(v))
                throw new InvalidOperationException($"Missing environment variable '{key}'. Add it to your .env.");
            return v;
        }

        private static string? GetHeader(HttpResponseMessage res, string name)
            => res.Headers.TryGetValues(name, out var vals) ? vals.FirstOrDefault() : null;

        private void SetBearer(string token)
        {
            _http.DefaultRequestHeaders.Clear();
            _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            _http.DefaultRequestHeaders.TryAddWithoutValidation("Prefer", "return=representation");
        }

        private async Task<string> GetAccessTokenAsync()
        {
            var creds = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));
            _http.DefaultRequestHeaders.Clear();
            _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", creds);

            var form = new FormUrlEncodedContent(new Dictionary<string, string> { ["grant_type"] = "client_credentials" });
            var resp = await _http.PostAsync($"{_baseUrl}/v1/oauth2/token", form);
            var body = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
                throw new HttpRequestException($"PayPal token error ({(int)resp.StatusCode}) {GetHeader(resp, "Paypal-Debug-Id")}: {body}");

            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.GetProperty("access_token").GetString()!;
        }

        public async Task<(string OrderId, string ApproveUrl)> CreateOrderAsync(
            decimal amount,
            string? currency = null,
            string? returnUrl = null,
            string? cancelUrl = null,
            string? description = null,
            string? referenceId = null)
        {
            var access = await GetAccessTokenAsync();
            SetBearer(access);

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        amount = new
                        {
                            currency_code = currency ?? _defaultCurrency,
                            value = amount.ToString("F2", CultureInfo.InvariantCulture)
                        },
                        description,
                        reference_id = referenceId
                    }
                },
                application_context = new
                {
                    return_url = returnUrl ?? _returnUrl,
                    cancel_url = cancelUrl ?? _cancelUrl,
                    brand_name = "RestoraNow",
                    landing_page = "NO_PREFERENCE",
                    user_action = "PAY_NOW",
                    // Reduce risk checks during sandbox testing
                    shipping_preference = "NO_SHIPPING"
                }
            };

            var json = JsonSerializer.Serialize(payload, new JsonSerializerOptions
            {
                DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
            });

            var resp = await _http.PostAsync($"{_baseUrl}/v2/checkout/orders",
                new StringContent(json, Encoding.UTF8, "application/json"));
            var body = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
                throw new HttpRequestException($"PayPal create order failed ({(int)resp.StatusCode}) {GetHeader(resp, "Paypal-Debug-Id")}: {body}");

            using var doc = JsonDocument.Parse(body);
            var id = doc.RootElement.GetProperty("id").GetString()!;
            var approve = doc.RootElement.GetProperty("links")
                .EnumerateArray()
                .First(l => l.GetProperty("rel").GetString() == "approve")
                .GetProperty("href").GetString()!;

            return (id, approve);
        }

        public async Task<string> GetOrderStatusAsync(string orderId)
        {
            var access = await GetAccessTokenAsync();
            SetBearer(access);

            var resp = await _http.GetAsync($"{_baseUrl}/v2/checkout/orders/{orderId}");
            var body = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
                throw new HttpRequestException($"PayPal get order failed ({(int)resp.StatusCode}) {GetHeader(resp, "Paypal-Debug-Id")}: {body}");

            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.GetProperty("status").GetString()!;
        }

        public async Task<(string Status, string CaptureId, decimal Amount, string? DebugId)> CaptureOrderAsync(string providerOrderId)
        {
            var access = await GetAccessTokenAsync();
            SetBearer(access);

            // Optional idempotency (safe to include)
            _http.DefaultRequestHeaders.Remove("PayPal-Request-Id");
            _http.DefaultRequestHeaders.Add("PayPal-Request-Id", $"capture-{providerOrderId}");

            var resp = await _http.PostAsync(
                $"{_baseUrl}/v2/checkout/orders/{providerOrderId}/capture",
                new StringContent("{}", Encoding.UTF8, "application/json"));

            var debugId = GetHeader(resp, "Paypal-Debug-Id");
            var body = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
                throw new HttpRequestException($"PayPal capture failed ({(int)resp.StatusCode}) {debugId}: {body}");

            using var doc = JsonDocument.Parse(body);
            var status = doc.RootElement.GetProperty("status").GetString()!;

            string captureId = "";
            decimal amount = 0m;

            if (status.Equals("COMPLETED", StringComparison.OrdinalIgnoreCase))
            {
                var cap = doc.RootElement.GetProperty("purchase_units")[0]
                    .GetProperty("payments").GetProperty("captures")[0];

                captureId = cap.GetProperty("id").GetString()!;
                var value = cap.GetProperty("amount").GetProperty("value").GetString()!;
                amount = decimal.Parse(value, CultureInfo.InvariantCulture);
            }

            return (status, captureId, amount, debugId);
        }
    }
}
