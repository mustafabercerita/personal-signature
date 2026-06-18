using System.Diagnostics;
using System.Reflection;
using System.Windows;
using System.Windows.Navigation;

namespace PontenWPF
{
    public partial class AboutWindow : Window
    {
        public AboutWindow(string shortcutDescription)
        {
            InitializeComponent();

            var version = Assembly.GetExecutingAssembly().GetName().Version;
            VersionText.Text = $"Version {version?.Major}.{version?.Minor}.{version?.Build ?? 0}";
            ShortcutText.Text = $"Global shortcut: {shortcutDescription}";
            GitHubLink.NavigateUri = new System.Uri("https://github.com/mustafabercerita/Ponten");
        }

        private void GitHubLink_RequestNavigate(object sender, RequestNavigateEventArgs e)
        {
            Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri) { UseShellExecute = true });
            e.Handled = true;
        }
    }
}