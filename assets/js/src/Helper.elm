module Helper exposing (isJust, toCharCodePoints)

import Base64
import Char


isJust : Maybe a -> Bool
isJust maybeValue =
    case maybeValue of
        Just v ->
            True

        Nothing ->
            False


toCharCodePoints : String -> List Int
toCharCodePoints encoded =
    case Base64.decode encoded of
        Err _ ->
            []

        Ok decoded ->
            List.map Char.toCode <| String.toList decoded
