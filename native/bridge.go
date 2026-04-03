package main

/*
#include <stdint.h>
#include <stdlib.h>

typedef void (*callback_t)(const char*);

static inline void call_callback(callback_t cb, const char* json) {
    if (cb != NULL) {
        cb(json);
    }
}
*/
import "C"
import (
	"encoding/json"
	"sync"
	"unsafe"
)

var (
	currCallback C.callback_t
	stopCh       chan struct{}
	mu           sync.Mutex
	isRunning    bool
)

type RevealerConfig struct {
	MajorType     string `json:"majorType"`
	MinorType     string `json:"minorType"`
	SharedMemName string `json:"sharedMemName"`
	PollMs        int    `json:"pollMs"`
	DebugLevel    int    `json:"debugLevel"`
}

type RevealerPatch struct {
	ChusanRaw string `json:"chusan_raw,omitempty"`
	Mu3Raw    string `json:"mu3_raw,omitempty"`
	Mai2Raw   string `json:"mai2_raw,omitempty"`
	HexLine   string `json:"hex_line,omitempty"`
}

//export revealer_register_callback
func revealer_register_callback(cb C.callback_t) {
	mu.Lock()
	defer mu.Unlock()
	currCallback = cb
}

//export revealer_start
func revealer_start(configPtr *C.char) int32 {
	mu.Lock()
	defer mu.Unlock()
	if isRunning {
		return 0
	}

	configStr := C.GoString(configPtr)
	var config RevealerConfig
	if err := json.Unmarshal([]byte(configStr), &config); err != nil {
		stopCh = make(chan struct{})
		isRunning = true
		go runChusanLoop(RevealerConfig{MajorType: "Chusan", MinorType: "Fallback", PollMs: 100})
		return -1
	}

	stopCh = make(chan struct{})
	isRunning = true

	go runChusanLoop(config)
	return 0
}

//export revealer_stop
func revealer_stop() int32 {
	mu.Lock()
	defer mu.Unlock()

	if isRunning {
		if stopCh != nil {
			close(stopCh)
			stopCh = nil
		}
		isRunning = false
	}
	return 0
}

func revealer_free_string(ptr *C.char) {
	C.free(unsafe.Pointer(ptr))
}

func pushToDart(patch RevealerPatch) {
	mu.Lock()
	cb := currCallback
	mu.Unlock()

	if cb == nil {
		return
	}

	bytes, _ := json.Marshal(patch)
	cStr := C.CString(string(bytes))
	C.call_callback(cb, cStr)
}

func main() {}