// This implemetation references webauthn-py
// ref: https://github.com/duo-labs/py_webauthn/blob/master/webauthn/webauthn.py
// TODO: follow spec (https://www.w3.org/TR/webauthn/)

pub mod credential_option;
pub mod error;

pub use credential_option::WebAuthnCredentialCreationOpption;
