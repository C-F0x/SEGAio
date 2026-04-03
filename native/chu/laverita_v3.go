package chu

type LaveritaV3Parser struct{}

func (p *LaveritaV3Parser) GetName() string {
	return "LaveritaV3"
}

func (p *LaveritaV3Parser) Parse(raw []byte) ChusanData {
	if len(raw) < 34 {
		return ChusanData{}
	}

	data := ChusanData{}

	irButtons := raw[0]
	data.Test = (irButtons>>6)&1 == 1
	data.Service = (irButtons>>7)&1 == 1

	mixedBeams := irButtons & 0x3F

	beams := ((mixedBeams & 0xAA) >> 1) | ((mixedBeams & 0x55) << 1)
	for i := 0; i < 6; i++ {
		data.Air[i] = (beams >> i) & 1 == 1
	}
	sliderRaw := raw[2:34]
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