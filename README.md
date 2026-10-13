# fnaf4-decompiled - Cloud build to bypass Termux

Repo: https://github.com/hipliteidk-glitch/fnaf4-decompiled

## Your current Termux status (fixed)
- ~/fnaf4_chowdren_out/fnaf4.exe = 445MB exists
- AnacondaPure_clean/build.py already correct (directive_defaults = Options.get_directive_defaults())
- Your error was path typo + python2 usage. Use python3
- Bridge ONLINE: python 3.14.6, gh 2.101.0, dotnet 8.0.131

## How to upload 445MB exe to cloud (GitHub release, not git)
Because >100MB, don't git add it. Do:
```bash
cd ~/fnaf4_chowdren_out
 gh release create fnaf4-input fnaf4.exe --repo hipliteidk-glitch/fnaf4-decompiled --title "FNAF4 input" --notes "input exe"
```
Then trigger workflow manually:
- Go to Actions > Decompile FNAF4 to Chowdren APK > Run workflow

## Local fix (Termux)
```bash
cd ~/AnacondaPure_clean
python3 -m pip install Cython pillow
python3 -m py_compile build.py  # should be OK now
python3 build.py build_ext --inplace
python3 decompile.py ~/fnaf4_chowdren_out/fnaf4.exe ~/fnaf4_decompiled_out
```

## NebulaFD local (no libz.so error if you use dotnet run directly)
```bash
cd ~/NebulaFD
# if libz.so missing:
 pkg install zlib
 export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
 dotnet Nebula.CLI/bin/Debug/net8.0/Nebula.CLI.dll ~/fnaf4_chowdren_out/fnaf4.exe -o ~/fnaf4_decompiled_nebula -v
```

## Chowdren -> Android APK (after decompile)
```bash
git clone https://github.com/SHARD28/Chowdren-Enhanced
```
And build with cmake + ndk.
