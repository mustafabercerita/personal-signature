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
            
            Rectangle rect = new Rectangle(0, 0, original.Width, original.Height);
            System.Drawing.Imaging.BitmapData bmpData = result.LockBits(rect, System.Drawing.Imaging.ImageLockMode.WriteOnly, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
            System.Drawing.Imaging.BitmapData origData = original.LockBits(rect, System.Drawing.Imaging.ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
            
            int bytes = Math.Abs(bmpData.Stride) * original.Height;
            byte[] rgbValues = new byte[bytes];
            byte[] origValues = new byte[bytes];
            
            Marshal.Copy(origData.Scan0, origValues, 0, bytes);
            
            for (int counter = 0; counter < rgbValues.Length; counter += 4)
            {
                byte b = origValues[counter];
                byte g = origValues[counter + 1];
                byte r = origValues[counter + 2];
                byte a = origValues[counter + 3];
                
                if (r > 200 && g > 200 && b > 200)
                {
                    rgbValues[counter] = 0;
                    rgbValues[counter + 1] = 0;
                    rgbValues[counter + 2] = 0;
                    rgbValues[counter + 3] = 0;
                }
                else
                {
                    rgbValues[counter] = b;
                    rgbValues[counter + 1] = g;
                    rgbValues[counter + 2] = r;
                    rgbValues[counter + 3] = a;
                }
            }
            
            Marshal.Copy(rgbValues, 0, bmpData.Scan0, bytes);
            
            original.UnlockBits(origData);
            result.UnlockBits(bmpData);
            
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
