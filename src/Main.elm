port module Main exposing (main)

import Browser
import Browser.Events
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
import Html.Attributes
import Html.Events
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import Maybe.Extra
import Style exposing (eachMargin, eachZero)


main : Program Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


entriesByName : Dict String (Entry msg)
entriesByName =
    Documentation.entries
        |> List.map (\entry -> ( entry.name, entry ))
        |> Dict.fromList



-- INIT


type alias Model =
    { selectedExample : Maybe String
    , tryNowTexts : Dict String String
    , consoleLogs : List ConsoleEntry
    , window : Window
    }


type alias ConsoleEntry =
    { level : ConsoleLevel
    , text : String
    }


type alias Window =
    { resizeCount : Int
    , width : Int
    , height : Int
    }


type ConsoleLevel
    = Log
    | Warn
    | Error


init : Value -> ( Model, Cmd Msg )
init flags =
    ( { selectedExample = List.head Documentation.entries |> Maybe.map .name
      , tryNowTexts = Dict.empty
      , consoleLogs = []
      , window =
            JD.decodeValue windowDecoder flags
                |> Result.withDefault { width = 1024, height = 768, resizeCount = 0 }
      }
    , Cmd.none
    )


windowDecoder : Decoder Window
windowDecoder =
    JD.map2 (Window 0)
        (JD.field "width" JD.int)
        (JD.field "height" JD.int)



-- UPDATE


