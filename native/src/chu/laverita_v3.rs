use super::{ChusanData, ChusanParser};

pub struct LaveritaV3Parser;

impl ChusanParser for LaveritaV3Parser {
    fn get_name(&self) -> &'static str {
        "LaveritaV3"
    }

    fn parse(&self, raw: &[u8]) -> ChusanData {
        if raw.len() < 34 {
            return ChusanData::default();
        }

        let mut data = ChusanData::default();

        let ir_buttons = raw[0];
        data.test = ((ir_buttons >> 6) & 1) == 1;
        data.service = ((ir_buttons >> 7) & 1) == 1;

        // Swap adjacent beam bits (0↔1, 2↔3, 4↔5)
        let mixed_beams = ir_buttons & 0x3F;
        let beams = ((mixed_beams & 0xAA) >> 1) | ((mixed_beams & 0x55) << 1);
        for i in 0..6 {
            data.air[i] = ((beams >> i) & 1) == 1;
        }

        // Slider bytes with index swapping: even→30-i, odd→32-i
        let slider_raw = &raw[2..34];
        for i in 0..32 {
            let target = if i % 2 == 0 { 30 - i } else { 32 - i };
            if target < 32 {
                data.slider[target] = slider_raw[i];
            }
        }

        data
    }
}
