using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace PontenWPF
{
    public class SignatureItem
    {
        public Guid Id { get; set; }
        public string Filename { get; set; } = "";
        public string? Name { get; set; }
    }

    public class UserSettings
    {
        public bool LaunchAtLogin { get; set; } = false;
        public bool AutoPaste { get; set; } = true;
        public bool RemoveBackground { get; set; } = true;
    }

    public class IndexWrapper
    {
        public List<SignatureItem> Items { get; set; } = new();
        public Guid? ActiveID { get; set; }
        public UserSettings Settings { get; set; } = new();
    }

    public class SignatureStorage
    {
        internal static readonly JsonSerializerOptions IndexJsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true,
            WriteIndented = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };

        private readonly string _storageDirectory;
        private readonly string _indexPath;
        private readonly bool _skipRegistrySync;

        public List<SignatureItem> Signatures { get; private set; } = new();
        public Guid? ActiveSignatureID { get; set; }
        public UserSettings Settings { get; set; } = new();

        public SignatureStorage(string? customStorageDirectory = null)
        {
            if (!string.IsNullOrEmpty(customStorageDirectory))
            {
                _storageDirectory = customStorageDirectory;
                _skipRegistrySync = true;
            }
            else
            {
                _storageDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Ponten");
                _skipRegistrySync = false;
            }
            _indexPath = Path.Combine(_storageDirectory, "index.json");
            Directory.CreateDirectory(_storageDirectory);
            CleanTempFiles();
            Load();
        }

        public static bool IsValidSignatureFilename(string filename)
        {
            if (string.IsNullOrWhiteSpace(filename))
            {
                return false;
            }

            if (filename.Contains("..", StringComparison.Ordinal))
            {
                return false;
            }

            if (filename.Contains('/') || filename.Contains('\\'))
            {
                return false;
            }

            if (filename.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
            {
                return false;
            }

            return Regex.IsMatch(filename, @"^[a-fA-F0-9\-]+\.png$");
        }

        public string GetSignatureFilePath(string filename)
        {
            if (!IsValidSignatureFilename(filename))
            {
                throw new ArgumentException($"Invalid signature filename: {filename}", nameof(filename));
            }

            return Path.Combine(_storageDirectory, filename);
        }

        private void CleanTempFiles()
        {
            try
            {
                foreach (string tmpPath in Directory.GetFiles(_storageDirectory, "*.tmp"))
                {
                    try
                    {
                        File.Delete(tmpPath);
                    }
                    catch (Exception ex)
                    {
                        App.Log($"Failed to delete temp file {Path.GetFileName(tmpPath)}: {ex.Message}");
                    }
                }
            }
            catch (Exception ex)
            {
                App.Log($"Failed to clean temp files: {ex.Message}");
            }
        }

        public void Load()
        {
            if (File.Exists(_indexPath))
            {
                try
                {
                    string json = File.ReadAllText(_indexPath);
                    var wrapper = JsonSerializer.Deserialize<IndexWrapper>(json, IndexJsonOptions);
                    if (wrapper != null)
                    {
                        Signatures = wrapper.Items ?? new List<SignatureItem>();
                        ActiveSignatureID = wrapper.ActiveID;
                        if (wrapper.Settings != null) Settings = wrapper.Settings;
                    }
                }
                catch (Exception ex)
                {
                    App.Log($"Failed to load index.json: {ex.Message}");
                }
            }
            
            // Clean up invalid filenames and missing files from the index
            bool changed = false;
            for (int i = Signatures.Count - 1; i >= 0; i--)
            {
                string filename = Signatures[i].Filename;
                if (!IsValidSignatureFilename(filename))
                {
                    App.Log($"Removing signature with invalid filename: {filename}");
                    Signatures.RemoveAt(i);
                    changed = true;
                    continue;
                }

                if (!File.Exists(GetSignatureFilePath(filename)))
                {
                    Signatures.RemoveAt(i);
                    changed = true;
                }
            }

            if (!Signatures.Any(s => s.Id == ActiveSignatureID))
            {
                ActiveSignatureID = Signatures.FirstOrDefault()?.Id;
                changed = true;
            }

            SyncLaunchAtLoginFromRegistry(ref changed);

            if (changed) SaveIndex();
        }

        private void SyncLaunchAtLoginFromRegistry(ref bool changed)
        {
            if (_skipRegistrySync)
            {
                return;
            }

            bool registryEnabled = IsLaunchAtLoginEnabledInRegistry();
            if (Settings.LaunchAtLogin != registryEnabled)
            {
                Settings.LaunchAtLogin = registryEnabled;
                changed = true;
            }
        }

        private static bool IsLaunchAtLoginEnabledInRegistry()
        {
            try
            {
                using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", false);
                return key?.GetValue("PontenSignatures") != null;
            }
            catch (Exception ex)
            {
                App.Log($"Failed to read Launch at Login registry state: {ex.Message}");
                return false;
            }
        }

        public void SaveIndex()
        {
            var wrapper = new IndexWrapper
            {
                Items = Signatures,
                ActiveID = ActiveSignatureID,
                Settings = Settings
            };
            try
            {
                string json = JsonSerializer.Serialize(wrapper, IndexJsonOptions);
                string tempPath = _indexPath + ".tmp";
                File.WriteAllText(tempPath, json);
                File.Move(tempPath, _indexPath, overwrite: true);
            }
            catch (Exception ex)
            {
                App.Log($"Failed to save index.json: {ex.Message}");
            }
        }

        public void AddSignature(SignatureItem item)
        {
            Signatures.Add(item);
            ActiveSignatureID = item.Id;
            SaveIndex();
        }

        public void RemoveSignature(Guid id)
        {
            var item = Signatures.FirstOrDefault(s => s.Id == id);
            if (item != null)
            {
                Signatures.Remove(item);
                string path = GetSignatureFilePath(item.Filename);
                if (File.Exists(path))
                {
                    try { File.Delete(path); }
                    catch (Exception ex) { App.Log($"Failed to delete signature image {item.Filename}: {ex.Message}"); }
                }
                
                if (ActiveSignatureID == id)
                {
                    ActiveSignatureID = Signatures.FirstOrDefault()?.Id;
                }
                SaveIndex();
            }
        }
        
        public void SetActiveSignature(Guid id)
        {
            if (Signatures.Any(s => s.Id == id))
            {
                ActiveSignatureID = id;
                SaveIndex();
            }
        }

        public void ApplyLaunchAtLogin(bool launch)
        {
            Settings.LaunchAtLogin = launch;
            SaveIndex();

            if (_skipRegistrySync)
            {
                return;
            }

            try
            {
                using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                if (key != null)
                {
                    string appName = "PontenSignatures";
                    if (launch)
                    {
                        string exePath = Environment.ProcessPath
                            ?? System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName
                            ?? "";
                        if (!string.IsNullOrEmpty(exePath))
                        {
                            key.SetValue(appName, $"\"{exePath}\"");
                        }
                    }
                    else
                    {
                        key.DeleteValue(appName, false);
                    }
                }
            }
            catch (Exception ex)
            {
                App.Log($"Failed to set Launch at Login: {ex.Message}");
            }
        }
    }
}
