use crate::AttestationResponse;
use serde::Deserialize;
use super::helper::base64_decode;

pub struct ClientExtension {
    pub appid: Option<String>,
    pub loc: Option<String>,
}

pub struct AuthenticatorExtension;

#[derive(Clone, Copy, Deserialize)]
pub enum ClientDataType {
    #[serde(rename(deserialize = "webauthn.get"))]
    Get,
    #[serde(rename(deserialize = "webauthn.create"))]
    Create,
}

#[derive(Deserialize)]
pub struct ClientData {
    challenge: String,
    origin: String,
    r#type: ClientDataType,
}

#[derive(Deserialize)]
pub struct AttestationObject {
    #[serde(rename(deserialize = "authData"))]
    pub auth_data: String,
    pub fmt: String,
    #[serde(rename(deserialize = "attStmt"))]
    pub att_stmt: String,
}

pub struct RegistrationResponse<'a> {
    pub rp_id: &'a str,
    pub origin: &'a str,
    pub attestation_response: AttestationResponse,
    pub trust_anchor_dir: &'a str,
    pub trusted_attestaion_cert_required: bool,
    pub self_attestation_permitted: bool,
    pub none_attestation_permitted: bool,
    pub uv_required: bool,
    pub expected_registration_client_extensions: Option<ClientExtension>,
    pub expected_registration_authenticator_extensions: Option<AuthenticatorExtension>,
}

impl<'a> RegistrationResponse<'a> {
    pub fn new(
        rp_id: &'a str,
        origin: &'a str,
        attestation_response: AttestationResponse,
    ) -> Self {
        RegistrationResponse {
            rp_id,
            origin,
            attestation_response,
            trust_anchor_dir: "",
            trusted_attestaion_cert_required: false,
            self_attestation_permitted: false,
            none_attestation_permitted: false,
            uv_required: false,
            expected_registration_client_extensions: None,
            expected_registration_authenticator_extensions: None,
        }
    }

    pub fn verify(&self, challenge: &str) -> bool {
        let client_data = self.get_client_data();
        let client_data_type = &client_data.r#type;
        let received_challenge = &client_data.challenge;
        let attestation_object = self.get_attestation_object();
        true
    }

    fn get_client_data(&self) -> ClientData {
        let decoded = base64_decode(&self.attestation_response.client_data);
        let s = std::str::from_utf8(&decoded).unwrap();
        serde_json::from_str::<ClientData>(s).unwrap()
    }

    fn get_attestation_object(&self) -> AttestationObject {
        let decoded = base64_decode(&self.attestation_response.att_obj);
        serde_cbor::from_slice::<AttestationObject>(&decoded).unwrap()
    }
}
