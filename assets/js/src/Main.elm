module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (disabled, name, placeholder, value)
import Html.Events exposing (onClick, onInput)



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { name : Maybe String
    , registered : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { name = Nothing, registered = False }, Cmd.none )



-- UPDATE


type Msg
    = Anonymous
    | Register
    | UpdateName String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Anonymous ->
            ( model, Cmd.none )

        UpdateName value ->
            ( { model
                | name =
                    if String.isEmpty value then
                        Nothing

                    else
                        Just value
              }
            , Cmd.none
            )

        Register ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "yo"
    , body =
        [ div []
            [ label []
                [ text "Name"
                , input
                    [ placeholder "name"
                    , name "name"
                    , onInput UpdateName
                    , value <| Maybe.withDefault "" model.name
                    ]
                    []
                ]
            , button
                [ onClick Register
                , isNothing model.name |> disabled
                ]
                [ text "register" ]
            ]
        ]
    }



-- HELPER


isJust : Maybe a -> Bool
isJust maybeValue =
    case maybeValue of
        Just v ->
            True

        Nothing ->
            False


isNothing : Maybe a -> Bool
isNothing maybeValue =
    isJust maybeValue |> not
