package main

import (
	"encoding/base64"
	"fmt"
	"time"
	"unsafe"
	"revealer/native/chu"
	"golang.org/x/sys/windows"
)

const (
	ChusanShmemID = "fcfe5b1100568d65af167d81acbed71d"
	MaxInputSize  = 36
)

func runChusanLoop(config RevealerConfig) {
	parser := getParser(config.MinorType)
	namePtr, _ := windows.UTF16PtrFromString("Global\\" + ChusanShmemID)
	handle, err := windows.OpenFileMapping(windows.FILE_MAP_READ, false, namePtr)

	if err != nil {
		pushToDart(RevealerPatch{
			HexLine: fmt.Sprintf("[Error] Cannot open Shmem: %v. Waiting...", err),
		})
	} else {
		defer windows.CloseHandle(handle)
	}

	var addr uintptr
	if handle != 0 {
		addr, _ = windows.MapViewOfFile(handle, windows.FILE_MAP_READ, 0, 0, 0)
		defer windows.UnmapViewOfFile(addr)
	}

	ticker := time.NewTicker(time.Duration(config.PollMs) * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-stopCh:
			return
		case <-ticker.C:
			if addr == 0 {
				handle, _ = windows.OpenFileMapping(windows.FILE_MAP_READ, false, namePtr)
				if handle != 0 {
					addr, _ = windows.MapViewOfFile(handle, windows.FILE_MAP_READ, 0, 0, 0)
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

	return fmt.Sprintf("[%s] %X... | AIR:%s | TEST:%v",
		shortName, raw[:4], airStr, data.Test)
}