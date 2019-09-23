extern crate rand;
extern crate actix_files;
extern crate actix_web;
extern crate env_logger;
extern crate openssl;
#[macro_use] extern crate failure;
extern crate serde;
extern crate serde_json;
#[macro_use] extern crate validator_derive;
extern crate validator;
extern crate actix_session;

use actix_session::CookieSession;
use actix_files::NamedFile;
use actix_web::{App, HttpServer, middleware, web, HttpResponse};
use openssl::ssl::{SslAcceptor, SslFiletype, SslMethod};
use serde::{Serialize, Deserialize};
use std::path::PathBuf;
use validator::{Validate, ValidationError};

mod webauthn;
mod helper;

use webauthn::WebAuthnCredentialCreationOpption;

fn index() -> actix_web::Result<NamedFile> {
    let path = PathBuf::from("index.html");
    Ok(NamedFile::open(path)?)
}

#[derive(Debug, Validate, Deserialize, Serialize)]
struct RegistrationForm {
    #[validate(length(min = 1, max = 32), custom = "validate_name")]
    username: String,
    #[validate(length(min = 1, max = 32), custom = "validate_name")]
    display_name: String,
}

fn validate_name(value: &str) -> Result<(), ValidationError>{
    match value.parse::<i64>() {
        Ok(_) => Err(ValidationError::new("only digits is disallowed")),
        Err(_) => Ok(())
    }
}

fn begin_activate(register_form: web::Json<RegistrationForm>) -> HttpResponse {
    match register_form.validate() {
        Ok(()) => HttpResponse::Ok().json(WebAuthnCredentialCreationOpption::new(
            helper::generate_random(32), "yo".to_owned(), "yo".to_owned(), helper::generate_random(20), register_form.username.to_owned(),
            register_form.display_name.to_owned(), "".to_owned(), None, None, None,
        )),
        Err(_) => HttpResponse::BadRequest().finish(),  // TODO: error handling
    }
}

fn main() {
    std::env::set_var("RUST_LOG", "actix_web=debug");
    env_logger::init();

    let mut builder = SslAcceptor::mozilla_intermediate(SslMethod::tls()).unwrap();
    builder
        .set_private_key_file("key.pem", SslFiletype::PEM)
        .unwrap();
    builder.set_certificate_chain_file("cert.pem").unwrap();

    HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .wrap(
                CookieSession::signed(&[0; 32])
                    .name("yo-session")
                    .secure(true)
            ).service(actix_files::Files::new("/assets", "./assets").show_files_listing())
            .route("/", web::get().to(index))
            .service(
                web::resource("/begin_activate").route(web::post().to(begin_activate))
            )
    })
    .bind_ssl("0.0.0.0:55301", builder)
    .unwrap()
    .run()
    .unwrap();
}
