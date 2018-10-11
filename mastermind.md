### Mastermind in Elm



Let's kick off the new year with another game. This is a little bit more complex than the [Memory game](http:/adf) and [Rock Paper Scissors](http://asdfads) clones I implemented in Elm over the past few weeks. You might want to refer to those previous tutorials if you're not entirely familiar with Elm and how the Elm Architecture works. You can play with a live version here:



#### Types

So Mastermind. We'll need some colors to play with:

```haskell
type Color
    = Red
    | Green
    | Blue
    | Cyan
    | Yellow
    | Empty
```

Notice the `Empty` constructor. It has essentially the same meaning as `Nothing` in `Maybe` and should make the code much easier to write and understand.

A `Combination` is just a list of colors.

```haskell
type alias Combination =
    List Color
```

When the user makes a guess, we'll encode it with the `Guess` type. We also need to give back some hints to the user (the black and white pegs).

```haskell
type Hint
    = CorrectPosition
    | WrongPosition

type alias Guess =
    ( Combination, List Hint )
```

Our model is pretty simple. We have a `correct` field which is the `Combination` that the user has to guess. `guesses` is the list of `Guess` that the user has made so far and `state` indicates if we're still playing or else.

The `Playing` state holds the current guess (`Combination`). Notice that thanks to `Empty` as a `Color` constructor, we can have a combination that looks like this `[Red, Empty, Cyan, Cyan]`.

 `Index` is only needed for the UI, it indicates which color in the current combination the user is choosing.

```haskell
type alias Index =
    Int

type GameState
    = Playing Combination (Maybe Index)
    | GameOver
    | Surrender

type alias Model =
    { correct : Combination
    , guesses : List Guess
    , state : GameState
    }
```



#### Update

Let's write some helper functions to generate a list of random colors that we'll use to create the `Combination` the user has to guess.

```haskell
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
```

This is very similar to the random number generation we've seen in the [Memory Game](http://asdfas). I suggest you read that post if you don't understand what's going on and/or you're still struggling with commands and the Elm architecture.

I think `randomCombination` is pretty cool because it first creates a list of lists in this form `[ [ Red, Red, Red ], [Cyan, Cyan, Cyan], …]`, it concatenates it so we get a flat list and then uses  the other list we get as input (`random`) to generate a shuffled version, of which we're only interested in the first `size` elements.

The most interesting piece of this little game is the algorithm that takes a `Combination` and returns a `Guess`. I followed the guidelines found on a Stackoverflow post ([How to count the “white” correctly in mastermind guessing game](http://stackoverflow.com/questions/2005723/how-to-count-the-white-correctly-in-mastermind-guessing-game-in-c)), here they are:

> 1. Make two arrays, `ans` and `guess`, with a slot for each color.
> 2. For each color, populate `ans` with the number of pegs of that color. Similarly for `guess`.
> 3. Add up `min(ans[i], guess[i])` for each `i`. This is whites plus blacks.
> 4. Add up `max(ans[i] - guess[i], 0)` for each `i`. This is the number of whites.



We obviously need to convert them in a more functional style. This will be a good exercise if you find yourself thinking in imperative code and can't figure out how to write something in a functional manner. Let's go over each of these steps:

##### 1. Make two arrays, `ans` and `guess`, with a slot for each color.

This one is easy, we'll just create a fixed `List` with all of our colors.

```haskell
colors : List Color
colors =
    [ Red, Green, Blue, Cyan, Yellow ]
```

##### 2. For each color, populate `ans` with the number of pegs of that color. Similarly for `guess`.

Let's make a function `populate` that does exactly that. It takes a `Combination` (either `ans` or `guess`) and returns a list of tuples in the form `( Color, Int )`. The second value (`Int`) is obviously the number of occurencies of that color in the `Combination`.

```haskell
populate : Combination -> List ( Color, Int )
populate combination =
    let
        countOccurrencies c =
            List.filter ((==) c) combination
                |> List.length
    in
        List.map (\c -> ( c, countOccurrencies c )) colors
```

##### 3. Add up `min(ans[i], guess[i])` for each `i`. This is whites plus blacks.

We'll create a function `processGuess` that takes two `Combination` (the guess and the correct one). We'll employ the `populate` function we just created.

```haskell
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
    in
      -- TODO...  
```

`p` is a helper function that takes two tuples in the form `( Color, Int )` and returns the minimum value between the two integers. `whiteBlacks` is clearly the sum of the blacks and whites.

##### 4. Add up `max(ans[i] - guess[i], 0)` for each `i`. This is the number of whites. 

I found this to be very much unnecessary. Instead of counting the number of whites, it is much easier to count the number of blacks and then derive the whites by just subtracting the blacks from the total. Finding out the number of blacks is fairly straightforward:

```haskell
blacks =
    List.map2 (==) guess correct
        |> List.filter identity
        |> List.length

whites =
    whiteBlacks - blacks
```

We're essentially creating a new list with the result of comparing the two colors at the same index. This will be a list like `[True, False, False, False]`. All is left to do is to count the `True` values, so we'll filter on `identity` (recall that `List.filter` expects a `Bool` so we're already good) and take the length of the resulting list.

Here's the function in full:

```haskell
tag : a -> Int -> List a
tag =
    flip List.repeat

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
```

Just for reference, we can use it in the `update` function like this:

```haskell
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
```

Super cool!

#### Wrapping up

The view is fairly simple so I'm not going to touch on that. As always, I encourage you to go through the source code and play with it! I hope you got something out of this, if you enjoyed this article share it on Twitter and `Maybe` follow me :)
