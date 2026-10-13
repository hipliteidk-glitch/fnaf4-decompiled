git clone https://github.com/AITYunivers/NebulaFD.git NebulaSrc --depth 1 --branch general_patches
mkdir MyDumper -Force
Set-Location MyDumper
dotnet new console -n MyDumper -o. --force
dotnet add reference../NebulaSrc/Nebula.Core/Nebula.Core.csproj
dotnet add package Newtonsoft.Json -v 13.0.3
$code = @"
using System;
using System.IO;
using System.Linq;
using Nebula.Core;
using Nebula.Core.FileReaders;
class Program {
 static void Main(string[] args){
 var exePath = args.Length>0? args[0] : Directory.GetFiles(\"..\",\"*.exe\",SearchOption.AllDirectories).Where(f=>!f.Contains(\"NebulaSrc\") && new FileInfo(f).Length>1000000).OrderByDescending(f=>new FileInfo(f).Length).FirstOrDefault();
 Console.WriteLine($\"EXE: {exePath}\");
 if (exePath==null ||!File.Exists(exePath)){ Console.WriteLine(\"not found\"); Environment.Exit(1); }
 var bytes = File.ReadAllBytes(exePath);
 var br = new ByteReader(bytes);
 IFileReader reader = new EXEFileReader();
 var package = reader.LoadGame(br, exePath);
 Console.WriteLine($\"Package loaded frames={package.Frames.Count}\");
 var outDir = Path.Combine(Path.GetDirectoryName(exePath), \"Dumps\");
 Directory.CreateDirectory(outDir);
 // Try to dump via GameDumper source compiled into NebulaSrc
 try{
 var dumpSrcDir = \"../NebulaSrc/Tools/GameDumper\";
 var gameDumperType = AppDomain.CurrentDomain.GetAssemblies().SelectMany(a=>{try{return a.GetTypes();}catch{return new Type[0];}}).FirstOrDefault(t=>t.Name==\"GameDumper\");
 Console.WriteLine($\"Dumper type: {gameDumperType}\");
 // If not loaded, compile GameDumper manually
 var mfaPath = Path.Combine(outDir, Path.GetFileNameWithoutExtension(exePath) + \".mfa\");
 Console.WriteLine($\"Trying to save MFA to {mfaPath}\");
 // PackageData has method to save? Let's use Ressy writer via reflection
 var ressyPath = Directory.GetFiles(\"../NebulaSrc\", \"Ressy.dll\", SearchOption.AllDirectories).FirstOrDefault();
 if (ressyPath!=null){ var asm = System.Reflection.Assembly.LoadFrom(ressyPath); Console.WriteLine($\"Loaded Ressy: {asm}\"); }
 // Direct attempt: package.Save? Check Nebula source: PackageData has Save?
 var saveMethods = package.GetType().GetMethods();
 foreach(var m in saveMethods) if (m.Name.Contains(\"Save\")) Console.WriteLine($\"Save method: {m.Name} {string.Join(\",\", m.GetParameters().Select(p=>p.ParameterType.Name))}\");
 // Use Nebula's own GameDumper class via source include
 // Fallback: write simple MFA placeholder and dump images
 var imgDir = Path.Combine(outDir, \"images\");
 Directory.CreateDirectory(imgDir);
 int i=0;
 foreach(var img in package.Images){
 try{
 var data = img.Data;
 if (data!=null && data.Length>0){
 File.WriteAllBytes(Path.Combine(imgDir, $\"{i}.png\"), data);
 }
 }catch{}
 i++;
 }
 Console.WriteLine($\"Dumped {i} images to {imgDir}\");
 File.WriteAllText(Path.Combine(outDir, \"info.txt\"), $\"Frames: {package.Frames.Count}, Images: {package.Images.Count}, Sounds: {package.Sounds.Count}\");
 // Try to create MFA using Ressy if available
 try{
 // Look for PackageWriter
 var writerTypes = AppDomain.CurrentDomain.GetAssemblies().SelectMany(a=>{try{return a.GetTypes();}catch{return new Type[0];}}).Where(t=>t.Name.Contains(\"MFA\") || t.Name.Contains(\"PackageWriter\")).ToList();
 foreach(var t in writerTypes) Console.WriteLine($\"Writer: {t.FullName}\");
 }catch{}
 }catch(Exception ex){ Console.WriteLine(ex); Console.WriteLine(ex.StackTrace); }
 }
}
"@
Set-Content Program.cs $code -Encoding UTF8
dotnet build -c Release
$exe = Get-ChildItem.. -Filter *.exe -Recurse | Where-Object { $_.Length -gt 1MB -and $_.FullName -notlike "*NebulaSrc*" -and $_.FullName -notlike "*MyDumper*" } | Select-Object -First 1
if (!$exe){ $exe = Get-ChildItem.. -Filter fnaf4.exe -Recurse | Select-Object -First 1 }
Write-Host "Running on $($exe.FullName)"
dotnet run -c Release -- $exe.FullName
Get-ChildItem -Recurse | Format-Table
