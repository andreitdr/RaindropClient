# Building on Windows

How to build and run RaindropClient on a Windows 10 or 11 (x64) machine from a fresh checkout. The
same list, in short, is at the top of [`windows/CMakeLists.txt`](../windows/CMakeLists.txt). CI
builds Windows on every push to `main` (see [CI and releases](ci-and-releases.md)), so if a local
build fails where CI does not, compare against what `ci.yml` sets up.

## What to install

| # | What | Why | Download |
|---|---|---|---|
| 1 | **Visual Studio 2022** (Community is fine) with the **Desktop development with C++** workload. That workload includes the MSVC v143 compiler, a Windows 10/11 SDK and CMake. | Flutter's Windows runner and every native plugin are C++, and Rust links with the MSVC linker. VS Code is not enough. | <https://visualstudio.microsoft.com/downloads/> |
| 2 | **Git for Windows** | Cloning, and Flutter itself needs Git. | <https://git-scm.com/downloads/win> |
| 3 | **Flutter SDK**, stable channel, on `PATH`. `pubspec.yaml` needs Dart 3.13.2 or newer, so use a current stable. | The app. | <https://docs.flutter.dev/get-started/install/windows/desktop> |
| 4 | **Rust** through **rustup**, with the default MSVC toolchain (`x86_64-pc-windows-msvc`) | The end-to-end encryption core (`../RaindropCrypto`) is Rust, compiled during `flutter build` by cargokit. | <https://rustup.rs/> |
| 5 | **Strawberry Perl** | SQLCipher builds a vendored OpenSSL from source, and OpenSSL's `Configure` needs a full Perl. Git's bundled Perl fails with `Locale::Maketext::Simple` missing. | <https://strawberryperl.com/> |
| 6 | **NASM**, with its folder added to `PATH` | OpenSSL's assembly is built with it. The installer puts it in `C:\Program Files\NASM` but **does not add it to `PATH`**, so add it yourself. | <https://www.nasm.us/pub/nasm/releasebuilds/> |
| 7 | **Developer Mode** on | Flutter links plugins with symlinks, and Windows only allows those in Developer Mode. Without it, `flutter pub get` stops with "Building with plugins requires symlink support". | <https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development> |

With `winget`, the installs (not the Visual Studio workload, Flutter or `PATH`) are:

```powershell
winget install Git.Git Rustlang.Rustup StrawberryPerl.StrawberryPerl NASM.NASM Microsoft.VisualStudio.2022.Community
```

Then:

- **Add the C++ workload.** Open the Visual Studio Installer → *Modify* → tick **Desktop
  development with C++**.
- **Add NASM to `PATH`.** Run `setx PATH "%PATH%;C:\Program Files\NASM"`, or use *System → About →
  Advanced system settings → Environment Variables*. Open a new terminal afterwards.
- **Switch on Developer Mode.** Run `start ms-settings:developers` and turn on *Developer Mode*.

Check everything from a **new** terminal:

```powershell
flutter doctor
rustc --version
perl -v
nasm -v
```

`flutter doctor` should show a tick for *Visual Studio – develop Windows apps*. `perl -v` should say
**Strawberry Perl**. If it names another Perl, move `C:\Strawberry\perl\bin` ahead of it on `PATH`,
or set `OPENSSL_SRC_PERL=C:\Strawberry\perl\bin\perl.exe`.

## Getting the code

The crypto plugin builds `../RaindropCrypto`, so the two repositories **must sit side by side** in
the same folder:

```powershell
mkdir C:\src\Raindrop
cd C:\src\Raindrop
git clone https://github.com/andreitdr/RaindropClient.git
git clone https://github.com/andreitdr/RaindropCrypto.git
```

