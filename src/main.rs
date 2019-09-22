extern crate actix_files;
extern crate actix_web;
extern crate env_logger;
extern crate openssl;
#[macro_use] extern crate failure;
#[macro_use]  extern crate serde;
extern crate serde_json;

use actix_files::NamedFile;
use actix_web::{App, HttpServer, middleware, web, Result, HttpRequest};
use openssl::ssl::{SslAcceptor, SslFiletype, SslMethod};
use std::path::PathBuf;

mod webauthn;

fn index() -> Result<NamedFile> {
    let path = PathBuf::from("index.html");
    Ok(NamedFile::open(path)?)
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
            .service(actix_files::Files::new("/assets", "./assets").show_files_listing())
            .route("/", web::get().to(index))
    })
    .bind_ssl("0.0.0.0:55301", builder)
    .unwrap()
    .run()
    .unwrap();
}