type Msg
    = NoOp
    | SelectDocEntry String
    | UserTypedTryNow String String
    | ResetTryNow String
    | RunTryNow String
    | RxConsoleLog Value
    | UserSelectedExampleCode String String
    | WindowResized Int Int


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
            ( { model
                | tryNowTexts =
                    if model.selectedExample == Just entryName then
                        Dict.insert entryName newText model.tryNowTexts

                    else
                        model.tryNowTexts
              }
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
                    if List.member logEntry ignoredEntries then
                        ( model, Cmd.none )

                    else
                        ( { model | consoleLogs = logEntry :: model.consoleLogs }
                        , Cmd.none
                        )

                Err _ ->
                    ( model, Cmd.none )

        UserSelectedExampleCode entryName newText ->
            ( { model | tryNowTexts = Dict.insert entryName newText model.tryNowTexts }
            , Cmd.none
            )

        WindowResized width height ->
            ( { model | window = { width = width, height = height, resizeCount = model.window.resizeCount + 1 } }
            , Cmd.none
            )


ignoredEntries : List ConsoleEntry
ignoredEntries =
    [ { level = Warn
      , text = "\"deferred object not found\" {\"command\":\"queryReturn\"}"
      }
    ]


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
    Sub.batch
        [ console RxConsoleLog
        , Browser.Events.onResize WindowResized
        ]



-- VIEW


type PlatformGuess
    = ProbablyOnline
    | ProbablyIpad
    | ProbablyIphone


guessPlatform : Window -> PlatformGuess
guessPlatform window =
    if window.resizeCount > 1 || window.height < 200 then
        ProbablyOnline

    else
        let
            device =
                Element.classifyDevice window
        in
        case ( device.class, device.orientation ) of
            ( Element.Phone, Element.Portrait ) ->
                -- the iPhone app is only ever in portrait mode
                ProbablyIphone

            ( Element.Tablet, Element.Landscape ) ->
                -- the iPad app is only ever in landscape mode
                ProbablyIpad

            _ ->
                ProbablyOnline


view : Model -> Html Msg
view model =
    viewLayout (guessPlatform model.window) model


viewLayout : PlatformGuess -> Model -> Html Msg
viewLayout platform model =
    Element.layout
        ([ width fill
         , Element.clip
         , Element.Font.size 14
         , Element.Font.color Style.extendedCoal
         , Element.Font.family [ Element.Font.typeface "-apple-system", Element.Font.sansSerif ]
         ]
            ++ platformLayoutAttrs platform
        )
        (case platform of
            ProbablyOnline ->
                Element.row [ width fill, height fill ]
                    [ viewOnlineSidebar model, viewOnlineBody model ]

            ProbablyIpad ->
                Element.row [ width fill, height fill ]
                    [ viewIpadSidebar model, viewIpadBody model ]

            ProbablyIphone ->
                Element.column [ width fill, height fill, Element.scrollbarY ]
                    [ viewIphoneHeader model, viewIphoneBody model ]
        )


platformLayoutAttrs : PlatformGuess -> List (Element.Attribute Msg)
platformLayoutAttrs platform =
    case platform of
        ProbablyOnline ->
            [ Element.height Element.shrink
            , Element.inFront (Element.html (Html.node "style" [] [ Html.text "html,body{height:auto !important};" ]))
            ]

        _ ->
            [ height fill ]


viewOnlineSidebar : Model -> Element Msg
viewOnlineSidebar =
    viewSidebar
        [ height (Element.shrink |> Element.minimum 600)
        , Element.alignTop
        ]


viewIpadSidebar : Model -> Element Msg
viewIpadSidebar =
    viewSidebar
        [ height fill
        , Element.htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , Element.scrollbarY
        ]


viewIphoneHeader : Model -> Element Msg
viewIphoneHeader =
    viewSidebar
        [ width fill, height Element.shrink ]


viewSidebar : List (Element.Attribute Msg) -> Model -> Element Msg
viewSidebar extraAttrs model =
    Element.column
        (extraAttrs
            ++ [ Element.paddingEach { eachMargin | left = 0 }
               , Element.Border.widthEach { eachZero | right = 1 }
               , Element.Border.color Style.silverLight
               ]
        )
        (List.map (viewSidebarItem model) Documentation.entries)


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


viewOnlineBody : Model -> Element Msg
viewOnlineBody =
    viewBody [ Element.scrollbarY ]


viewIpadBody : Model -> Element Msg
viewIpadBody =
    viewBody [ Element.scrollbarY ]


viewIphoneBody : Model -> Element Msg
viewIphoneBody =
    viewBody []


viewBody : List (Element.Attribute Msg) -> Model -> Element Msg
viewBody extraAttrs model =
    model.selectedExample
        |> Maybe.andThen (\entryName -> Dict.get entryName entriesByName)
        |> Maybe.map (viewExampleBody extraAttrs model)
        |> Maybe.withDefault Element.none


viewExampleBody : List (Element.Attribute Msg) -> Model -> Entry Msg -> Element Msg
viewExampleBody extraAttrs model entry =
    Element.column
        ([ height fill
         , width fill
         , Element.padding Style.margin
         , Element.spacing Style.margin
         , Element.Background.color Style.background
         ]
            ++ extraAttrs
        )
        [ entry.docs
        , Components.Card.view "Try Now" <|
            Element.column
                [ height Element.shrink
                , width fill
                ]
                [ Element.row [ width fill, Element.spacing Style.margin ]
                    [ if List.isEmpty entry.tryNowOptions then
                        Element.none

                      else
                        Element.column
                            [ width (Element.shrink |> Element.minimum 100)
                            , Element.spacing Style.margin
                            , height fill
                            , Element.Border.widthEach { eachZero | top = 1 }
                            , Element.Border.color Style.silverLight
                            , Element.paddingEach { eachZero | top = Style.margin }
                            ]
                            (List.map (viewExample entry) entry.tryNowOptions)
                    , Element.el [ width fill ]
                        (Element.html
                            (Html.node "codemirror-element"
                                [ Html.Attributes.attribute "value"
                                    (Dict.get entry.name model.tryNowTexts
                                        |> Maybe.withDefault entry.defaultTryNow
                                    )
                                , Html.Events.on "codemirrorInput" (JD.map (UserTypedTryNow entry.name) (JD.field "detail" JD.string))
                                ]
                                []
                            )
                        )
                    ]
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
                            , label = Element.text "Run ›"
                            }
                        , Element.Input.button
                            [ width fill
                            , Element.padding Style.margin
                            , Element.focused [ Element.Background.color Style.extendedMist ]
                            ]
                            { onPress = Just (ResetTryNow entry.name)
                            , label = Element.text "Reset"
                            }
                        ]
                    , Element.column
                        [ height (Element.shrink |> Element.minimum 200 |> Element.maximum 400)
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
    let
        textToShow =
            case
                JD.decodeString JD.value logEntry.text
            of
                Ok value ->
                    JE.encode 4 value

                Err _ ->
                    logEntry.text
    in
    Element.row [ width fill, Element.Background.color (colorForLevel logEntry.level) ]
        [ Element.el [ Element.alignTop ] (Element.text "› ")
        , textToShow
            |> String.lines
            |> List.map (replaceLeadingSpaces >> Element.text >> List.singleton >> Element.paragraph [ width fill ])
            |> Element.column [ width fill ]
        ]


replaceLeadingSpaces : String -> String
replaceLeadingSpaces =
    String.toList
        >> countAndTrimLeadingSpaces
        >> (\( count, restOfLine ) -> String.repeat count "\u{00A0}" ++ String.fromList restOfLine)


countAndTrimLeadingSpaces : List Char -> ( Int, List Char )
countAndTrimLeadingSpaces chars =
    let
        recursionHelper countSoFar charsRemaining =
            case charsRemaining of
                ' ' :: rest ->
                    recursionHelper (countSoFar + 1) rest

                _ ->
                    ( countSoFar, charsRemaining )
    in
    recursionHelper 0 chars


colorForLevel : ConsoleLevel -> Element.Color
colorForLevel level =
    case level of
        Log ->
            Style.white

        Warn ->
            Style.warningBackground

        Error ->
            Style.errorBackground
