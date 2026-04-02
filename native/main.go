package main

/*
#include <stdlib.h>
typedef void (*RevealerCallback)(const char* jsonPatch);
static inline void call_callback(RevealerCallback cb, const char* json) {
    cb(json);
}
*/
import "C"
import (
	"encoding/base64"
	"encoding/json"
	"sync"
	"time"
	"unsafe"
)


type ChusanParser interface {
	Parse() []byte }

type LaveritaV3Parser struct{}
func (p *LaveritaV3Parser) Parse() []byte {
		data := make([]byte, 48)
	data[0] = 0x01 	return data
}

type TasollerPlusParser struct{}
func (p *TasollerPlusParser) Parse() []byte { return make([]byte, 48) }

type TasollerV2Parser struct{}
func (p *TasollerV2Parser) Parse() []byte { return make([]byte, 48) }

type FallbackParser struct{}
func (p *FallbackParser) Parse() []byte { return make([]byte, 48) }

func getParser(minorType string) ChusanParser {
	switch minorType {
	case "Laverita":
		return &LaveritaV3Parser{}
	case "TASOLLER+":
		return &TasollerPlusParser{}
	case "TASOLLER":
		return &TasollerV2Parser{}
	default:
		return &FallbackParser{}
	}
}


var (
	mu             sync.Mutex
	stopCh         chan struct{}
	activeCallback C.RevealerCallback
	isRunning      bool
)

func revealer_register_callback(cb C.RevealerCallback) {
	mu.Lock()
	defer mu.Unlock()
	activeCallback = cb
}

func revealer_start(configStr *C.char) int32 {
	mu.Lock()
	defer mu.Unlock()

	if isRunning {
		return 0
	}

	conf := C.GoString(configStr)
	var config map[string]interface{}
	if err := json.Unmarshal([]byte(conf), &config); err != nil {
		return -1
	}

	stopCh = make(chan struct{})
	isRunning = true
	go runLoop(config)

	return 0
}

func revealer_stop() {
	mu.Lock()
	defer mu.Unlock()
	if isRunning {
		close(stopCh)
		isRunning = false
	}
}


func runLoop(config map[string]interface{}) {
		pollMs := 10 * time.Millisecond
	if val, ok := config["poll_ms"].(float64); ok {
		pollMs = time.Duration(val) * time.Millisecond
	}
	minorType, _ := config["minor"].(string)

		parser := getParser(minorType)
	ticker := time.NewTicker(pollMs)
	defer ticker.Stop()

	for {
		select {
		case <-stopCh:
			return
		case <-ticker.C:
						rawData := parser.Parse()

						b64Data := base64.StdEncoding.EncodeToString(rawData)

						patch := map[string]interface{}{
				"chusan_raw": b64Data,
				"hex_line":   nil, 			}

			jsonBytes, _ := json.Marshal(patch)
			cStr := C.CString(string(jsonBytes))

			mu.Lock()
			if activeCallback != nil {
				C.call_callback(activeCallback, cStr)
			}
			mu.Unlock()

			C.free(unsafe.Pointer(cStr))
		}
	}
}

func main() {}