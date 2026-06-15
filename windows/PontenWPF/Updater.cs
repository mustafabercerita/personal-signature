using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

namespace PontenWPF
{
    public class Updater
    {
        public async Task DownloadUpdateAndExecute(string url)
        {
            // Use GetRandomFileName to avoid symlink/predictable path vulnerabilities
            string secureTempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
            Directory.CreateDirectory(secureTempDir);

            string installerPath = Path.Combine(secureTempDir, "update.exe");

            using (HttpClient client = new HttpClient())
            {
                using (var stream = await client.GetStreamAsync(url))
                {
                    using (var fileStream = new FileStream(installerPath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        await stream.CopyToAsync(fileStream);
                    }
                }
            }

            // Execute the update
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = installerPath,
                UseShellExecute = true
            });
        }
    }
}
