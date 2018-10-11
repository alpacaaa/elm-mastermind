module Main exposing (Color(..), Combination, Guess, Hint(..), Model, Msg(..), colors, correct, drawGuess, drawHint, drawPeg, drawPegboard, explain, guess1, guess2, guess3, hintClass, initialModel, main, pegClass, renderGame, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class)
import String


main: Program () Model Msg
main =
    Browser.element
        { init = \_ -> initialModel
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
    ( { correct = correct
      , guesses = [ guess1, guess2, guess3 ]
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


pegClass : Color -> String
pegClass color =
    String.toLower <|
        case color of
            Red ->
                "Red"

            Green ->
                "Green"

            Blue ->
                "Blue"

            Cyan ->
                "Cyan"

            Yellow ->
                "Yellow"

            Empty ->
                ""


hintClass : Hint -> String
hintClass hint =
    case hint of
        CorrectPosition ->
            "black"

        WrongPosition ->
            "white"


drawPeg : Color -> Html Msg
drawPeg color =
    div [ class <| "peg " ++ pegClass color ] []


drawHint : Hint -> Html Msg
drawHint hint =
    div [ class <| "hint " ++ hintClass hint ] []


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
