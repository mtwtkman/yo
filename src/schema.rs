table! {
    users (id) {
        id -> Int4,
        webauthn_user_id -> Varchar,
        credential_id -> Varchar,
        display_name -> Varchar,
        public_key -> Nullable<Varchar>,
        sign_count -> Int4,
        name -> Varchar,
        icon_url -> Nullable<Varchar>,
        created_at -> Timestamp,
        updated_at -> Timestamp,
        deleted_at -> Nullable<Timestamp>,
    }
}
