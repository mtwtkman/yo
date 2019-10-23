use rand::{thread_rng, Rng};
use rand::distributions::Alphanumeric;

pub fn generate_random(length: usize) -> String {
    let s: String = thread_rng()
        .sample_iter(&Alphanumeric)
        .take(length)
        .collect();
    base64::encode(s.as_bytes())
}