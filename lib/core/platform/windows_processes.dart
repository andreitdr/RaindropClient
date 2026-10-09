/// Which process owns a window, and which processes this one descends from —
/// asked of Windows directly, for one decision: whether a window's own sound
/// can be shared without sending more than that window.
///
/// flutter_webrtc captures a window's sound with WASAPI *process-tree*
/// loopback: the window's process and every process it started. That is
/// exactly right for a browser, whose sound comes from a child process, and
/// badly wrong for Explorer, which started nearly everything on the desktop —
/// Raindrop included. Sharing an Explorer window with sound would send every
/// app's sound, and the call itself back into the call. [windowAudioRefusal]
/// is the rule; this file only answers its questions.
///
/// Every function here calls Windows and may only run there.
/// `platform_info.dart` decides when they are called; nothing here branches on
/// the platform itself, and nothing is loaded until a function is called, so
/// importing this file anywhere is safe.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Why a window's sound cannot be shared, or null when it can.
///
/// Refused for a window this process owns — sharing Raindrop's own sound
/// would send the call back into itself — and for a window owned by any of
/// this process's ancestors, whose process tree contains Raindrop and,
/// usually, much else besides. Kept free of Windows so the rule can be
/// tested anywhere.
String? windowAudioRefusal({
  required int windowProcessId,
  required int thisProcessId,
  required List<int> thisProcessAncestors,
}) {
  if (windowProcessId == thisProcessId) {
    return "That is Raindrop's own window — sharing its sound would send the "
        'call back into itself.';
  }
  if (thisProcessAncestors.contains(windowProcessId)) {
    return "That window's sound comes with every app it started, Raindrop "
        "included, so it can't be shared on its own.";
  }
  return null;
}

/// The id of the process that owns window [hwnd], or null when it is gone.
int? windowProcessId(int hwnd) {
  final pid = calloc<Uint32>();
  try {
    final thread = _getWindowThreadProcessId(hwnd, pid);
    return thread == 0 || pid.value == 0 ? null : pid.value;
  } finally {
    calloc.free(pid);
  }
}

/// Whether window [hwnd] still exists.
bool windowExists(int hwnd) => _isWindow(hwnd) != 0;

/// This process's id.
int get thisProcessId => _getCurrentProcessId();

/// This process's parent, its parent's parent, and so on, nearest first.
///
/// From one snapshot of every process. Windows reuses a process id once its
/// owner exits, so an ancestor that has since exited may stand for an
/// unrelated process here; the only effect is refusing a window's sound that
/// could have been shared, which is the safe way to be wrong.
List<int> thisProcessAncestors() {
  final parents = <int, int>{};

  final snapshot = _createToolhelp32Snapshot(_th32csSnapProcess, 0);
  if (snapshot == _invalidHandleValue) return const [];

  final entry = calloc<_ProcessEntry32W>();
  try {
    entry.ref.dwSize = sizeOf<_ProcessEntry32W>();
    var more = _process32FirstW(snapshot, entry) != 0;
    while (more) {
      parents[entry.ref.th32ProcessID] = entry.ref.th32ParentProcessID;
      more = _process32NextW(snapshot, entry) != 0;
    }
  } finally {
    calloc.free(entry);
    _closeHandle(snapshot);
  }

  final ancestors = <int>[];
  var current = thisProcessId;
  // Bounded, because ids are reused and a reused id can make a loop.
  for (var hop = 0; hop < 32; hop++) {
    final parent = parents[current];
    if (parent == null || parent == 0 || ancestors.contains(parent)) break;
    ancestors.add(parent);
    current = parent;
  }
  return ancestors;
}

// ── Windows ─────────────────────────────────────────────────────────────────

const _th32csSnapProcess = 0x00000002;
const _invalidHandleValue = -1;

/// `PROCESSENTRY32W`. The FFI lays it out with the platform's own padding,
/// which is what `ULONG_PTR` as an [IntPtr] is for.
final class _ProcessEntry32W extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int cntUsage;

  @Uint32()
  external int th32ProcessID;

  @IntPtr()
  external int th32DefaultHeapID;

  @Uint32()
  external int th32ModuleID;

  @Uint32()
  external int cntThreads;

  @Uint32()
  external int th32ParentProcessID;

  @Int32()
  external int pcPriClassBase;

  @Uint32()
  external int dwFlags;

  @Array(260)
  external Array<Uint16> szExeFile;
}

final _user32 = DynamicLibrary.open('user32.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _getWindowThreadProcessId = _user32
    .lookupFunction<
      Uint32 Function(IntPtr, Pointer<Uint32>),
      int Function(int, Pointer<Uint32>)
    >('GetWindowThreadProcessId');

final _isWindow = _user32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsWindow');

final _getCurrentProcessId = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetCurrentProcessId');

final _createToolhelp32Snapshot = _kernel32
    .lookupFunction<IntPtr Function(Uint32, Uint32), int Function(int, int)>(
      'CreateToolhelp32Snapshot',
    );

final _process32FirstW = _kernel32
    .lookupFunction<
      Int32 Function(IntPtr, Pointer<_ProcessEntry32W>),
      int Function(int, Pointer<_ProcessEntry32W>)
    >('Process32FirstW');

final _process32NextW = _kernel32
    .lookupFunction<
      Int32 Function(IntPtr, Pointer<_ProcessEntry32W>),
      int Function(int, Pointer<_ProcessEntry32W>)
    >('Process32NextW');

final _closeHandle = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
