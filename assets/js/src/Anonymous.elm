port module Anonymous exposing (Model, Msg, createCredential, init, subscriptions, update, view)

import AttestationResponse exposing (attestationResponseDecoder)
import CredentialOption
    exposing
        ( CredentialCreationOpption
        , PublicKeyCredentialCreationOption
        , credentialCreationOptionDecoder
        , publicKeyCredentialCreationOptionEncoder
        )
import Helper exposing (isJust, toCharCodePoints)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (disabled, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D
import Json.Encode as E exposing (Value)



-- PORT


port createCredential : Value -> Cmd msg


port receiveAttestationResponse : (Value -> msg) -> Sub msg



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
    | ReceiveAttestationResponse Value


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

        ReceiveAttestationResponse value ->
            case D.decodeValue attestationResponseDecoder value of
                Ok assertion ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


transformCredentialCreationOption : CredentialCreationOpption -> PublicKeyCredentialCreationOption
transformCredentialCreationOption option =
    let
        encodedUser =
            let
                user =
                    option.user
            in
            { id = toCharCodePoints option.user.id
            , name = option.user.name
            , displayName = option.user.displayName
            }
    in
    { challenge = toCharCodePoints option.challenge
    , rp = option.rp
    , user = encodedUser
    , pubKeyCredParams = option.pubKeyCredParams
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


registerUser : RegistrationForm -> Cmd Msg
registerUser registration_form =
    Http.post
        { url = "/create_credential"
        , body = Http.jsonBody <| registrationEncoder registration_form
        , expect = Http.expectJson GotCredentialCreationOption credentialCreationOptionDecoder
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ receiveAttestationResponse ReceiveAttestationResponse ]
