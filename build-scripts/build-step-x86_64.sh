#!/bin/bash

export ARCH="x86_64"
export WIN_ARCH="x86_64,i386"
export OUTPUT_DIR="$HOME/compiled-files-x86_64"

export deps="$HOME/termuxfs/x86_64/data/data/com.termux/files/usr"
export RUNTIME_PATH="/data/data/com.termux/files/usr"
export install_dir=$deps/../opt/wine

#export TOOLCHAIN="$HOME/Android/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin"
export TOOLCHAIN="$HOME/Android/Sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/linux-x86_64/bin"
export LLVM_MINGW_TOOLCHAIN="$HOME/toolchains/llvm-mingw-20250920-ucrt-ubuntu-22.04-x86_64/bin"
export TARGET=x86_64-linux-android28
export PATH=$LLVM_MINGW_TOOLCHAIN:$PATH

export CC=$TOOLCHAIN/$TARGET-clang
export AS=$CC
export CXX=$TOOLCHAIN/$TARGET-clang++
export AR=$TOOLCHAIN/llvm-ar
export LD=$TOOLCHAIN/ld
export RANLIB=$TOOLCHAIN/llvm-ranlib
export STRIP=$TOOLCHAIN/llvm-strip
export DLLTOOL=$LLVM_MINGW_TOOLCHAIN/llvm-dlltool

export PKG_CONFIG_LIBDIR=$deps/lib/pkgconfig:$deps/share/pkgconfig
export ACLOCAL_PATH=$deps/lib/aclocal:$deps/share/aclocal
export CPPFLAGS="-I$deps/include --sysroot=$TOOLCHAIN/../sysroot"

export C_OPTS="-march=x86-64 -mtune=generic -Wno-declaration-after-statement -Wno-implicit-function-declaration -Wno-int-conversion"
export CFLAGS=$C_OPTS
export CXXFLAGS=$C_OPTS
export LDFLAGS="-L$deps/lib -Wl,-rpath=$RUNTIME_PATH/lib"

export FREETYPE_CFLAGS="-I$deps/include/freetype2"
export PULSE_CFLAGS="-I$deps/include/pulse"
export PULSE_LIBS="-L$deps/lib/pulseaudio -lpulse"
export SDL2_CFLAGS="-I$deps/include/SDL2"
export SDL2_LIBS="-L$deps/lib -lSDL2"
export X_CFLAGS="-I$deps/include/X11"
export X_LIBS=""
export GSTREAMER_CFLAGS="-I$deps/include/gstreamer-1.0 -I$deps/include/glib-2.0 -I$deps/lib/glib-2.0/include -I$deps/glib-2.0/include -I$deps/lib/gstreamer-1.0/include"
export GSTREAMER_LIBS="-L$deps/lib -lgstgl-1.0 -lgstapp-1.0 -lgstvideo-1.0 -lgstaudio-1.0 -lglib-2.0 -lgobject-2.0 -lgio-2.0 -lgsttag-1.0 -lgstbase-1.0 -lgstreamer-1.0"
export FFMPEG_CFLAGS="-I$deps/include/libavutil -I$deps/include/libavcodec -I$deps/include/libavformat"
export FFMPEG_LIBS="-L$deps/lib -lavutil -lavcodec -lavformat"

