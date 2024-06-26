port module Main exposing (main)

import Browser
import Components.Card
import Dict exposing (Dict)
import DocHelpers exposing (Entry)
import Documentation
import Element exposing (Element, fill, height, width)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import Html exposing (Html)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import Maybe.Extra
import Style exposing (eachMargin, eachZero)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


entriesByName : Dict String (Entry msg)
entriesByName =
    Documentation.entrys
        |> List.map (\entry -> ( entry.name, entry ))
        |> Dict.fromList



-- INIT


type alias Model =
    { selectedExample : Maybe String
    , tryNowTexts : Dict String String
    , consoleLogs : List ConsoleEntry
    }


type alias ConsoleEntry =
    { level : ConsoleLevel
    , text : String
    }


type ConsoleLevel
    = Log
    | Warn
    | Error


init : () -> ( Model, Cmd Msg )
init () =
    ( { selectedExample = List.head Documentation.entrys |> Maybe.map .name
      , tryNowTexts = Dict.empty
      , consoleLogs = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | SelectDocEntry String
    | UserTypedTryNow String String
    | ResetTryNow String
    | RunTryNow String
    | RxConsoleLog Value
    | UserSelectedExampleCode String String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        SelectDocEntry entryName ->
            ( { model | selectedExample = Just entryName, consoleLogs = [] }
            , Cmd.none
            )

        UserTypedTryNow entryName newText ->
            ( { model | tryNowTexts = Dict.insert entryName newText model.tryNowTexts }
            , Cmd.none
            )

        ResetTryNow entryName ->
            ( { model | tryNowTexts = Dict.remove entryName model.tryNowTexts, consoleLogs = [] }
            , Cmd.none
            )

        RunTryNow entryName ->
            ( { model | consoleLogs = [] }
            , Dict.get entryName model.tryNowTexts
                |> Maybe.Extra.orElse (Dict.get entryName entriesByName |> Maybe.map .defaultTryNow)
                |> Maybe.Extra.unwrap Cmd.none (sendJsToRun entryName)
            )

        RxConsoleLog consoleJson ->
            case JD.decodeValue logEntryDecoder consoleJson of
                Ok logEntry ->
                    ( { model | consoleLogs = logEntry :: model.consoleLogs }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        UserSelectedExampleCode entryName newText ->
            ( { model | tryNowTexts = Dict.insert entryName newText model.tryNowTexts }
            , Cmd.none
            )


logEntryDecoder : Decoder ConsoleEntry
logEntryDecoder =
    JD.map2 ConsoleEntry
        (JD.field "level" consoleLevelDecoder)
        (JD.field "args"
            (JD.oneOf
                [ JD.string
                , JD.list JD.string |> JD.map (String.join " ")
                , JD.list JD.value |> JD.map (List.map (JE.encode 0) >> String.join " ")
                ]
            )
        )


consoleLevelDecoder : Decoder ConsoleLevel
consoleLevelDecoder =
    JD.string
        |> JD.andThen
            (\words ->
                case words of
                    "LOG" ->
                        JD.succeed Log

                    "WARN" ->
                        JD.succeed Warn

                    "ERROR" ->
                        JD.succeed Error

                    _ ->
                        JD.fail ("Invalid console level: '" ++ words ++ "'")
            )



-- PORTS


port elmToJs : { tag : String, data : Value } -> Cmd msg


sendJsToRun : String -> String -> Cmd msg
sendJsToRun entryName jsTextToRun =
    elmToJs
        { tag = "RUN_JS"
        , data =
            JE.object
                [ ( "entry", JE.string entryName )
                , ( "code", JE.string jsTextToRun )
                ]
        }


port console : (Value -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    console RxConsoleLog



-- VIEW


view : Model -> Html Msg
view model =
    Element.layout
        [ width fill
        , height fill
        , Element.Font.size 14
        , Element.Font.color Style.extendedCoal
        , Element.Font.family [ Element.Font.typeface "-apple-system", Element.Font.sansSerif ]
        ]
        (Element.row [ width fill, height fill ]
            [ viewSidebar model, viewBody model ]
        )


viewSidebar : Model -> Element Msg
viewSidebar model =
    Element.column
        [ height fill
        , Element.paddingEach { eachMargin | left = 0 }
        , Element.Border.widthEach { eachZero | right = 1 }
        , Element.Border.color Style.silverLight
        ]
        (List.map (viewSidebarItem model) Documentation.entrys)


viewSidebarItem : Model -> Entry Msg -> Element Msg
viewSidebarItem model entry =
    Element.Input.button
        [ Element.Font.family
            [ Element.Font.monospace ]
        , width fill
        , Element.padding Style.margin
        , Element.Border.widthEach { eachZero | left = 4 }
        , Element.Border.color
            (if model.selectedExample == Just entry.name then
                Style.blueDefault

             else
                Style.white
            )
        , Element.Region.navigation
        , Element.focused
            []
        ]
        { onPress = Just (SelectDocEntry entry.name)
        , label = Element.text entry.name
        }


viewBody : Model -> Element Msg
viewBody model =
    model.selectedExample
        |> Maybe.andThen (\entryName -> Dict.get entryName entriesByName)
        |> Maybe.map (viewExampleBody model)
        |> Maybe.withDefault Element.none


viewExampleBody : Model -> Entry Msg -> Element Msg
viewExampleBody model entry =
    Element.column
        [ height fill
        , width fill
        , Element.padding Style.margin
        , Element.spacing Style.margin
        , Element.scrollbarY
        , Element.Background.color Style.background
        ]
        [ entry.docs
        , Components.Card.view "Try Now" <|
            Element.column
                [ height Element.shrink
                , width fill
                , Element.spacing Style.margin
                ]
                [ Element.Input.multiline [ height (Element.shrink |> Element.minimum 50 |> Element.maximum 300) ]
                    { onChange = UserTypedTryNow entry.name
                    , text = Dict.get entry.name model.tryNowTexts |> Maybe.withDefault entry.defaultTryNow
                    , placeholder = Nothing
                    , label = Element.Input.labelHidden "Code"
                    , spellcheck = False
                    }
                , Element.row [ width fill, Element.spacing Style.margin ]
                    [ Element.column
                        [ height fill
                        , Element.spacing Style.margin
                        , width (Element.shrink |> Element.minimum 100)
                        ]
                        [ Element.Input.button
                            [ width fill
                            , Element.padding Style.margin
                            , Element.focused [ Element.Background.color Style.extendedMist ]
                            ]
                            { onPress = Just (RunTryNow entry.name)
                            , label = Element.text "Run"
                            }
                        , Element.Input.button
                            [ width fill
                            , Element.padding Style.margin
                            , Element.focused [ Element.Background.color Style.extendedMist ]
                            ]
                            { onPress = Just (ResetTryNow entry.name)
                            , label = Element.text "Reset"
                            }
                        , if List.isEmpty entry.tryNowOptions then
                            Element.none

                          else
                            Element.column
                                [ width fill
                                , Element.spacing Style.margin
                                , height fill
                                , Element.Border.widthEach { eachZero | top = 1 }
                                , Element.Border.color Style.silverLight
                                , Element.paddingEach { eachZero | top = Style.margin }
                                ]
                                (List.map (viewExample entry) entry.tryNowOptions)
                        ]
                    , Element.column
                        [ height (Element.shrink |> Element.minimum 200 |> Element.maximum 600)
                        , width fill
                        , Element.scrollbarY
                        , Element.Border.width 1
                        , Element.Border.color Style.silverLight
                        , Element.Background.color Style.white
                        , Element.alignTop
                        ]
                        (List.map viewConsoleLogEntry (List.reverse model.consoleLogs))
                    ]
                ]
        ]


viewExample : Entry Msg -> { name : String, code : String } -> Element Msg
viewExample entry { name, code } =
    Element.Input.button
        [ width fill
        , Element.padding Style.margin
        , Element.focused [ Element.Background.color Style.extendedMist ]
        ]
        { onPress = Just (UserSelectedExampleCode entry.name code)
        , label = Element.text name
        }


viewConsoleLogEntry : ConsoleEntry -> Element Msg
viewConsoleLogEntry logEntry =
    Element.row [ width fill, Element.Background.color (colorForLevel logEntry.level) ]
        [ Element.el [ Element.alignTop ] (Element.text "> ")
        , logEntry.text
            |> String.split "\n"
            |> List.map (Element.text >> List.singleton >> Element.paragraph [ width fill ])
            |> Element.column [ width fill ]
        ]


colorForLevel : ConsoleLevel -> Element.Color
colorForLevel level =
    case level of
        Log ->
            Style.white

        Warn ->
            Style.warningBackground

        Error ->
            Style.errorBackground
