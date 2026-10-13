git clone https://github.com/AITYunivers/NebulaFD.git NebulaSrc --depth 1 --branch general_patches -q
if (!(Test-Path NebulaSrc)) { git clone https://github.com/AITYunivers/NebulaFD.git NebulaSrc --depth 1 -q }
New-Item -ItemType Directory -Force -Path MyDumper | Out-Null
Set-Location MyDumper
dotnet new console -n MyDumper -o. --force | Out-Null
dotnet add reference../NebulaSrc/Nebula.Core/Nebula.Core.csproj | Out-Null
dotnet add package Newtonsoft.Json -v 13.0.3 | Out-Null
@'
using System;
using System.IO;
using System.Linq;
using Nebula.Core;
using Nebula.Core.FileReaders;
class Program {
 static void Main(string[] args){
 var exePath = args.Length>0? args[0] : Directory.GetFiles("..","*.exe",SearchOption.AllDirectories).Where(f=>!f.Contains("NebulaSrc") && new FileInfo(f).Length>1000000).OrderByDescending(f=>new FileInfo(f).Length).FirstOrDefault();
 Console.WriteLine($"EXE: {exePath}");
 if (exePath==null ||!File.Exists(exePath)){ Console.WriteLine("not found"); Environment.Exit(1); }
 var bytes = File.ReadAllBytes(exePath);
 var br = new ByteReader(bytes);
 IFileReader reader = new EXEFileReader();
 var package = reader.LoadGame(br, exePath);
 Console.WriteLine($"Package loaded frames={package.Frames.Count} images={package.Images.Count} sounds={package.Sounds.Count}");
 var outDir = Path.Combine(Path.GetDirectoryName(exePath), "Dumps");
 Directory.CreateDirectory(outDir);
 var imgDir = Path.Combine(outDir, "images");
 Directory.CreateDirectory(imgDir);
 int i=0;
 foreach(var img in package.Images){
 try{
 var data = img.Data;
 if (data!=null && data.Length>0){
 File.WriteAllBytes(Path.Combine(imgDir, $"{i}.png"), data);
 }
 }catch(Exception ex){ Console.WriteLine(ex.Message); }
 i++;
 }
 File.WriteAllText(Path.Combine(outDir, "info.txt"), $"Frames: {package.Frames.Count}, Images: {package.Images.Count}, Sounds: {package.Sounds.Count}");
 Console.WriteLine($"Dumped {i} images");
 // Try to find MFA writer
 var methods = package.GetType().GetMethods();
 foreach(var m in methods) Console.WriteLine($"Method {m.Name}");
 }
}
'@ | Set-Content Program.cs -Encoding UTF8
dotnet build -c Release
$exe = Get-ChildItem.. -Filter *.exe -Recurse | Where-Object { $_.Length -gt 1MB -and $_.FullName -notlike "*NebulaSrc*" -and $_.FullName -notlike "*MyDumper*" } | Select-Object -First 1
if (!$exe){ $exe = Get-ChildItem.. -Filter *.exe -Recurse | Select-Object -First 1 }
Write-Host "Running on $($exe.FullName)"
dotnet run -c Release -- $exe.FullName
Get-ChildItem -Recurse | Format-Table
