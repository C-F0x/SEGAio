use super::{ChusanData, ChusanParser};

pub struct RustnithmParser;

impl ChusanParser for RustnithmParser {
    fn get_name(&self) -> &'static str {
        "Rustnithm"
    }

    fn parse(&self, raw: &[u8]) -> ChusanData {
        if raw.len() < 136 {
            return ChusanData::default();
        }

        let mut data = ChusanData::default();

        for i in 0..6 {
            data.air[i] = raw[i] != 0;
        }

        data.slider.copy_from_slice(&raw[6..38]);

        data.test = raw[134] != 0;
        data.service = raw[135] != 0;

        data
    }
}
