package chu

import "math/bits"

type TasollerPlusParser struct{}

func (p *TasollerPlusParser) GetName() string {
	return "TasollerPlus"
}

func (p *TasollerPlusParser) Parse(raw []byte) ChusanData {
	if len(raw) < 36 {
		return ChusanData{}
	}

	data := ChusanData{}
	irButtons := raw[3]
	reversed := bits.Reverse8(irButtons)

	data.Test = (reversed & 1) == 1
	data.Service = (reversed&2)>>1 == 1

	beams := reversed >> 2
	for i := 0; i < 6; i++ {
		data.Air[i] = (beams >> i) & 1 == 1
	}

	copy(data.Slider[:], raw[4:36])

	return data
}