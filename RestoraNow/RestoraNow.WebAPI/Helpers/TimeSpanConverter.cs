using System.Text.Json.Serialization;
using System.Text.Json;

namespace RestoraNow.WebAPI.Helpers
{
    public class TimeSpanConverter : JsonConverter<TimeSpan>
    {
        private const string Format = @"hh\:mm\:ss";

        public override TimeSpan Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            var stringValue = reader.GetString(); //ovo treba popravit
            if (TimeSpan.TryParseExact(stringValue, Format, null, out var result))
            {
                return result;
            }

            throw new JsonException($"Invalid TimeSpan format. Expected format is '{Format}'");
        }

        public override void Write(Utf8JsonWriter writer, TimeSpan value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.ToString(Format));
        }
    }
}
