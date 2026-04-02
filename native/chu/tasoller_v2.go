package chu

type TasollerV2Parser struct{}

func (p *TasollerV2Parser) GetName() string {
	return "TasollerV2"
}

func (p *TasollerV2Parser) Parse(raw []byte) ChusanData {
	if len(raw) < 36 {
		return ChusanData{}
	}

	data := ChusanData{}

	irButtons := raw[3]

	rawBtn := irButtons >> 6

	data.Test = (rawBtn&2)>>1 == 1
	data.Service = (rawBtn&1)<<1>>1 == 1

	beams := irButtons & 0x3F
	for i := 0; i < 6; i++ {
		data.Air[i] = (beams >> i) & 1 == 1
	}

	sliderRaw := raw[4:36]
	for i := 0; i < 32; i++ {
		var targetIdx int
		if i%2 == 0 {
			targetIdx = 30 - i
		} else {
			targetIdx = 32 - i
		}
		if targetIdx >= 0 && targetIdx < 32 {
			data.Slider[targetIdx] = sliderRaw[i]
		}
	}

	return data
}