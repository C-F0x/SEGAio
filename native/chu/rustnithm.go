package chu

type RustnithmParser struct{}

func (p *RustnithmParser) GetName() string {
	return "Rustnithm"
}

func (p *RustnithmParser) Parse(raw []byte) ChusanData {
	if len(raw) < 136 {
		return ChusanData{}
	}

	data := ChusanData{}

	for i := 0; i < 6; i++ {
		data.Air[i] = raw[i] != 0
	}

	copy(data.Slider[:], raw[6:38])

	data.Test = raw[134] != 0
	data.Service = raw[135] != 0

	return data
}