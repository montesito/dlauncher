# DLauncher - Icon & Assets Generator (Flat, Vibrant, Homogeneous Colors with True Windows DIBs)
# Regenera src\Assets\logo.png, logo.ico (multi-resolución) y logo_b64.txt a partir del logo vectorial.
# Uso: powershell -ExecutionPolicy Bypass -File .\tools\New-DLauncherIcon.ps1
# Tras regenerar, actualiza $logoBase64 en src\UI\DLauncherUI.ps1 con el contenido de logo_b64.txt y vuelve a compilar.
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

$csharpCode = @"
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class TrueIcoBuilder {
    public static byte[] CreateIco(Bitmap src256) {
        int[] sizes = new int[] { 16, 24, 32, 48, 64, 128, 256 };
        List<byte[]> dataList = new List<byte[]>();
        
        using (MemoryStream ms = new MemoryStream()) {
            BinaryWriter bw = new BinaryWriter(ms);
            bw.Write((ushort)0); // reserved
            bw.Write((ushort)1); // type = ico
            bw.Write((ushort)sizes.Length); // count
            
            int offset = 6 + (16 * sizes.Length);
            
            for (int i = 0; i < sizes.Length; i++) {
                int s = sizes[i];
                byte[] imgData;
                
                using (Bitmap resized = new Bitmap(src256, new Size(s, s))) {
                    if (s == 256) {
                        // 256x256 uses standard PNG format
                        using (MemoryStream pngMs = new MemoryStream()) {
                            resized.Save(pngMs, ImageFormat.Png);
                            imgData = pngMs.ToArray();
                        }
                    } else {
                        // Standard Windows 32bpp DIB format
                        using (MemoryStream dibMs = new MemoryStream()) {
                            BinaryWriter dw = new BinaryWriter(dibMs);
                            int maskRowSize = ((s + 31) / 32) * 4;
                            int maskSize = maskRowSize * s;
                            
                            // BITMAPINFOHEADER (40 bytes)
                            dw.Write((uint)40); // biSize
                            dw.Write((int)s);   // biWidth
                            dw.Write((int)(s * 2)); // biHeight (doubled for image + mask)
                            dw.Write((ushort)1); // biPlanes
                            dw.Write((ushort)32); // biBitCount
                            dw.Write((uint)0);  // biCompression = BI_RGB
                            dw.Write((uint)(s * s * 4)); // biSizeImage
                            dw.Write((int)0);   // biXPelsPerMeter
                            dw.Write((int)0);   // biYPelsPerMeter
                            dw.Write((uint)0);  // biClrUsed
                            dw.Write((uint)0);  // biClrImportant
                            
                            // Bottom-up BGRA raw pixels
                            for (int y = s - 1; y >= 0; y--) {
                                for (int x = 0; x < s; x++) {
                                    Color c = resized.GetPixel(x, y);
                                    dw.Write(c.B);
                                    dw.Write(c.G);
                                    dw.Write(c.R);
                                    dw.Write(c.A);
                                }
                            }
                            
                            // 1-bit AND mask (all 0s)
                            for (int m = 0; m < maskSize; m++) {
                                dw.Write((byte)0);
                            }
                            
                            imgData = dibMs.ToArray();
                        }
                    }
                }
                
                dataList.Add(imgData);
                
                byte bSize = s >= 256 ? (byte)0 : (byte)s;
                bw.Write(bSize); // width
                bw.Write(bSize); // height
                bw.Write((byte)0); // colors
                bw.Write((byte)0); // reserved
                bw.Write((ushort)1); // planes
                bw.Write((ushort)32); // bit count
                bw.Write((uint)imgData.Length); // bytes in res
                bw.Write((uint)offset); // offset
                
                offset += imgData.Length;
            }
            
            for (int i = 0; i < dataList.Count; i++) {
                bw.Write(dataList[i]);
            }
            
            return ms.ToArray();
        }
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies System.Drawing

# XAML con Colores Planos, Homogéneos y Sin Degradados ni Reflejos
# Columna: Tech Azure (#0070F3)
# Chevron: Solar Orange (#FF5500)
$xamlTemplate = @"
<Viewbox xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <Canvas Width="100" Height="100">
        <Rectangle Canvas.Left="25" Canvas.Top="20" Width="14" Height="60" RadiusX="3" RadiusY="3" Fill="#0070F3" />
        <Path Data="M 48,20 L 65,20 L 95,50 L 65,80 L 48,80 L 48,65 L 65,65 L 80,50 L 65,35 L 48,35 Z" Fill="#FF5500" />
    </Canvas>
</Viewbox>
"@

$sr = [System.IO.StringReader]::new($xamlTemplate)
$xr = [System.Xml.XmlReader]::Create($sr)
$viewbox = [System.Windows.Markup.XamlReader]::Load($xr)

$sz = [System.Windows.Size]::new(256, 256)
$viewbox.Measure($sz)
$viewbox.Arrange([System.Windows.Rect]::new([System.Windows.Point]::new(0, 0), $sz))
$viewbox.UpdateLayout()

$rtb = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(256, 256, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
$rtb.Render($viewbox)

$enc = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
$enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))

$ms = [System.IO.MemoryStream]::new()
$enc.Save($ms)
$png256Bytes = $ms.ToArray()
$ms.Dispose()
$xr.Dispose()
$sr.Dispose()

$assetsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\src\Assets"
if (-not (Test-Path $assetsDir)) {
    $null = New-Item -ItemType Directory -Path $assetsDir -Force
}

# 1. Guardar logo.png (256x256)
$pngPath = Join-Path -Path $assetsDir -ChildPath "logo.png"
[System.IO.File]::WriteAllBytes($pngPath, $png256Bytes)
Write-Host "logo.png guardado en $pngPath ($($png256Bytes.Length) bytes)" -ForegroundColor Green

# 2. Guardar logo_b64.txt
$b64 = [System.Convert]::ToBase64String($png256Bytes)
$b64Path = Join-Path -Path $assetsDir -ChildPath "logo_b64.txt"
[System.IO.File]::WriteAllText($b64Path, $b64)
Write-Host "logo_b64.txt actualizado en $b64Path" -ForegroundColor Green

# 3. Compilar y guardar logo.ico multi-resolución en formato DIB de Windows
$bmpStream = [System.IO.MemoryStream]::new($png256Bytes)
$srcBmp = [System.Drawing.Bitmap]::FromStream($bmpStream)
$icoBytes = [TrueIcoBuilder]::CreateIco($srcBmp)
$srcBmp.Dispose()
$bmpStream.Dispose()

$icoPath = Join-Path -Path $assetsDir -ChildPath "logo.ico"
[System.IO.File]::WriteAllBytes($icoPath, $icoBytes)
Write-Host "logo.ico generado con éxito en $icoPath ($($icoBytes.Length) bytes)" -ForegroundColor Green
