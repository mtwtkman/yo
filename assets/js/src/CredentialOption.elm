module CredentialOption exposing
    ( CredentialCreationOpption
    , PublicKeyCredentialCreationOption
    , credentialCreationOptionDecoder
    , publicKeyCredentialCreationOptionEncoder
    )

import Json.Decode as D exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E exposing (Value)



-- MODEL


type alias User =
    { id : String
    , name : String
    , displayName : String
    }


type alias PubKeyCredParams =
    List PubKeyCredParam


type alias CredentialCreationOpption =
    { challenge : String
    , rp : RelyingParty
    , user : User
    , pubKeyCredParams : PubKeyCredParams
    }


type alias PubKeyCredParam =
    { alg : Int
    , type_ : String
    }


type alias RelyingParty =
    { name : String
    , id : String
    }


type alias EncodedUser =
    { id : List Int
    , name : String
    , displayName : String
    }


type alias AuthenticatorSelection =
    { requireResidentKey : Bool
    , userVerification : String
    }


type alias PublicKeyCredentialCreationOption =
    { challenge : List Int
    , rp : RelyingParty
    , user : EncodedUser
    , pubKeyCredParams : PubKeyCredParams
    }



-- ENCODER


encodedUserEncoder : EncodedUser -> Value
encodedUserEncoder user =
    E.object
        [ ( "id", E.list E.int user.id )
        , ( "name", E.string user.name )
        , ( "displayName", E.string user.displayName )
        ]


pubKeyCredParamEncoder : PubKeyCredParam -> Value
pubKeyCredParamEncoder param =
    E.object
        [ ( "alg", E.int param.alg )
        , ( "type", E.string param.type_ )
        ]


pubKeyCredParamsEncoder : PubKeyCredParams -> Value
pubKeyCredParamsEncoder params =
    E.list pubKeyCredParamEncoder params


relyingPartyEncoder : RelyingParty -> Value
relyingPartyEncoder rp =
    E.object
        [ ( "name", E.string rp.name )
        , ( "id", E.string rp.id )
        ]


publicKeyCredentialCreationOptionEncoder : PublicKeyCredentialCreationOption -> Value
publicKeyCredentialCreationOptionEncoder option =
    E.object
        [ ( "challenge", E.list E.int option.challenge )
        , ( "rp", relyingPartyEncoder option.rp )
        , ( "user", encodedUserEncoder option.user )
        , ( "pubKeyCredParams", pubKeyCredParamsEncoder option.pubKeyCredParams )
        ]



-- DECODER


pubKeyCredParamsDecoder : Decoder PubKeyCredParams
pubKeyCredParamsDecoder =
    list pubKeyCredParamDecoder


credentialCreationOptionDecoder : Decoder CredentialCreationOpption
credentialCreationOptionDecoder =
    D.succeed CredentialCreationOpption
        |> required "challenge" string
        |> required "rp" relyingPartyDecoder
        |> required "user" userDecoder
        |> required "pubKeyCredParams" pubKeyCredParamsDecoder


pubKeyCredParamDecoder : Decoder PubKeyCredParam
pubKeyCredParamDecoder =
    D.succeed PubKeyCredParam
        |> required "alg" int
        |> required "type" string


userDecoder : Decoder User
userDecoder =
    D.succeed User
        |> required "id" string
        |> required "name" string
        |> required "displayName" string


relyingPartyDecoder : Decoder RelyingParty
relyingPartyDecoder =
    D.succeed RelyingParty
        |> required "name" string
        |> required "id" string
