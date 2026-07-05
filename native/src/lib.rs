use std::ffi::{c_char, CStr, CString};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::thread::{self, JoinHandle};
use std::time::Duration;

use base64::Engine;
use serde::{Deserialize, Serialize};
use windows::Win32::Foundation::{CloseHandle, HANDLE};
use windows::Win32::System::Memory::{
    MapViewOfFile, UnmapViewOfFile, OpenFileMappingW, FILE_MAP_READ,
    MEMORY_MAPPED_VIEW_ADDRESS,
};
use windows::core::PCWSTR;

mod chu;
use chu::{ChusanData, ChusanParser};

// ---------------------------------------------------------------------------
// JSON structures (match Dart side exactly)
// ---------------------------------------------------------------------------

#[derive(Debug, Deserialize)]
struct RevealerConfig {
    #[allow(dead_code)]
    #[serde(rename = "majorType")]
    major_type: String,
    #[serde(rename = "minorType")]
    minor_type: String,
    #[serde(rename = "sharedMem")]
    shared_mem: String,
    #[serde(rename = "pollMs")]
    poll_ms: i32,
    #[serde(rename = "debugLevel")]
    debug_level: i32,
}

#[derive(Debug, Serialize, Default)]
struct RevealerPatch {
    #[serde(skip_serializing_if = "Option::is_none")]
    chusan_raw: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mu3_raw: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mai2_raw: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    hex_line: Option<String>,
}

// ---------------------------------------------------------------------------
// Global state (equivalent to Go's package-level vars)
// ---------------------------------------------------------------------------

static CALLBACK: Mutex<Option<extern "C" fn(*const c_char)>> = Mutex::new(None);

struct RunningState {
    stop_flag: Arc<AtomicBool>,
    thread_handle: Option<JoinHandle<()>>,
}

static RUNNING: Mutex<Option<RunningState>> = Mutex::new(None);

// ---------------------------------------------------------------------------
// C ABI exports
// ---------------------------------------------------------------------------

/// Register the callback function pointer that Dart/Flutter provides.
/// Called once before `revealer_start`.
#[no_mangle]
pub extern "C" fn revealer_register_callback(cb: Option<extern "C" fn(*const c_char)>) {
    let mut guard = CALLBACK.lock().unwrap();
    *guard = cb;
}

/// Start the shared-memory polling loop.
/// `config_ptr` – a C string containing JSON matching `RevealerConfig`.
/// Returns 0 on success, -1 on failure (fallback mode started).
#[no_mangle]
pub extern "C" fn revealer_start(config_ptr: *const c_char) -> i32 {
    if config_ptr.is_null() {
        return -1;
    }

    let config_str = match unsafe { CStr::from_ptr(config_ptr).to_str() } {
        Ok(s) => s.to_owned(),
        Err(_) => return -1,
    };

    let config: RevealerConfig = match serde_json::from_str(&config_str) {
        Ok(c) => c,
        Err(_) => {
            // Fallback (same behavior as original Go code)
            let fallback = RevealerConfig {
                major_type: "Chusan".into(),
                minor_type: "Fallback".into(),
                shared_mem: String::new(),
                poll_ms: 100,
                debug_level: 0,
            };
            start_inner(fallback);
            return -1;
        }
    };

    start_inner(config);
    0
}

/// Stop the shared-memory polling loop and join the background thread.
#[no_mangle]
pub extern "C" fn revealer_stop() -> i32 {
    let mut guard = RUNNING.lock().unwrap();
    if let Some(state) = guard.take() {
        state.stop_flag.store(true, Ordering::SeqCst);
        if let Some(handle) = state.thread_handle {
            let _ = handle.join();
        }
    }
    0
}

/// Free a C string previously allocated by Rust and passed to Dart.
/// Called from Dart side after processing callback data.
#[no_mangle]
pub extern "C" fn revealer_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn start_inner(config: RevealerConfig) {
    let mut guard = RUNNING.lock().unwrap();

    // Stop any existing thread first
    if let Some(state) = guard.take() {
        state.stop_flag.store(true, Ordering::SeqCst);
        if let Some(handle) = state.thread_handle {
            let _ = handle.join();
        }
    }

    let stop_flag = Arc::new(AtomicBool::new(false));
    let thread_stop = stop_flag.clone();

    let handle = thread::spawn(move || {
        run_chusan_loop(config, thread_stop);
    });

    *guard = Some(RunningState {
        stop_flag,
        thread_handle: Some(handle),
    });
}

fn get_parser(minor_type: &str) -> Box<dyn ChusanParser> {
    match minor_type {
        "Rustnithm" => Box::new(chu::rustnithm::RustnithmParser),
        "Laverita" => Box::new(chu::laverita_v3::LaveritaV3Parser),
        "Yubideck" => Box::new(chu::yubideck::YubideckParser),
        "Tasoller+" => Box::new(chu::tasoller_p::TasollerPlusParser),
        "Tasoller" => Box::new(chu::tasoller_v2::TasollerV2Parser),
        _ => Box::new(chu::rustnithm::RustnithmParser),
    }
}

