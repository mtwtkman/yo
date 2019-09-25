port module Anonymous exposing (Model, Msg, createCredential, init, receiveAssertion, subscriptions, update, view)

import Base64
import Char
import Debug exposing (log)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (disabled, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Decoder, bool, int, list, maybe, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E exposing (Value)



-- PORT


port createCredential : Value -> Cmd msg


port receiveAssertion : (Value -> msg) -> Sub msg


type alias Assertion =
    { id : String
    , attObj : String
    , clientData : String
    , rawId : String
    , registrationClientExtensions : String
    , type_ : String
    }


assertionDecoder : Decoder Assertion
assertionDecoder =
    D.succeed Assertion
        |> required "id" string
        |> required "attObj" string
        |> required "clientData" string
        |> required "rawId" string
        |> required "registrationClientExtensions" string
        |> required "type" string



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
    | CreateCredentialCreationOpption
    | GotCredentialCreationOption (Result Http.Error CredentialCreationOpption)
    | ReceiveAssertion Value


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

        CreateCredentialCreationOpption ->
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
                    ( model, createCredential (publicKeyCredentialCreationOptionEncoder publicKeyCredentialCreationOption) )

                Err _ ->
                    ( model, Cmd.none )

        ReceiveAssertion value ->
            case D.decodeValue assertionDecoder value of
                Ok assertion ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


publicKeyCredentialCreationOptionEncoder : PublicKeyCredentialCreationOption -> Value
publicKeyCredentialCreationOptionEncoder option =
    E.object
        [ ( "challenge", E.list E.int option.challenge )
        , ( "rp", relyingPartyEncoder option.rp )
        , ( "user", encodedUserEncoder option.user )
        , ( "pubKeyCredParams", pubKeyCredParamsEncoder option.pubKeyCredParams )
        ]


type alias EncodedUser =
    { id : List Int
    , name : String
    , displayName : String
    }


encodedUserEncoder : EncodedUser -> Value
encodedUserEncoder user =
    E.object
        [ ( "id", E.list E.int user.id )
        , ( "name", E.string user.name )
        , ( "displayName", E.string user.displayName )
        ]


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


toCharCodePoints : String -> List Int
toCharCodePoints encoded =
    case Base64.decode encoded of
        Err _ ->
            []

        Ok decoded ->
            List.map Char.toCode <| String.toList decoded


transformCredentialCreationOption : CredentialCreationOpption -> PublicKeyCredentialCreationOption
transformCredentialCreationOption credentialCreationOption =
    let
        encodedUser =
            let
                user =
                    credentialCreationOption.user
            in
            { id = toCharCodePoints credentialCreationOption.user.id
            , name = credentialCreationOption.user.name
            , displayName = credentialCreationOption.user.displayName
            }
    in
    { challenge = toCharCodePoints credentialCreationOption.challenge
    , rp = credentialCreationOption.rp
    , user = encodedUser
    , pubKeyCredParams = credentialCreationOption.pubKeyCredParams
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
                [ onClick CreateCredentialCreationOpption
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
        , expect = Http.expectJson GotCredentialCreationOption makeCredentialOptionDecoder
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


relyingPartyEncoder : RelyingParty -> Value
relyingPartyEncoder rp =
    E.object
        [ ( "name", E.string rp.name )
        , ( "id", E.string rp.id )
        ]


relyingPartyDecoder : Decoder RelyingParty
relyingPartyDecoder =
    D.succeed RelyingParty
        |> required "name" string
        |> required "id" string


type alias User =
    { id : String
    , name : String
    , displayName : String
    }


userDecoder : Decoder User
userDecoder =
    D.succeed User
        |> required "id" string
        |> required "name" string
        |> required "displayName" string


type alias PubKeyCredParam =
    { alg : Int
    , type_ : String
    }


pubKeyCredParamEncoder : PubKeyCredParam -> Value
pubKeyCredParamEncoder param =
    E.object
        [ ( "alg", E.int param.alg )
        , ( "type", E.string param.type_ )
        ]


pubKeyCredParamDecoder : Decoder PubKeyCredParam
pubKeyCredParamDecoder =
    D.succeed PubKeyCredParam
        |> required "alg" int
        |> required "type" string


type alias PubKeyCredParams =
    List PubKeyCredParam


pubKeyCredParamsEncoder : PubKeyCredParams -> Value
pubKeyCredParamsEncoder params =
    E.list pubKeyCredParamEncoder params


pubKeyCredParamsDecoder : Decoder PubKeyCredParams
pubKeyCredParamsDecoder =
    list pubKeyCredParamDecoder


type alias CredentialCreationOpption =
    { challenge : String
    , rp : RelyingParty
    , user : User
    , pubKeyCredParams : PubKeyCredParams
    }


makeCredentialOptionDecoder : Decoder CredentialCreationOpption
makeCredentialOptionDecoder =
    D.succeed CredentialCreationOpption
        |> required "challenge" string
        |> required "rp" relyingPartyDecoder
        |> required "user" userDecoder
        |> required "pubKeyCredParams" pubKeyCredParamsDecoder



-- HELPER


isJust : Maybe a -> Bool
isJust maybeValue =
    case maybeValue of
        Just v ->
            True

        Nothing ->
            False



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ receiveAssertion ReceiveAssertion ]
