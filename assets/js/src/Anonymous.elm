port module Anonymous exposing (Model, Msg, createCredential, init, update, view)

import Base64
import Char
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (disabled, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Decoder, bool, int, list, maybe, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E exposing (Value)



-- PORT


port createCredential : PublicKeyCredentialCreationOption -> Cmd msg



-- MODEL


type alias Model =
    { username : Maybe String
    , displayName : Maybe String
    }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { username = Nothing, displayName = Nothing }, Cmd.none )



-- UPDATE


type Msg
    = UpdateUsername String
    | UpdateDisplayName String
    | CreateWebAuthnCredentialCreationOpption
    | GotCredentialCreationOption (Result Http.Error WebAuthnCredentialCreationOpption)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateUsername value ->
            ( { model
                | username =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
              }
            , Cmd.none
            )

        UpdateDisplayName value ->
            ( { model
                | displayName =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
              }
            , Cmd.none
            )

        CreateWebAuthnCredentialCreationOpption ->
            ( model
            , registerUser
                { username = Maybe.withDefault "" model.username
                , displayName = Maybe.withDefault "" model.displayName
                }
            )

        GotCredentialCreationOption result ->
            case result of
                Ok response ->
                    let
                        publicKeyCredentialCreationOption =
                            transformCredentialCreationOption response
                    in
                    ( model, createCredential publicKeyCredentialCreationOption )

                Err _ ->
                    ( model, Cmd.none )


type alias EncodedUser =
    { id : List Int
    , name : String
    , displayName : String
    , icon : String
    }


type alias PublicKeyCredentialCreationOption =
    { challenge : List Int
    , rp : RelyingParty
    , user : EncodedUser
    , pubKeyCredParams : PubKeyCredParams
    , timeout : Int
    , excludeCredentials : List String
    , attestation : String
    , extensions : Extensions
    , authenticatorSelection : Maybe String
    }


toEncodedCharList : String -> List Int
toEncodedCharList s =
    String.toList (Base64.encode s)
        |> List.map Char.toCode


transformCredentialCreationOption : WebAuthnCredentialCreationOpption -> PublicKeyCredentialCreationOption
transformCredentialCreationOption webAuthnCredentialCreationOption =
    let
        encodedUser =
            let
                user =
                    webAuthnCredentialCreationOption.user
            in
            { id = toEncodedCharList webAuthnCredentialCreationOption.user.id
            , name = webAuthnCredentialCreationOption.user.name
            , displayName = webAuthnCredentialCreationOption.user.displayName
            , icon = webAuthnCredentialCreationOption.user.icon
            }
    in
    { challenge = toEncodedCharList webAuthnCredentialCreationOption.challenge
    , rp = webAuthnCredentialCreationOption.rp
    , user = encodedUser
    , pubKeyCredParams = webAuthnCredentialCreationOption.pubKeyCredParams
    , timeout = webAuthnCredentialCreationOption.timeout
    , excludeCredentials = webAuthnCredentialCreationOption.excludeCredentials
    , attestation = webAuthnCredentialCreationOption.attestation
    , extensions = webAuthnCredentialCreationOption.extensions
    , authenticatorSelection = webAuthnCredentialCreationOption.authenticatorSelection
    }



-- VIEW


view : Model -> Html Msg
view model =
    let
        submit_disabled =
            List.map isJust [ model.username, model.displayName ] |> List.any not
    in
    div []
        [ div []
            [ label []
                [ text "username"
                , input
                    [ placeholder "username"
                    , onInput UpdateUsername
                    , value <| Maybe.withDefault "" model.username
                    ]
                    []
                ]
            , label []
                [ text "display name"
                , input
                    [ placeholder "display name"
                    , onInput UpdateDisplayName
                    , value <| Maybe.withDefault "" model.displayName
                    ]
                    []
                ]
            ]
        , div []
            [ button
                [ onClick CreateWebAuthnCredentialCreationOpption
                , disabled submit_disabled
                ]
                [ text "register" ]
            ]
        ]



-- API


registerUser : RegistrationForm -> Cmd Msg
registerUser registration_form =
    Http.post
        { url = "/begin_activate"
        , body = Http.jsonBody <| registrationEncoder registration_form
        , expect = Http.expectJson GotCredentialCreationOption webAuthnMakeCredentialOptionDecoder
        }


type alias RegistrationForm =
    { username : String
    , displayName : String
    }


registrationEncoder : RegistrationForm -> Value
registrationEncoder registration_form =
    E.object
        [ ( "username", E.string registration_form.username )
        , ( "display_name", E.string registration_form.displayName )
        ]


type alias RelyingParty =
    { name : String
    , id : String
    }


relyingPartyDecoder : Decoder RelyingParty
relyingPartyDecoder =
    D.succeed RelyingParty
        |> required "name" string
        |> required "id" string


type alias User =
    { id : String
    , name : String
    , displayName : String
    , icon : String
    }


userDecoder : Decoder User
userDecoder =
    D.succeed User
        |> required "id" string
        |> required "name" string
        |> required "displayName" string
        |> required "icon" string


type alias PubKeyCredParam =
    { alg : Int
    , type_ : String
    }


pubKeyCredParamDecoder : Decoder PubKeyCredParam
pubKeyCredParamDecoder =
    D.succeed PubKeyCredParam
        |> required "alg" int
        |> required "type" string


type alias PubKeyCredParams =
    List PubKeyCredParam


pubKeyCredParamsDecoder : Decoder PubKeyCredParams
pubKeyCredParamsDecoder =
    list pubKeyCredParamDecoder


type alias Extensions =
    { webauthnLoc : Bool
    }


extensionsDecoder : Decoder Extensions
extensionsDecoder =
    D.succeed Extensions
        |> required "webauthn.loc" bool


type alias WebAuthnCredentialCreationOpption =
    { challenge : String
    , rp : RelyingParty
    , user : User
    , pubKeyCredParams : PubKeyCredParams
    , timeout : Int
    , excludeCredentials : List String
    , attestation : String
    , extensions : Extensions
    , authenticatorSelection : Maybe String
    }


webAuthnMakeCredentialOptionDecoder : Decoder WebAuthnCredentialCreationOpption
webAuthnMakeCredentialOptionDecoder =
    D.succeed WebAuthnCredentialCreationOpption
        |> required "challenge" string
        |> required "rp" relyingPartyDecoder
        |> required "user" userDecoder
        |> required "pubKeyCredParams" pubKeyCredParamsDecoder
        |> required "timeout" int
        |> required "excludeCredentials" (list string)
        |> required "attestation" string
        |> required "extensions" extensionsDecoder
        |> required "authenticatorSelection" (maybe string)



-- HELPER


isJust : Maybe a -> Bool
isJust maybeValue =
    case maybeValue of
        Just v ->
            True

        Nothing ->
            False
