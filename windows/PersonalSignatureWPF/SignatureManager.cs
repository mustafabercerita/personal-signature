using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace PersonalSignatureWPF
{
    public class SignatureManager
    {
        // 1. Strip White Background
        // Turns white background pixels transparent and returns the modified image
        public Bitmap StripWhiteBackground(Bitmap original)
        {
            Bitmap result = new Bitmap(original.Width, original.Height);
            
            for (int y = 0; y < original.Height; y++)
            {
                for (int x = 0; x < original.Width; x++)
                {
                    Color pixelColor = original.GetPixel(x, y);
                    
                    // Simple threshold for "white"
                    if (pixelColor.R > 200 && pixelColor.G > 200 && pixelColor.B > 200)
                    {
                        result.SetPixel(x, y, Color.Transparent);
                    }
                    else
                    {
                        result.SetPixel(x, y, pixelColor);
                    }
                }
            }
            return result;
        }

        // 2. Auto-Paste Logic
        // Simulate Ctrl+V using keybd_event
        [DllImport("user32.dll")]
        private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        private const int VK_CONTROL = 0x11;
        private const int VK_V = 0x56;
        private const uint KEYEVENTF_KEYUP = 0x0002;

        public void AutoPaste()
        {
            // Press Ctrl
            keybd_event(VK_CONTROL, 0, 0, UIntPtr.Zero);
            // Press V
            keybd_event(VK_V, 0, 0, UIntPtr.Zero);
            // Release V
            keybd_event(VK_V, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
            // Release Ctrl
            keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        }
    }
}
