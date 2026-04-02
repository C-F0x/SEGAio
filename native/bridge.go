package main

/*
#include <stdint.h>
#include <stdlib.h>
typedef void (*callback_t)(const char*);
static void call_callback(callback_t cb, const char* json) {
    cb(json);
}
*/
import "C"
import (
	"encoding/json"
	"sync"
	"unsafe"
	"revealer/native/chu"
)

var (
	currCallback C.callback_t
	stopCh       chan struct{}
	wg           sync.WaitGroup
	mu           sync.Mutex
	isRunning    bool
)

type RevealerConfig struct {
	MajorType  string `json:"majorType"`
	MinorType  string `json:"minorType"`
	PollMs     int    `json:"pollMs"`
	DebugLevel int    `json:"debugLevel"`
}

type RevealerPatch struct {
	ChusanRaw string `json:"chusan_raw,omitempty"`
	HexLine   string `json:"hex_line,omitempty"`
}

func revealer_register_callback(cb C.callback_t) {
	mu.Lock()
	defer mu.Unlock()
	currCallback = cb
}

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


func revealer_stop() int32 {
	mu.Lock()
	defer mu.Unlock()

	if isRunning {
		close(stopCh)
		isRunning = false
	}
	return 0
}

func pushToDart(patch RevealerPatch) {
	if currCallback == nil {
		return
	}

	bytes, _ := json.Marshal(patch)
	cStr := C.CString(string(bytes))
	defer C.free(unsafe.Pointer(cStr))
	C.call_callback(currCallback, cStr)
}

type FallbackParser struct{ chu.RustnithmParser }

func main() {}