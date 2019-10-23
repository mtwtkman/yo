use crate::AttestationResponse;
use serde::Deserialize;
use sha2::{Sha256, Digest};
use super::helper::base64_decode;

pub struct ClientExtension {
    pub appid: Option<String>,
    pub loc: Option<String>,
}

pub struct AuthenticatorExtension;

#[derive(Clone, Copy, Deserialize, Eq, PartialEq)]
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

impl AttestationObject {
    pub fn get_auth_data_rp_id_hash(&self) -> Vec<u8> {
        self.auth_data[0..32].as_bytes().to_owned()
    }

    pub fn get_flag_bit(&self) -> u8 {
        self.auth_data[32..33].as_bytes().to_owned()[0]
    }
}

pub enum RegistrationResponseError {
    InvalidClientDataType,
    InvalidChallenge,
    InvalidOrigin,
    InvalidRpId,
    InvalidFlag,
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

    pub fn verify(&self, challenge: &str) -> Result<(), RegistrationResponseError> {
        let decoded_cd = base64_decode(&self.attestation_response.client_data);
        let client_data = self.get_client_data(&decoded_cd);
        if &client_data.r#type != &ClientDataType::Create {
            return Err(RegistrationResponseError::InvalidClientDataType)
        }
        if &client_data.challenge != challenge {
            return Err(RegistrationResponseError::InvalidChallenge)
        }
        if &client_data.origin != &self.origin {
            return Err(RegistrationResponseError::InvalidOrigin)
        }
        let client_data_hash = self.get_client_data_hash(&decoded_cd);
        let attestation_object = self.get_attestation_object();
        let auth_data_rp_id_hash = &attestation_object.get_auth_data_rp_id_hash();
        if &self.rp_id.as_bytes().to_owned() != auth_data_rp_id_hash {
            return Err(RegistrationResponseError::InvalidRpId)
        }
        let flag_bit = &attestation_object.get_flag_bit();
        if *flag_bit & 1 << 0 != 0x01 {
            return Err(RegistrationResponseError::InvalidFlag)
        }
        if self.uv_required && *flag_bit & 1 << 2 != 0x04 {
            return Err(RegistrationResponseError::InvalidFlag)
        }
        if self.expected_registration_client_extensions.is_some() {

        }
        Ok(())
    }

    fn get_client_data(&self, decoded_cd: &[u8]) -> ClientData {
        let s = std::str::from_utf8(decoded_cd).unwrap();
        serde_json::from_str::<ClientData>(s).unwrap()
    }

    fn get_attestation_object(&self) -> AttestationObject {
        let decoded = base64_decode(&self.attestation_response.att_obj);
        serde_cbor::from_slice::<AttestationObject>(&decoded).unwrap()
    }

    fn get_client_data_hash(&self, client_data: &[u8]) -> Vec<u8> {
        let mut hasher = Sha256::new();
        hasher.input(client_data);
        hasher.result().as_slice().to_vec()
    }
}