for arg in "$@"
do
  if [ "$arg" == "--build-sysvshm" ];
  then
    # Build android_sysvshm library
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

    if [ -d "$PROJECT_ROOT/android/android_sysvshm" ]; then
        echo "Building android_sysvshm library..."
        cd "$PROJECT_ROOT/android/android_sysvshm"
        ./build-x86_64.sh
        if [ $? -eq 0 ]; then
            echo "android_sysvshm built successfully"
            # Copy the library to deps/lib for linking
            mkdir -p "$deps/lib"
            cp build-x86_64/libandroid-sysvshm.so "$deps/lib/"
            echo "Copied libandroid-sysvshm.so to $deps/lib/"
        else
            echo "Warning: android_sysvshm build failed"
        fi
        cd "$PROJECT_ROOT"
    fi
  fi

  if [ "$arg" == "--configure" ];
  then
    ./configure \
      --enable-archs=$WIN_ARCH \
      --host=$TARGET \
      --prefix $install_dir \
      --bindir $install_dir/bin \
      --libdir $install_dir/lib \
      --exec-prefix $install_dir \
      --with-mingw=clang \
      --with-wine-tools=./wine-tools \
      --enable-win64 \
      --disable-win16 \
      --enable-nls \
      --disable-amd_ags_x64 \
      --enable-wineandroid_drv=no \
      --disable-tests \
      --with-alsa \
      --without-capi \
      --without-coreaudio \
      --without-cups \
      --without-dbus \
      --without-ffmpeg \
      --with-fontconfig \
      --with-freetype \
      --without-gcrypt \
      --without-gettext \
      --with-gettextpo=no \
      --without-gphoto \
      --with-gnutls \
      --without-gssapi \
      --with-gstreamer \
      --without-inotify \
      --without-krb5 \
      --without-netapi \
      --without-opencl \
      --with-opengl \
      --without-osmesa \
      --without-oss \
      --without-pcap \
      --without-pcsclite \
      --without-piper \
      --with-pthread \
      --with-pulse \
      --without-sane \
      --with-sdl \
      --without-udev \
      --without-unwind \
      --without-usb \
      --without-v4l2 \
      --without-vosk \
      --with-vulkan \
      --without-wayland \
      --without-xcomposite \
      --with-xcursor \
      --without-xfixes \
      --without-xinerama \
      --without-xinput \
      --without-xinput2 \
      --without-xrandr \
      --without-xrender \
      --without-xshape \
      --without-xshm \
      --without-xxf86vm

    echo "Applying patches..."

    PATCHES=(
      "0001-fixup-ntdll-Wait-for-thread-suspension-in-NtSuspendT.patch"
      "0045-ntdll-remove-outdated-workaround-for-rainbow-six-ext.patch"
      "0101-ntdll-Add-a-stub-for-NtCreateSectionEx.patch"
      "0126-ntdll-Also-trap-syscalls-in-the-top-down-reserved-ar.patch"
      "0186-ntdll-Update-version-resource.patch"
      "0199-ntdll-Add-FIXME-to-SystemModuleInformation.patch"
      "0208-ntdll-Silence-the-noisy-FIXME-in-RtlGetCurrentProces.patch"
      "0209-ntdll-Don-t-skip-synchronous-read-when-serial-read-t.patch"
      "0218-ntdll-Add-sys_membarrier-based-implementation-of-NtF.patch"
      "0220-ntdll-Implement-querying-StorageDeviceProperty-for-o.patch"
      "0221-ntdll-Validate-fd-type-in-IOCTL_AFD_WINE_COMPLETE_AS.patch"
      "0223-ntdll-Use-signed-type-for-IAT-offset-in-LdrResolveDe.patch"
      "0229-ntdll-Return-an-error-if-count-is-zero-in-NtRemoveIo.patch"
      "0237-ntdll-Align-records-retrieved-by-SystemProcessInform.patch"
      "0240-ntdll-Also-relocate-entry-point-for-builtin-modules.patch"
      "0245-ntdll-Use-the-InitializeObjectAttributes-macro-in-mo.patch"
      "0252-ntdll-Correct-NtAllocateReserveObject-arguments-in-s.patch"
      "0267-ntdll-Avoid-evaluating-a-possibly-uninitialized-vari.patch"
      "0299-ntdll-Fix-a-buffer-overflow-in-wcsncpy.patch"
      "0309-ntdll-Consistently-output-one-loaddll-trace-per-modu.patch"
      "0325-ntdll-Check-for-invalid-gs_base-in-the-64-bit-segv_h.patch"
      "0333-ntdll-Fix-inconsistency-in-LFH-block-size-calculatio.patch"
      "0334-ntdll-Make-server-requests-robust-to-spurious-short-.patch"
      "0340-ntdll-Use-the-bundled-tomcrypt-for-the-crc32-impleme.patch"
      "0356-ntdll-Stop-unwinding-on-access-violation.patch"
      "0373-ntdll-Reimplement-NtWaitForSingleObject-without-NtWa.patch"
      "0468-ntdll-Add-some-special-XDG-env-vars.patch"
      "0477-ntdll-Do-not-rely-on-CLOCK_REALTIME_COURSE-for-NtQue.patch"
      "0485-ntdll-Avoid-infinite-wait-during-process-termination.patch"
      "0009-HACK-kernel32-Spoof-GetProcAddress-of-KiUserApcDispa.patch"
      "0099-kernel32-Implement-timeGetTime.patch"
      "0197-kernel32-Implement-VirtualProtectFromApp.patch"
      "0207-kernel32-Add-some-stubs-for-chromium.patch"
      "0222-kernel32-Implement-SetThreadpoolTimerEx.patch"
      "0100-kernelbase-Implement-HeapSummary.patch"
      "0102-kernelbase-Implement-CreateFileMapping2.patch"
      "0215-kernelbase-Add-stub-for-GetCurrentApplicationUserMod.patch"
      "0370-kernelbase-Use-NT_ERROR-to-check-for-errors-in-WaitF.patch"
      "0371-kernelbase-Reimplement-WaitForSingleObject-Ex-on-top.patch"
      
      "0116-winex11-Extend-cursor_pos-using-cursor_begin-cursor_.patch"
      "0212-winex11.drv-Don-t-add-MWM_DECOR_BORDER-to-windows-wi.patch"
      "0001-win32u-add-env-switch-to-disable-wm-decorations.patch"
      "0216-win32u-Add-stub-for-NtUserSetAdditionalForegroundBoo.patch"
      "0368-win32u-Reset-internal-pixel-format-when-pixel-format.patch"
      "0390-win32u-Ignore-deadkeys-in-kbd_tables_init_vk2char.patch"
      "0408-HACK-win32u-Avoid-divide-by-0-when-querying-monitor-.patch"
      "0464-win32u-Avoid-setting-surface-layered-with-the-dummy-.patch"
      "0107-opengl32-Improve-wow64-mapping-performance-by-20x.patch"
      "0404-server-Use-correct-keystate-for-VK_NUMLOCK.patch"
      "0253-server-Use-a-high-precision-timespec-directly-for-po.patch"

      "0079-winegstreamer-disable-media-converter.patch"
      "0467-dmo-Do-not-rely-on-mediaconv-unless-avformat-cannot-.patch"
      "0469-Revert-HACK-mfplat-Use-the-MP4-bytestream-handler-as.patch"
      "0474-HACK-winegstreamer-Add-semi-stub-for-GetAttributeInd.patch"
      "add-envvar-to-gate-media-converter.patch"
      "proton-use_winegstreamer_and_set_orientation-PROTON_MEDIA_USE_GST-PROTON_GST_VIDEO_ORIENTATION.patch"
      "winealsa-override-channel-count.patch"
      "winepulse-fast-polling.patch"
      "0062-winedmo-Fix-double-free.patch"
      "0304-fluidsynth-Fix-g_atomic_int_add-return-value.patch"

      "0122-ntoskrnl.exe-tests-Improve-device-properties-test-av.patch"
      "0127-ntoskrnl.exe-Implement-KeAcquireGuardedMutex.patch"
      "0152-ntoskrnl-Implement-some-instructions-used-for-VM-det.patch"
      "0153-ntoskrnl-Fixup-control-register-emulation-on-amd64.patch"
      "0154-wdfldr.sys-Add-stub-dll.patch"
      "0157-ntoskrnl-Add-stub-for-VslGetSecurePciEnabled.patch"
      "0158-ntoskrnl-Implement-PsGetProcessPeb.patch"
      "0159-ntoskrnl-Implement-ProbeForWrite.patch"
      "0161-ntoskrnl-Implement-PsGetProcessSessionId.patch"
      "0163-ntoskrnl-Implement-PsGetThreadProcess.patch"
      "0164-ntoskrnl-Implement-PsGetCurrentThreadTeb.patch"
      "0167-ntoskrnl-Add-stub-for-KeRegisterBugCheckCallback.patch"
      "0172-ntoskrnl-Add-semi-stub-for-MmGetVirtualForPhysical.patch"
      "0176-ntoskrnl-Implement-SeQueryInformationToken.patch"
      "0177-ntoskrnl-Implement-PsGetContextThread.patch"
      "0181-ntoskrnl-Add-stub-for-KeCapturePersistentThreadState.patch"
      "0184-ntoskrnl-Add-semi-stub-for-IoGetBaseFileSystemDevice.patch"
      "0185-ntoskrnl-hal-Add-some-exports.patch"
      "0200-mountmgr.sys-Add-stub-for-StorageDeviceTrimProperty.patch"

      "0265-msvcrt-Add-MSVCRT__NOBUF-flag-check-in-_filbuf-to-av.patch"
      "0266-msvcrt-Update-file-position-in-_flsbuf-in-append-mod.patch"
      "0289-msvcrt-Concurrency-Fix-signed-unsigned-comparison.patch"
      "0335-msvcrt-Add-missing-TRACE_ON-check.patch"
      "0336-msvcrt-Fix-memory-leaks-in-create_locinfo.patch"
      "0250-shell32-Added-stub-for-IEnumObjects-interface.patch"
      "0259-shcore-Implement-OS_TABLETPC-and-OS_MEDIACENTER.patch"
      "0210-wineboot-Fetch-the-list-of-supported-machines-once-a.patch"
      "wineboot-ProxySettings.patch"
      "0227-dwmapi-Do-not-prefer-native-dll.patch"
      "0357-coremessaging-Add-IDispatcherQueueControllerStatics-.patch"

      "assettocorsa-hud.patch"
      "pso2_hack.patch"
      "0236-HACK-wine.inf-Add-workaround-for-WRC9.patch"
      "0097-wine.inf-Add-override-for-diabotical.patch"
      "0409-HACK-wine.inf-Allow-builtin-for-vulkan-1-in-RDR2.patch"
      "silence-starcitizen-unsupported-os.patch"
      "unity_crash_hotfix.patch"
      "dai_xinput.patch"
      "vgsoh.patch"
      "0032-Avoid-long-types-on-the-Unix-side.patch"
      "0035-wine.inf-Don-t-clobber-UBR-key.patch"
      "0036-twinapi.appcore-tests-Fix-broken-registry-query.patch"
      "0037-winecfg-Add-support-for-UBR-key.patch"
      "0211-cfgmgr32-Add-stub-for-CM_Unregister_Notification.patch"
      "0213-powrprof-Add-stub-for-PowerRegisterForEffectivePower.patch"
      "0214-combase-Add-a-stub-for-SetRestrictedErrorInfo.patch"
      "0417-advapi32-Add-semi-stub-for-RegCreateKeyTransacted-A-.patch"
      "8848.patch"
      "NCryptDecrypt_implementation.patch"
      "cryptext-CryptExtOpenCER.patch"
      "fix-a-crash-in-ID2D1DeviceContext-if-no-target-is-set.patch"
      "registry_RRF_RT_REG_SZ-RRF_RT_REG_EXPAND_SZ.patch"
      "wine_host_block_envvar.patch"
      "0231-server-Fix-incorrect-usage-of-__WINE_ATOMIC_STORE_RE.patch"
      "0232-include-Prevent-misuse-of-__WINE_ATOMIC_-helper-macr.patch"
      "0244-include-Move-InitializeObjectAttributes-definition-t.patch"
      "0328-include-Mark-global-asm-functions-as-hidden.patch"
      "0230-include-Fix-ReadNoFence64-on-i386.patch"
      
      # android network patch
      "android_network.patch"
      "dlls_nsiproxy_sys_ip_c.patch"

      # midi support
      "midi_support.patch"

      # sdl patch
      "dlls_winebus_sys_bus_sdl_c.patch"

      # shm_utils
      "dlls_ntdll_unix_esync_c.patch"
      "dlls_ntdll_unix_fsync_c.patch"
      "server_esync_c.patch"
      "server_fsync_c.patch"

      # winex11
      "dlls_winex11_drv_x11drv_h.patch"
      "dlls_winex11_drv_bitblt_c.patch"
      "dlls_winex11_drv_desktop_c.patch"
      "dlls_winex11_drv_mouse_c.patch"
      "dlls_winex11_drv_x11drv_main_c.patch"

      # address space patches
      "dlls_ntdll_unix_virtual_c.patch"
      "loader_preloader_c.patch"

      # syscall Patches
      "dlls_ntdll_unix_signal_x86_64_c.patch"

      # pulse Patches
      "dlls_winepulse_drv_pulse_c.patch"

      # desktop patches
      "programs_explorer_desktop_c.patch"

      # path patches
      "dlls_ntdll_unix_server_c.patch"

      # winlator patches
      "dlls_amd_ags_x64_unixlib_c.patch"
      "dlls_winex11_drv_opengl_c.patch"

      # shortcut patch
      "programs_winemenubuilder_winemenubuilder_c.patch"

      # advapi32 patches
      "dlls_advapi32_advapi_c.patch"

      # browser patches
      "programs_winebrowser_makefile_in.patch"
      "programs_winebrowser_main_c.patch"

      # clipboard patches
      "dlls_user32_makefile_in.patch"
      "dlls_user32_clipboard_c.patch"
      "dlls_win32u_clipboard_c.patch"
    )

    for patch in "${PATCHES[@]}"; do
#      if git apply --check ./android/patches/$patch 2>/dev/null; then
        git apply ./android/patches/$patch
#      fi
    done
  fi

  if [ "$arg" == "--build" ]
  then
    echo "Building..."
    rm -rf $OUTPUT_DIR/bin
    rm -rf $OUTPUT_DIR/lib
    rm -rf $OUTPUT_DIR/share
    rm -rf $install_dir
    make -j$(nproc)
  fi

  if [ "$arg" == "--install" ]
  then
    echo "Installing..."
    mkdir -p $OUTPUT_DIR/bin
    mkdir -p $OUTPUT_DIR/lib
    mkdir -p $OUTPUT_DIR/share
    mkdir -p $install_dir
    make install -j$(nproc)
    cp -r $install_dir/bin/wine* $OUTPUT_DIR/bin
    cp -r $install_dir/bin/reg* $OUTPUT_DIR/bin
    cp -r $install_dir/bin/msi* $OUTPUT_DIR/bin
    cp -r $install_dir/bin/notepad $OUTPUT_DIR/bin
    cp -r $install_dir/lib/wine  $OUTPUT_DIR/lib
    cp -r $install_dir/share/wine  $OUTPUT_DIR/share
  fi
done
