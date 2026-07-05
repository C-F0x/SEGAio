use super::{ChusanData, ChusanParser};

pub struct TasollerPlusParser;

impl ChusanParser for TasollerPlusParser {
    fn get_name(&self) -> &'static str {
        "TasollerPlus"
    }

    fn parse(&self, raw: &[u8]) -> ChusanData {
        if raw.len() < 36 {
            return ChusanData::default();
        }

        let mut data = ChusanData::default();

        let ir_buttons = raw[3];
        let reversed = ir_buttons.reverse_bits();

        data.test = (reversed & 1) == 1;
        data.service = ((reversed & 2) >> 1) == 1;

        let beams = reversed >> 2;
        for i in 0..6 {
            data.air[i] = ((beams >> i) & 1) == 1;
        }

        data.slider.copy_from_slice(&raw[4..36]);

        data
    }
}
