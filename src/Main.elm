module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, disabled, style)
import Html.Events exposing (onClick)
import Random
import String
import Browser

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
    , state : GameState
    }


type GameState
    = Playing Combination (Maybe Index)
    | GameOver
    | Surrender


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


type alias Index =
    Int


type Msg
    = NoOp Index
    | Shuffle (List Int)
    | SelectPeg Index
    | Choose Color
    | Confirm
    | Reset
    | ShowCorrect



-- MODEL


guessSize : Int
guessSize =
    4


colors : List Color
colors =
    [ Red, Green, Blue, Cyan, Yellow ]


emptyCombination : Combination
emptyCombination =
    List.repeat guessSize Empty


initialModel : ( Model, Cmd Msg )
initialModel =
    ( { correct = [ Red, Green, Green, Blue ]
      , guesses = []
      , state = Playing emptyCombination Nothing
      }
    , randomList Shuffle (guessSize * guessSize)
    )



-- UPDATE


randomList : (List Int -> Msg) -> Int -> Cmd Msg
randomList msg len =
    Random.int 0 100
        |> Random.list len
        |> Random.generate msg


shuffle : List comparable -> List a -> List a
shuffle random list =
    List.map2 (\a b -> ( a, b )) list random
        |> List.sortBy Tuple.second
        |> List.unzip
        |> Tuple.first


randomCombination : Int -> List a -> List comparable -> List a
randomCombination size xs random =
    List.map (List.repeat size) xs
        |> List.concat
        |> shuffle random
        |> List.take size



{--
Make two arrays, ans and guess, with a slot for each color.
For each color, populate ans with the number of pegs of that color. Similarly for guess.
Add up min(ans[i], guess[i]) for each i. This is whites plus blacks.
Add up max(ans[i] - guess[i], 0) for each i. This is the number of whites.
Counting blacks is easy, just check one by one
http://stackoverflow.com/questions/2005723/how-to-count-the-white-correctly-in-mastermind-guessing-game-in-c
--}


tag : a -> Int -> List a
tag =
    \b a -> List.repeat a b


processGuess : Combination -> Combination -> Guess
processGuess guess correct =
    let
        ans =
            populate correct

        gus =
            populate guess

        p ( _, count1 ) ( _, count2 ) =
            min count1 count2

        whiteBlacks =
            List.sum <| List.map2 p ans gus

        blacks =
            List.map2 (==) guess correct
                |> List.filter identity
                |> List.length

        whites =
            whiteBlacks - blacks
    in
        ( guess, (tag CorrectPosition blacks) ++ (tag WrongPosition whites) )


populate : Combination -> List ( Color, Int )
populate combination =
    let
        countOccurrencies c =
            List.filter ((==) c) combination
                |> List.length
    in
        List.map (\c -> ( c, countOccurrencies c )) colors


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset ->
            initialModel

        _ ->
            ( update_ msg model
            , Cmd.none
            )


update_ : Msg -> Model -> Model
update_ msg model =
    case msg of
        SelectPeg index ->
            { model
                | state =
                    case model.state of
                        Playing combination _ ->
                            Playing combination (Just index)

                        _ ->
                            model.state
            }

        Choose color ->
            case model.state of
                Playing combination (Just index) ->
                    let
                        replace i item =
                            if i == index then
                                color
                            else
                                item

                        newCombination =
                            List.indexedMap replace combination
                    in
                        { model | state = Playing newCombination Nothing }

                _ ->
                    model

        Confirm ->
            case model.state of
                Playing combination _ ->
                    let
                        isOver =
                            combination == model.correct

                        guess =
                            processGuess combination model.correct

                        newModel =
                            { model | guesses = model.guesses ++ [ guess ] }
                    in
                    if isOver then
                        { newModel | state = GameOver }

                    else
                        { newModel | state = Playing emptyCombination Nothing }

                _ ->
                    model

        Shuffle random ->
            { model | correct = randomCombination guessSize colors random }

        ShowCorrect ->
            { model | state = Surrender }

        _ ->
            model



-- VIEW


pegClass : Color -> String
pegClass color =
    String.toLower <|
        case color of
            Red -> "Red"
            Green -> "Green"
            Blue -> "Blue"
            Cyan -> "Cyan"
            Yellow -> "Yellow"
            Empty -> ""



hintClass : Hint -> String
hintClass hint =
    case hint of
        CorrectPosition ->
            "black"

        WrongPosition ->
            "white"


drawPeg : Msg -> Color -> Html Msg
drawPeg msg color =
    div [ class <| "peg " ++ pegClass color, onClick msg ] []


drawHint : Hint -> Html Msg
drawHint hint =
    div [ class <| "hint " ++ hintClass hint ] []


drawPegboard : Combination -> (Index -> Msg) -> Html Msg
drawPegboard combination msg =
    div [ class "pegboard" ] <| List.indexedMap (drawPeg << msg) combination


drawGuess : Guess -> Html Msg
drawGuess ( combination, hints ) =
    div [ class "decoding-row" ]
        [ drawPegboard combination NoOp
        , div [ class "hint-wrapper" ] (List.map drawHint hints)
        ]


pegChooser : Maybe Index -> Html Msg
pegChooser selected =
    case selected of
        Nothing ->
            div [] []

        Just index ->
            let
                leftCss : String
                leftCss =
                    (String.fromInt <| 60 * index) ++ "px"

            in
                div [ class "chooser", style "left" leftCss ]
                    [ drawPeg (Choose Red) Red
                    , drawPeg (Choose Yellow) Yellow
                    , drawPeg (Choose Green) Green
                    , drawPeg (Choose Cyan) Cyan
                    , drawPeg (Choose Blue) Blue
                    ]


decodingRow : Combination -> Maybe Index -> Html Msg
decodingRow combination selectedPeg =
    let
        canConfirm =
            List.all ((/=) Empty) combination
    in
    div [ class "decoding-row current-combination" ]
        [ drawPegboard combination SelectPeg
        , button [ disabled (not canConfirm), onClick Confirm ] [ text "Confirm" ]
        , pegChooser selectedPeg
        ]


gameView : List Guess -> Html Msg -> Html Msg
gameView guesses extra =
    div [ class "mastermind" ]
        [ div [] <| List.map drawGuess guesses
        , extra
        ]


renderGame : List Guess -> Combination -> Maybe Index -> Html Msg
renderGame guesses combination selectedPeg =
    gameView guesses (decodingRow combination selectedPeg)


showCorrect : Msg -> Html Msg
showCorrect msg =
    div [ class "show-correct" ]
        [ text "I had enough!"
        , button [ onClick msg ] [ text "Show me the answer" ]
        ]


info : Html a
info =
    div [ class "show-correct" ]
        [ text "Guess the correct combination" ]


surrenderView : Combination -> Html Msg
surrenderView correct =
    div [ class "surrender" ]
        [ drawPegboard correct NoOp ]


playAgain : Msg -> String -> Html Msg
playAgain msg infoMsg =
    div [ class "congrats" ]
        [ p [] [ text infoMsg ]
        , text "Do you want to "
        , span [ onClick Reset ] [ text "play again?" ]
        ]


view : Model -> Html Msg
view model =
    case model.state of
        Playing combination maybeSelected ->
            div []
                [ if List.length model.guesses > 0 then
                    showCorrect ShowCorrect
                  else
                    info
                , renderGame model.guesses combination maybeSelected
                ]

        GameOver ->
            gameView model.guesses (playAgain Reset "Yay! You win!")

        Surrender ->
            div []
                [ gameView model.guesses (surrenderView model.correct)
                , playAgain Reset "C'mon you can do it."
                ]
