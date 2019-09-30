module AttestationResponse exposing (attestationResponseDecoder)

import Json.Decode as D exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required)



-- MODEL


type alias AttestationResponse =
    { id : String
    , attObj : String
    , clientData : String
    , rawId : String
    , registrationClientExtensions : String
    , type_ : String
    }



-- DECODER


attestationResponseDecoder : Decoder AttestationResponse
attestationResponseDecoder =
    D.succeed AttestationResponse
        |> required "id" string
        |> required "attObj" string
        |> required "clientData" string
        |> required "rawId" string
        |> required "registrationClientExtensions" string
        |> required "type" string
