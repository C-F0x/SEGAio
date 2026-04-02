package chu

type YubideckParser struct{}

func (p *YubideckParser) GetName() string {
	return "Yubideck"
}

func (p *YubideckParser) Parse(raw []byte) ChusanData {
	if len(raw) < 45 {
		return ChusanData{}
	}

	data := ChusanData{}

	irValue := raw[0]
	data.Air[1] = (irValue & (1 << 0)) != 0
	data.Air[0] = (irValue & (1 << 1)) != 0
	data.Air[3] = (irValue & (1 << 2)) != 0
	data.Air[2] = (irValue & (1 << 3)) != 0
	data.Air[5] = (irValue & (1 << 4)) != 0
	data.Air[4] = (irValue & (1 << 5)) != 0

	buttons := raw[1]
	data.Test = (buttons & (1 << 0)) != 0
	data.Service = (buttons & (1 << 1)) != 0

	copy(data.Slider[:], raw[2:34])

	return data
}