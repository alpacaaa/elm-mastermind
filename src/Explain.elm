module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class)
import String


main =
    Html.program
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- TYPES


type alias Model =
    { correct : Combination
    , guesses : List Guess
    }


type Color
    = Red
    | Green
    | Blue
    | Cyan
    | Yellow
    | Empty


type Hint
    = CorrectPosition
    | WrongPosition


type alias Combination =
    List Color


type alias Guess =
    ( Combination, List Hint )


type Msg
    = NoOp



-- MODEL


colors =
    [ Red, Green, Blue, Cyan, Yellow ]


correct =
    [ Green, Cyan, Cyan, Blue ]


guess1 =
    ( [ Yellow, Blue, Cyan, Red ]
    , [ CorrectPosition, WrongPosition ]
    )


guess2 =
    ( [ Green, Yellow, Cyan, Blue ]
    , [ CorrectPosition, CorrectPosition, WrongPosition ]
    )


guess3 =
    ( correct
    , [ CorrectPosition, CorrectPosition, CorrectPosition, CorrectPosition ]
    )


initialModel : ( Model, Cmd Msg )
initialModel =
    { correct = correct
    , guesses = [ guess1, guess2, guess3 ]
    }
        ! []



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []



-- VIEW


pegClass : Color -> String
pegClass color =
    String.toLower (toString color)


hintClass : Hint -> String
hintClass hint =
    case hint of
        CorrectPosition ->
            "black"

        WrongPosition ->
            "white"


drawPeg : Color -> Html Msg
drawPeg color =
    div [ class <| "peg " ++ (pegClass color) ] []


drawHint : Hint -> Html Msg
drawHint hint =
    div [ class <| "hint " ++ (hintClass hint) ] []


drawPegboard : Combination -> Html Msg
drawPegboard combination =
    div [ class "pegboard" ] <| List.map drawPeg combination


drawGuess : Guess -> Html Msg
drawGuess ( combination, hints ) =
    div [ class "decoding-row" ]
        [ drawPegboard combination
        , div [ class "hint-wrapper" ] (List.map drawHint hints)
        ]


renderGame guesses =
    div [ class "mastermind" ] [ div [] <| List.map drawGuess guesses ]


explain str t =
    p [ class "explain" ]
        [ text str
        , code [] [ text t ]
        ]


view : Model -> Html Msg
view model =
    div [ class "mastermind" ]
        [ explain "This is a " "Combination"
        , drawPegboard [ Red, Red, Red, Red ]
        , explain "Given the solution" ""
        , drawPegboard model.correct
        , explain "These are valid " "Guesses"
        , div [] <| List.map drawGuess model.guesses
        ]
