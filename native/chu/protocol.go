package chu

type ChusanData struct {
	Test    bool
	Service bool
	Air     [6]bool
	Slider  [32]uint8
}

type ChusanParser interface {
	Parse(raw []byte) ChusanData
	GetName() string
}

func (d *ChusanData) Serialize() []byte {
	res := make([]byte, 34)
	if d.Test {
		res[0] |= 1 << 0
	}
	if d.Service {
		res[0] |= 1 << 1
	}
	var airByte uint8
	for i := 0; i < 6; i++ {
		if d.Air[i] {
			airByte |= 1 << i
		}
	}
	res[1] = airByte
	copy(res[2:], d.Slider[:])
	return res
}