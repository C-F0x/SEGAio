package main

import (
	"encoding/base64"
	"fmt"
	"syscall"
	"time"
	"unsafe"

	"revealer/chu"
)

var (
	modKernel32          = syscall.NewLazyDLL("kernel32.dll")
	procOpenFileMappingW = modKernel32.NewProc("OpenFileMappingW")
	procMapViewOfFile    = modKernel32.NewProc("MapViewOfFile")
	procUnmapViewOfFile  = modKernel32.NewProc("UnmapViewOfFile")
	procCloseHandle      = modKernel32.NewProc("CloseHandle")
)

const (
	MaxInputSize  = 48
	FILE_MAP_READ = 0x0004
)

func runChusanLoop(config RevealerConfig) {
	pollDuration := time.Duration(config.PollMs) * time.Millisecond
	if pollDuration <= 0 {
		pollDuration = 10 * time.Millisecond
	}

	parser := getParser(config.MinorType)
	shmemNamePtr, _ := syscall.UTF16PtrFromString(config.SharedMemName)

	var handle uintptr
	var addr uintptr

	cleanup := func() {
		if addr != 0 {
			procUnmapViewOfFile.Call(addr)
			addr = 0
		}
		if handle != 0 {
			procCloseHandle.Call(handle)
			handle = 0
		}
	}
	defer cleanup()

	h, _, _ := procOpenFileMappingW.Call(
		uintptr(FILE_MAP_READ),
		uintptr(0),
		uintptr(unsafe.Pointer(shmemNamePtr)),
	)
	if h != 0 {
		handle = h
		a, _, _ := procMapViewOfFile.Call(handle, uintptr(FILE_MAP_READ), 0, 0, 0)
		if a != 0 {
			addr = a
			pushToDart(RevealerPatch{HexLine: fmt.Sprintf("[Info] %s Connected.", config.MinorType)})
		}
	} else {
		pushToDart(RevealerPatch{HexLine: "[Wait] Waiting for Shared Memory..."})
	}

	ticker := time.NewTicker(pollDuration)
	defer ticker.Stop()

	for {
		select {
		case <-stopCh:
			return
		case <-ticker.C:
			if addr == 0 {
				h, _, _ := procOpenFileMappingW.Call(uintptr(FILE_MAP_READ), 0, uintptr(unsafe.Pointer(shmemNamePtr)))
				if h != 0 {
					handle = h
					a, _, _ := procMapViewOfFile.Call(handle, uintptr(FILE_MAP_READ), 0, 0, 0)
					if a != 0 {
						addr = a
						pushToDart(RevealerPatch{HexLine: "[Info] Shmem Connected."})
					} else {
						procCloseHandle.Call(handle)
						handle = 0
					}
				}
				continue
			}

			raw := (*[MaxInputSize]byte)(unsafe.Pointer(addr))[:]
			data := parser.Parse(raw)
			logicBytes := data.Serialize()
			encoded := base64.StdEncoding.EncodeToString(logicBytes)

			patch := RevealerPatch{
				ChusanRaw: encoded,
			}

			if config.DebugLevel > 0 {
				patch.HexLine = formatHexLine(parser.GetName(), raw, data)
			}

			pushToDart(patch)
		}
	}
}

func getParser(minorType string) chu.ChusanParser {
	switch minorType {
	case "Rustnithm":
		return &chu.RustnithmParser{}
	case "Laverita":
		return &chu.LaveritaV3Parser{}
	case "Yubideck":
		return &chu.YubideckParser{}
	case "Tasoller+":
		return &chu.TasollerPlusParser{}
	case "Tasoller":
		return &chu.TasollerV2Parser{}
	default:
		return &chu.RustnithmParser{}
	}
}

func formatHexLine(name string, raw []byte, data chu.ChusanData) string {
	airStr := ""
	for _, b := range data.Air {
		if b {
			airStr += "1"
		} else {
			airStr += "0"
		}
	}
	shortName := name
	if len(name) > 4 {
		shortName = name[:4]
	}
	return fmt.Sprintf("[%s] %X... | AIR:%s | TEST:%v", shortName, raw[:8], airStr, data.Test)
}