fn push_to_dart(patch: RevealerPatch) {
    let cb = {
        let guard = CALLBACK.lock().unwrap();
        *guard
    };

    if let Some(callback) = cb {
        if let Ok(json) = serde_json::to_string(&patch) {
            if let Ok(c_str) = CString::new(json) {
                // Intentionally leak -- Dart side will free via revealer_free_string
                let ptr = c_str.into_raw();
                callback(ptr as *const c_char);
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Shared memory polling loop (equivalent to chusan.go)
// ---------------------------------------------------------------------------

const MAX_INPUT_SIZE: usize = 48;

#[allow(unused_assignments)]
fn run_chusan_loop(config: RevealerConfig, stop_flag: Arc<AtomicBool>) {
    let poll_ms = if config.poll_ms > 0 {
        config.poll_ms as u64
    } else {
        10
    };
    let poll_duration = Duration::from_millis(poll_ms);

    let parser = get_parser(&config.minor_type);

    // Convert shared memory name to UTF-16
    let shmem_wide: Vec<u16> = config.shared_mem.encode_utf16().chain(std::iter::once(0)).collect();

    // Helper to open/close shared memory handles
    let mut handle: HANDLE = HANDLE::default();
    let mut addr: MEMORY_MAPPED_VIEW_ADDRESS = MEMORY_MAPPED_VIEW_ADDRESS::default();

    // Try initial connection
    unsafe {
        handle = OpenFileMappingW(FILE_MAP_READ.0, false, PCWSTR(shmem_wide.as_ptr()))
            .unwrap_or_default();
        if handle == HANDLE::default() {
            push_to_dart(RevealerPatch {
                hex_line: Some("[Wait] Waiting for Shared Memory...".into()),
                ..Default::default()
            });
        } else {
            addr = MapViewOfFile(handle, FILE_MAP_READ, 0, 0, 0);
            if !addr.Value.is_null() {
                push_to_dart(RevealerPatch {
                    hex_line: Some(format!("[Info] {} Connected.", config.minor_type)),
                    ..Default::default()
                });
            } else {
                let _ = CloseHandle(handle);
                handle = HANDLE::default();
            }
        }
    }

    // Polling loop
    while !stop_flag.load(Ordering::SeqCst) {
        thread::sleep(poll_duration);

        if stop_flag.load(Ordering::SeqCst) {
            break;
        }

        unsafe {
            if addr.Value.is_null() {
                // Try to reconnect
                handle = OpenFileMappingW(FILE_MAP_READ.0, false, PCWSTR(shmem_wide.as_ptr()))
                    .unwrap_or_default();
                if handle != HANDLE::default() {
                    addr = MapViewOfFile(handle, FILE_MAP_READ, 0, 0, 0);
                    if !addr.Value.is_null() {
                        push_to_dart(RevealerPatch {
                            hex_line: Some("[Info] Shmem Connected.".into()),
                            ..Default::default()
                        });
                    } else {
                        let _ = CloseHandle(handle);
                        handle = HANDLE::default();
                    }
                }
                continue;
            }

            // Read raw bytes from shared memory
            let raw = std::slice::from_raw_parts(addr.Value as *const u8, MAX_INPUT_SIZE);
            let data = parser.parse(raw);
            let logic_bytes = data.serialize();
            let encoded = base64::engine::general_purpose::STANDARD.encode(&logic_bytes);

            let mut patch = RevealerPatch {
                chusan_raw: Some(encoded),
                ..Default::default()
            };

            if config.debug_level > 0 {
                patch.hex_line = Some(format_hex_line(parser.get_name(), raw, &data));
            }

            push_to_dart(patch);
        }
    }

    // Cleanup
    unsafe {
        if !addr.Value.is_null() {
            let _ = UnmapViewOfFile(addr);
            addr = MEMORY_MAPPED_VIEW_ADDRESS::default();
        }
        if handle != HANDLE::default() {
            let _ = CloseHandle(handle);
            handle = HANDLE::default();
        }
    }
}

fn format_hex_line(name: &str, raw: &[u8], data: &ChusanData) -> String {
    let air_str: String = data.air.iter().map(|&b| if b { '1' } else { '0' }).collect();
    let short_name = if name.len() > 4 { &name[..4] } else { name };
    let max_preview = raw.len().min(8);
    format!(
        "[{}] {}... | AIR:{} | TEST:{}",
        short_name,
        raw[..max_preview].iter().map(|b| format!("{:02X}", b)).collect::<String>(),
        air_str,
        data.test as u8
    )
}
