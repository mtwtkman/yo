use serde::{Serialize, Serializer};

enum AttestationType {
    Basic,
    ECDAA,
    AttCA,
    Self_,
    None,
}

enum AttestationFormat {
    Packed,
    TPM,
    FIDOU2F,
    None,
}

#[derive(Clone, Copy)]
pub enum AttestationForm {
    None,
    Indirect,
    Direct,
}

impl Serialize for AttestationForm {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer,
    {
        let s = match self {
            Self::None => "none",
            Self::Indirect => "indirect",
            Self::Direct => "direct",
        };
        serializer.serialize_str(s)
    }
}

#[derive(Clone, Copy)]
pub enum UserVerification {
    Required,
    Preferred,
    Discouraged,
}

impl Serialize for UserVerification {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer,
    {
        let s = match self {
            Self::Required => "required",
            Self::Preferred => "preferred",
            Self::Discouraged => "discouraged",
        };
        serializer.serialize_str(s)
    }
}

enum Algorithm {
    ES256,
    PS256,
    RS256,
}

impl Serialize for Algorithm {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer,
    {
        let code: i16 = match self {
            Self::ES256 => -7,
            Self::PS256 => -37,
            Self::RS256 => -257,
        };
        serializer.serialize_i16(code)
    }
}

#[derive(Serialize)]
struct RelyingParty {
    name: String,
    id: String,
}

#[derive(Serialize)]
struct User {
    id: String,
    name: String,
    #[serde(rename(serialize = "displayName"))]
    display_name: String,
    icon: Option<String>,
}

#[derive(Serialize)]
struct CredParam {
    alg: Algorithm,
    #[serde(rename(serialize = "type"))]
    type_: String,
}

#[derive(Serialize)]
struct Extension {
    #[serde(rename(serialize = "webauthn.loc"))]
    webauthn_loc: bool,
}

#[derive(Serialize)]
struct AuthenticatorSelection {
    #[serde(rename(serialize = "userVerification"))]
    user_verification: UserVerification,
}

#[derive(Serialize)]
pub struct WebAuthnCredentialCreationOpption {
    challenge: String,
    rp: RelyingParty,
    user: User,
    #[serde(rename(serialize = "pubKeyCredParams"))]
    pub_key_cred_params: Vec<CredParam>,
    timeout: u32,
    #[serde(rename(serialize = "excludeCredentials"))]
    exclude_credentials: Vec<String>,  // TODO: ensure thie correct type
    attestation: AttestationForm,
    extensions: Extension,
    #[serde(rename(serialize = "authenticatorSelection"))]
    authenticator_selection: Option<AuthenticatorSelection>
}

impl WebAuthnCredentialCreationOpption {
    pub fn new(
        challenge: String,
        rp_name: String,
        rp_id: String,
        user_id: String,
        username: String,
        display_name: String,
        icon_url: String,
        timeout: Option<u32>,
        attestation: Option<AttestationForm>,
        user_verification: Option<UserVerification>,
    ) -> Self {
        let timeout = timeout.unwrap_or(60000);
        let attestation = attestation.unwrap_or(AttestationForm::Direct);
        let rp = RelyingParty {
            name: rp_name,
            id: rp_id,
        };
        let user = User {
            id: user_id,
            name: username,
            display_name: display_name,
            icon: Some(icon_url),
        };
        let pub_key_cred_params = vec![
            CredParam { alg: Algorithm::ES256, type_: "public_key".to_owned() },
            CredParam { alg: Algorithm::PS256, type_: "public_key".to_owned() },
            CredParam { alg: Algorithm::RS256, type_: "public_key".to_owned() },
        ];
        let extensions = Extension { webauthn_loc: true };
        let authenticator_selection = user_verification
            .map(|v| AuthenticatorSelection { user_verification: v });
        WebAuthnCredentialCreationOpption {
            challenge: challenge,
            rp,
            user,
            pub_key_cred_params,
            timeout: timeout,
            exclude_credentials: vec![],
            attestation: attestation,
            extensions,
            authenticator_selection,
        }
    }
}
