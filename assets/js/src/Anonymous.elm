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
    | CreateCredentialCreationOpption
    | GotCredentialCreationOption (Result Http.Error CredentialCreationOpption)


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
                    ( model, createCredential publicKeyCredentialCreationOption )

                Err _ ->
                    ( model, Cmd.none )


type alias EncodedUser =
    { id : List Int
    , name : String
    , displayName : String
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
