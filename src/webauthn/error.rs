use failure::Error;

#[derive(Debug, Fail)]
pub enum WebAuthnError {
    #[fail(display = "invalid COSE key")]
    InvalidCOSEKey,
    #[fail(display = "authentication rejected")]
    AuthenticationRejected,
    #[fail(display = "registration rejected")]
    RegistrationRejected,
    #[fail(display = "webauthn user data missing")]
    WebAuthnUserDataMissing,
}
