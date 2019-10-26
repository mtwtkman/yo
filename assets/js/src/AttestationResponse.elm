module AttestationResponse exposing (attestationResponseDecoder)

import Json.Decode as D exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required)



-- MODEL


type alias AttestationResponse =
    {  attObj : String
    , clientData : String
    }



-- DECODER


attestationResponseDecoder : Decoder AttestationResponse
attestationResponseDecoder =
    D.succeed AttestationResponse
        |> required "attObj" string
        |> required "clientData" string
