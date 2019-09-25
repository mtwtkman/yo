module Main exposing (main)

import Anonymous
import Browser exposing (Document)
import Html exposing (div, h1, text)



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Anonymous Anonymous.Model



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    updateWith Anonymous GotAnonymousMsg Anonymous.init



-- UPDATE


type Msg
    = Unknown
    | GotAnonymousMsg Anonymous.Msg


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel, Cmd.map toMsg subCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Anonymous subModel, GotAnonymousMsg subMsg ) ->
            Anonymous.update subMsg subModel |> updateWith Anonymous GotAnonymousMsg

        ( _, _ ) ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "yo"
    , body =
        let
            subView =
                case model of
                    Anonymous subModel ->
                        Html.map GotAnonymousMsg (Anonymous.view subModel)
        in
        [ div [] [ h1 [] [ text "yo" ] ]
        , subView
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Anonymous anonymous ->
            Sub.map GotAnonymousMsg (Anonymous.subscriptions anonymous)
