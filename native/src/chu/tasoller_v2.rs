use super::{ChusanData, ChusanParser};

pub struct TasollerV2Parser;

impl ChusanParser for TasollerV2Parser {
    fn get_name(&self) -> &'static str {
        "TasollerV2"
    }

    fn parse(&self, raw: &[u8]) -> ChusanData {
        if raw.len() < 36 {
            return ChusanData::default();
        }

        let mut data = ChusanData::default();

        let ir_buttons = raw[3];
        let raw_btn = ir_buttons >> 6;

        data.test = ((raw_btn & 2) >> 1) == 1;
        data.service = ((raw_btn & 1) << 1 >> 1) == 1;

        let beams = ir_buttons & 0x3F;
        for i in 0..6 {
            data.air[i] = ((beams >> i) & 1) == 1;
        }

        // Slider bytes with index swapping: even→30-i, odd→32-i
        let slider_raw = &raw[4..36];
        for i in 0..32 {
            let target = if i % 2 == 0 { 30 - i } else { 32 - i };
            if target < 32 {
                data.slider[target] = slider_raw[i];
            }
        }

        data
    }
}
