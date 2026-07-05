/// Data structure representing Chusan input state.
#[derive(Debug, Clone, Default)]
pub struct ChusanData {
    pub test:    bool,
    pub service: bool,
    pub air:     [bool; 6],
    pub slider:  [u8; 32],
}

impl ChusanData {
    /// Serialize into a 34-byte binary format:
    ///   [0]    = bit0: Test, bit1: Service
    ///   [1]    = air bits (bit0..bit5)
    ///   [2..34] = slider bytes
    pub fn serialize(&self) -> Vec<u8> {
        let mut res = vec![0u8; 34];
        if self.test {
            res[0] |= 1 << 0;
        }
        if self.service {
            res[0] |= 1 << 1;
        }
        let mut air_byte: u8 = 0;
        for i in 0..6 {
            if self.air[i] {
                air_byte |= 1 << i;
            }
        }
        res[1] = air_byte;
        res[2..34].copy_from_slice(&self.slider);
        res
    }
}

/// Trait for Chusan protocol parsers.
pub trait ChusanParser: Send {
    fn parse(&self, raw: &[u8]) -> ChusanData;
    fn get_name(&self) -> &'static str;
}

pub mod rustnithm;
pub mod laverita_v3;
pub mod yubideck;
pub mod tasoller_p;
pub mod tasoller_v2;
