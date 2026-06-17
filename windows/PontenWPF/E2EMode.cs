namespace PontenWPF;

internal static class E2EMode
{
    public static bool IsEnabled { get; private set; }
    public static string? DataDirectory { get; private set; }

    public static void Initialize(string[]? args)
    {
        args ??= Array.Empty<string>();

        IsEnabled = args.Contains("--e2e")
            || string.Equals(Environment.GetEnvironmentVariable("PONTEN_E2E"), "1", StringComparison.Ordinal);

        DataDirectory = Environment.GetEnvironmentVariable("PONTEN_DATA_DIR");

        for (int i = 0; i < args.Length; i++)
        {
            if (args[i].StartsWith("--data-dir=", StringComparison.Ordinal))
            {
                DataDirectory = args[i]["--data-dir=".Length..].Trim('"');
            }
            else if (args[i] == "--data-dir" && i + 1 < args.Length)
            {
                DataDirectory = args[i + 1].Trim('"');
            }
        }
    }
}