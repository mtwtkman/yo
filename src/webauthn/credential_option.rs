use serde::{Serialize, Serializer};
use crate::helper::generate_random;

#[derive(Clone, Copy)]
pub enum Attestation {
    None,
    Indirect,
    Direct,
}

impl Serialize for Attestation {
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

pub enum Algorithm {
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
pub struct RelyingParty {
    name: String,
    id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    icon: Option<String>
}

impl RelyingParty {
    pub fn new(name: &str, id: &str, icon: Option<&str>) -> Self {
        RelyingParty {
            name: name.to_owned(),
            id: id.to_owned(),
            icon: icon.map(|v| v.to_owned()),
        }
    }
}

#[derive(Serialize)]
pub struct User {
    id: String,
    name: String,
    #[serde(rename(serialize = "displayName"))]
    display_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    icon: Option<String>,
}

impl User {
    pub fn new(name: &str, display_name: &str, icon: Option<&str>) -> Self {
        User {
            id: generate_random(20),
            name: name.to_owned(),
            display_name: display_name.to_owned(),
            icon: icon.map(|v| v.to_owned()),
        }
    }
}

#[derive(Serialize)]
pub struct CredParam {
    alg: Algorithm,
    #[serde(rename(serialize = "type"))]
    type_: String,
}

impl CredParam {
    pub fn new(alg: Algorithm) -> Self {
        CredParam {
            alg,
            type_: "public-key".to_owned(),
        }
    }
}

#[derive(Serialize)]
pub struct BiometricPerfBounds {
    far: f64,
    frr: f64,
}

#[derive(Serialize)]
pub struct Extension {
    #[serde(rename(serialize = "authSel"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    auth_sel: Option<Vec<usize>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    exts: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    uvi: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    loc: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    uvm: Option<bool>,
    #[serde(rename(serialize = "biometricPerfBounds"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    biometric_perf_bounds: Option<BiometricPerfBounds>,
}

impl Extension {
    pub fn new(auth_sel: Option<Vec<usize>>, exts: Option<bool>, uvi: Option<bool>, loc: Option<bool>, uvm: Option<bool>, biometric_perf_bounds: Option<BiometricPerfBounds>) -> Self {
        Extension {
            auth_sel,
            exts,
            uvi,
            loc,
            uvm,
            biometric_perf_bounds,
        }
    }
}


pub enum AuthenticatorAttachment {
    Platform,
    CrossPlatform,
}

impl Serialize for AuthenticatorAttachment {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer
    {
        let s = match self {
            Self::Platform => "platform",
            Self::CrossPlatform => "cross-platform",
        };
        serializer.serialize_str(s)
    }
}

#[derive(Serialize)]
pub struct AuthenticatorSelection {
    #[serde(rename(serialize = "userVerification"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    user_verification: Option<UserVerification>,
    #[serde(rename(serialize = "authenticatorAttachment"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    authenticator_attachment: Option<AuthenticatorAttachment>,
    #[serde(rename(serialize = "requireResidentKey"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    require_resident_key: Option<bool>
}

impl AuthenticatorSelection {
    pub fn new(user_verification: Option<UserVerification>, authenticator_attachment: Option<AuthenticatorAttachment>, require_resident_key: Option<bool>) -> Self {
        AuthenticatorSelection {
            user_verification,
            authenticator_attachment,
            require_resident_key,
        }
    }
}


#[derive(Clone, Copy)]
pub enum ExcludeCredentialTransport {
    USB,
    NFC,
    BLE,
    INTERNAL,
}


impl Serialize for ExcludeCredentialTransport {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer
    {
        let s = match self {
            Self::USB => "usb",
            Self::NFC => "nfc",
            Self::BLE => "ble",
            Self::INTERNAL => "internal"
        };
        serializer.serialize_str(s)
    }
}

#[derive(Serialize)]
pub struct ExcludeCredential {
    type_: String,
    id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    transports: Option<ExcludeCredentialTransport>
}

impl ExcludeCredential {
    pub fn new(id: String, transports: Option<ExcludeCredentialTransport>) -> Self {
        ExcludeCredential {
            type_: "public-key".to_owned(),  // https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions/excludeCredentials#Value
            id,
            transports,
        }
    }
}


#[derive(Serialize)]
pub struct PublicKeyCredentialCreationOptions {
    // ref: https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
    rp: RelyingParty,
    user: User,
    challenge: String,
    #[serde(rename(serialize = "pubKeyCredParams"))]
    pub_key_cred_params: Vec<CredParam>,
    #[serde(skip_serializing_if = "Option::is_none")]
    timeout: Option<usize>,
    #[serde(rename(serialize = "excludeCredentials"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    exclude_credentials: Option<Vec<ExcludeCredential>>,
    #[serde(rename(serialize = "authenticatorSelection"))]
    #[serde(skip_serializing_if = "Option::is_none")]
    authenticator_selection: Option<AuthenticatorSelection>,
    #[serde(skip_serializing_if = "Option::is_none")]
    attestation: Option<Attestation>,
    #[serde(skip_serializing_if = "Option::is_none")]
    extensions: Option<Extension>,
}

impl PublicKeyCredentialCreationOptions {
    pub fn new(
        rp: RelyingParty,
        user: User,
        challenge_length: usize,
        pub_key_cred_params: Vec<CredParam>,
        timeout: Option<usize>,
        exclude_credentials: Option<Vec<ExcludeCredential>>,
        authenticator_selection: Option<AuthenticatorSelection>,
        attestation: Option<Attestation>,
        extensions: Option<Extension>,
    ) -> Self {
        PublicKeyCredentialCreationOptions {
            rp,
            user,
            challenge: generate_random(challenge_length),
            pub_key_cred_params,
            timeout,
            exclude_credentials,
            authenticator_selection,
            attestation,
            extensions,
        }
    }
}
