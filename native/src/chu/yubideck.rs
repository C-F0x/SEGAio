use super::{ChusanData, ChusanParser};

pub struct YubideckParser;

impl ChusanParser for YubideckParser {
    fn get_name(&self) -> &'static str {
        "Yubideck"
    }

    fn parse(&self, raw: &[u8]) -> ChusanData {
        if raw.len() < 45 {
            return ChusanData::default();
        }

        let mut data = ChusanData::default();

        // Air bits are in swapped pair order
        let ir_value = raw[0];
        data.air[1] = (ir_value & (1 << 0)) != 0;
        data.air[0] = (ir_value & (1 << 1)) != 0;
        data.air[3] = (ir_value & (1 << 2)) != 0;
        data.air[2] = (ir_value & (1 << 3)) != 0;
        data.air[5] = (ir_value & (1 << 4)) != 0;
        data.air[4] = (ir_value & (1 << 5)) != 0;

        let buttons = raw[1];
        data.test = (buttons & (1 << 0)) != 0;
        data.service = (buttons & (1 << 1)) != 0;

        data.slider.copy_from_slice(&raw[2..34]);

        data
    }
}
