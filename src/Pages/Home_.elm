port module Pages.Home_ exposing (Model, Msg, page)

import Dict exposing (Dict)
import Effect exposing (Effect)
import Element exposing (Element, fill, height, scrollbars, width)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import Markdown exposing (defaultOptions)
import Maybe.Extra
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Style exposing (eachMargin, eachZero)
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page _ _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



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


init : () -> ( Model, Effect Msg )
init () =
    ( { selectedExample = List.head entrys |> Maybe.map .name
      , tryNowTexts = Dict.empty
      , consoleLogs = []
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NoOp
    | SelectExample String
    | UserTypedTryNow String String
    | ResetTryNow String
    | RunTryNow String
    | RxConsoleLog Value
    | UserSelectedExampleCode String String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )

        SelectExample entryName ->
            ( { model | selectedExample = Just entryName }
            , Effect.none
            )

        UserTypedTryNow entryName newText ->
            ( { model | tryNowTexts = Dict.insert entryName newText model.tryNowTexts }
            , Effect.none
            )

        ResetTryNow entryName ->
            ( { model | tryNowTexts = Dict.remove entryName model.tryNowTexts, consoleLogs = [] }
            , Effect.none
            )

        RunTryNow entryName ->
            ( { model | consoleLogs = [] }
            , Dict.get entryName model.tryNowTexts
                |> Maybe.Extra.orElse (Dict.get entryName entriesByName |> Maybe.map .defaultTryNow)
                |> Maybe.Extra.unwrap Effect.none (Effect.sendJsToRun entryName)
            )

        RxConsoleLog consoleJson ->
            case JD.decodeValue logEntryDecoder consoleJson of
                Ok logEntry ->
                    ( { model | consoleLogs = logEntry :: model.consoleLogs }
                    , Effect.none
                    )

                Err _ ->
                    ( model, Effect.none )

        UserSelectedExampleCode entryName newText ->
            ( { model | tryNowTexts = Dict.insert entryName newText model.tryNowTexts }
            , Effect.none
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



-- SUBSCRIPTIONS


port console : (Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    console RxConsoleLog



-- VIEW


view : Model -> View Msg
view model =
    { title = "MyInsights Interactive Developer Docs"
    , attributes = [ width fill, height fill ]
    , element =
        Element.row [ width fill, height fill ]
            [ viewSidebar model, viewBody model ]
    }


viewSidebar : Model -> Element Msg
viewSidebar model =
    Element.column
        [ height fill
        , Element.paddingEach { eachMargin | left = 0 }
        , Element.Border.widthEach { eachZero | right = 1 }
        , Element.Border.color Style.silverLight
        ]
        (List.map (viewSidebarItem model) entrys)


viewSidebarItem : Model -> Entry -> Element Msg
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
        { onPress = Just (SelectExample entry.name)
        , label = Element.text entry.name
        }


viewBody : Model -> Element Msg
viewBody model =
    model.selectedExample
        |> Maybe.andThen (\entryName -> Dict.get entryName entriesByName)
        |> Maybe.map (viewExampleBody model)
        |> Maybe.withDefault Element.none


viewExampleBody : Model -> Entry -> Element Msg
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

        -- Element.el [ width fill, height fill, scrollbars ] (Element.html (Markdown.toHtmlWith markdownOptions [] entry.docs))
        , Element.column
            [ height Element.shrink
            , Element.alignBottom
            , width fill
            , Element.spacing Style.margin
            , Element.Border.widthEach { eachZero | top = 1 }
            , Element.Border.color Style.silverLight
            , Element.paddingEach { eachZero | top = Style.margin }
            ]
            [ Element.Input.multiline [ height (Element.shrink |> Element.minimum 100 |> Element.maximum 300) ]
                { onChange = UserTypedTryNow entry.name
                , text = Dict.get entry.name model.tryNowTexts |> Maybe.withDefault entry.defaultTryNow
                , placeholder = Nothing
                , label =
                    Element.Input.labelAbove []
                        (Element.text "Try Now")
                , spellcheck = False
                }
            , Element.row [ width fill, Element.spacing Style.margin ]
                [ Element.column
                    [ height fill
                    , Element.spacing Style.margin
                    , width (Element.shrink |> Element.minimum 100)
                    ]
                    [ Element.Input.button []
                        { onPress = Just (RunTryNow entry.name)
                        , label = Element.text "Run"
                        }
                    , Element.Input.button []
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
                            , Element.scrollbarY
                            , Element.Border.widthEach { eachZero | top = 1 }
                            , Element.Border.color Style.silverLight
                            , Element.paddingEach { eachZero | top = Style.margin }
                            ]
                            (List.map (viewExample entry) entry.tryNowOptions)
                    ]
                , Element.column
                    [ height (Element.px 200)
                    , width fill
                    , Element.scrollbarY
                    , Element.Border.width 1
                    , Element.Border.color Style.silverLight
                    , Element.Background.color Style.white
                    ]
                    (List.map viewConsoleLogEntry (List.reverse model.consoleLogs))
                ]
            ]
        ]


markdownOptions : Markdown.Options
markdownOptions =
    { defaultOptions | githubFlavored = Just { tables = True, breaks = True } }


viewExample : Entry -> { name : String, code : String } -> Element Msg
viewExample entry { name, code } =
    Element.Input.button []
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



-- DOCUMENTATION ENTRIES


type alias Entry =
    { name : String
    , docs : Element Msg
    , defaultTryNow : String
    , tryNowOptions : List { name : String, code : String }
    }


entrys : List Entry
entrys =
    [ { name = "getDataForCurrentObject"
      , docs =
            standardDocs
                { title = "getDataForCurrentObject(object, field)"
                , blurb = "Asynchronously fetches a field from the current object."
                , parameters =
                    [ { name = "object", type_ = "string", description = "The API name of the object that you wish to query." }
                    , { name = "field", type_ = "string", description = "The API name of the field that you wish to query." }
                    ]
                , return = standardQueryReturn
                }
      , defaultTryNow = """ds.getDataForCurrentObject("user__sys", "name__v")
// get the name of the current user"""
      , tryNowOptions =
            [ { name = "Log", code = "console.log('log')" }
            , { name = "Warn", code = "console.warn('warning')" }
            , { name = "Error", code = "console.error('error')" }
            , { name = "All three", code = "console.log('log') \nconsole.warn('warning') \nconsole.error('error')" }
            ]
      }
    , { name = "queryRecord"
      , docs =
            standardDocs
                { title = "queryRecord(config)"
                , blurb = "query records"
                , parameters = []
                , return = standardQueryReturn
                }
      , defaultTryNow = "ds.queryRecord({...})"
      , tryNowOptions =
            [ { name = "Calls", code = "//put call query here" }
            , { name = "Accounts", code = "//put account query here" }
            ]
      }
    ]


type alias StandardDoc =
    { title : String
    , blurb : String
    , parameters : List { name : String, type_ : String, description : String }
    , return : String
    }


standardDocs : StandardDoc -> Element Msg
standardDocs doc =
    Element.column
        [ width fill
        , height fill
        , Element.scrollbarY
        , Element.spacing Style.margin
        , Element.Region.mainContent
        ]
        [ h1 doc.title
        , h2 "Parameters"
        , Element.table [ Element.spacing Style.margin ]
            { data = doc.parameters
            , columns =
                [ { header = Element.text "Name", width = Element.shrink, view = .name >> Element.text }
                , { header = Element.text "Type", width = Element.shrink, view = .type_ >> Element.text }
                , { header = Element.text "Description", width = fill, view = .description >> Element.text >> List.singleton >> Element.paragraph [] }
                ]
            }
        , h2 "Return"
        , Element.text doc.return
        ]


h1 : String -> Element msg
h1 =
    Element.el [ Element.Region.heading 1, Element.Font.size 32 ] << Element.text


h2 : String -> Element msg
h2 =
    Element.el [ Element.Region.heading 2, Element.Font.size 24 ] << Element.text


standardQueryReturn : String
standardQueryReturn =
    "Returns a promise that will resolve with the results of the query."


entriesByName : Dict String Entry
entriesByName =
    entrys
        |> List.map (\entry -> ( entry.name, entry ))
        |> Dict.fromList
