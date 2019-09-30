pub fn base64_decode(s: &str) -> Vec<u8> {
    base64::decode_config(s, base64::URL_SAFE).unwrap()
}