RaindropCrypto is a separate repository, so your GitHub account needs access to it. Keep the parent
folder short (`C:\src\Raindrop` rather than somewhere deep under `Documents`). The Rust build is
already moved out of the way (see [Path length](#path-length)), but the rest of the build lives under
`RaindropClient\build`.

## Building and running

```powershell
cd C:\src\Raindrop\RaindropClient
flutter pub get
flutter run -d windows
```

`flutter run -d windows` builds a debug build and starts it. For a release build:

```powershell
flutter build windows --release
```

The release build lands in `build\windows\x64\runner\Release\`.

**The first build is slow**, typically several minutes. OpenSSL, SQLCipher and OpenMLS compile from
source, and flutter_webrtc and media_kit download prebuilt WebRTC and libmpv, so it also needs
internet access. Later builds only recompile what changed.

### Running the build on another PC

`raindrop_client.exe` needs the whole `Release\` folder next to it, and the PC needs the Visual C++
runtime. Either install the **Visual C++ Redistributable (x64)** there
(<https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist>), or copy the runtime DLLs
(`msvcp140*.dll`, `vcruntime140*.dll`) from
`C:\Program Files\Microsoft Visual Studio\2022\<edition>\VC\Redist\MSVC\<version>\x64\Microsoft.VC143.CRT\`
next to the exe. The second option is what [`release.yml`](../.github/workflows/release.yml) does for
the published `.zip`.

## Path length

OpenSSL's build tree is deep. Under cargokit's default folder
(`build\windows\x64\plugins\raindrop_crypto_ffi\cargokit_build\…`), its longest paths pass Windows'
260-character limit, and OpenSSL's Perl `Configure` fails with `No such file or directory`. So on
Windows, [`cargokit.cmake`](../native/raindrop_crypto_builder/cargokit/cmake/cargokit.cmake) builds the
Rust code in **`%LOCALAPPDATA%\rdcargo`**.

To use another folder, set `RAINDROP_CARGO_BUILD_DIR` before building. Keep it short; CI uses
`C:/ck`. Deleting the folder forces a full Rust rebuild, and nothing else is lost.

Turning on Windows' long-path support is optional, but it doesn't hurt:

```powershell
git config --global core.longpaths true
```

```powershell
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force
```

The second command needs an administrator PowerShell. It doesn't replace the short folder: MSBuild
and Perl don't all honour long paths.

## What works differently on Windows

- **Camera effects** (background blur and replacement) are not available. Windows has no processor
  chain to insert them into, so the effect picker is hidden. See
  [Voice → Camera effects](voice.md#camera-effects).
- **Scanning a device-link QR code** is not available, because `mobile_scanner` has no Windows
  implementation. Type the link code instead.
- **Sharing a window's sound** needs Windows 11, and is refused for any window that belongs to
  Raindrop itself. See [Voice → Screen sharing](voice.md#screen-sharing).
- Secrets are kept in the **Windows Credential Manager** (`flutter_secure_storage`).

## When it fails

| Error | Fix |
|---|---|
| `Building with plugins requires symlink support` | Turn on Developer Mode, then open a new terminal. |
| `Unable to find suitable Visual Studio toolchain` / `flutter doctor` has no Visual Studio tick | Install the *Desktop development with C++* workload. |
| `perl reported failure` or `Can't locate Locale/Maketext/Simple.pm` | The wrong Perl ran. Put Strawberry Perl first on `PATH`, or set `OPENSSL_SRC_PERL` to its `perl.exe`. |
| `'nasm' is not recognized` or `NASM not found` | Add `C:\Program Files\NASM` to `PATH` and open a new terminal. |
| `No such file or directory` from OpenSSL's `Configure` | Path too long. Set `RAINDROP_CARGO_BUILD_DIR` to a very short folder such as `C:\ck`, and move the checkout to a shorter path. |
| `could not find ...\RaindropCrypto\crates\raindrop_crypto_ffi` | RaindropCrypto is not cloned next to RaindropClient. |
| `cargo` / `rustup` not found during the build | Rust is not on the `PATH` the build sees. Open a new terminal after installing rustup. |
| The exe starts on your PC but not on another one (missing `MSVCP140.dll` / `VCRUNTIME140.dll`) | Install the Visual C++ Redistributable there, or copy the DLLs next to the exe. |
