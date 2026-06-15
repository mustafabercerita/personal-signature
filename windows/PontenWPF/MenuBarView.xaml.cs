using System.Windows;

namespace PontenWPF
{
    public partial class MenuBarView : Window
    {
        public MenuBarView()
        {
            InitializeComponent();
        }

        private void AddSignature_Click(object sender, RoutedEventArgs e)
        {
            var editor = new ImageEditorWindow();
            editor.Show();
            this.Hide();
        }
    }
}
