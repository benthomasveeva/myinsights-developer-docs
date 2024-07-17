module CreateDocumentation exposing (generateFromDirectory)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Dict exposing (Dict)
import Dict.Extra
import DocHelpers exposing (..)
import Elm
import FatalError exposing (FatalError)
import Gen.DocHelpers
import Json.Decode as JD exposing (Decoder)
import Json.Decode.Pipeline as JDPipe
import Pages.Script as Script exposing (Script)
import String.Extra


generateFromDirectory : String -> Script
generateFromDirectory dirName =
    Script.withoutCliOptions
        (BackendTask.map3 makeDocFile
            (readDocJsonFile dirName)
            (readDefaultTryNowFiles dirName)
            (readTryNowExampleFiles dirName)
            |> BackendTask.andThen writeDocFile
        )


readDocJsonFile : String -> BackendTask FatalError (List ( String, StandardDoc ))
readDocJsonFile dirName =
    File.jsonFile entryDecoder ("docs/" ++ dirName ++ "/docs.json")
        |> BackendTask.allowFatal


entryDecoder : Decoder (List ( String, StandardDoc ))
entryDecoder =
    JD.keyValuePairs
        (JD.succeed StandardDoc
            |> JDPipe.required "title" JD.string
            |> JDPipe.required "blurb" JD.string
            |> JDPipe.optional "parameters" (JD.list parameterDecoder) []
            |> JDPipe.optional "return" JD.string standardQueryReturn
        )


type alias FileId =
    { filepath : String, key : String }


findDefaultTryNowFiles : String -> BackendTask FatalError (List FileId)
findDefaultTryNowFiles dirName =
    Glob.succeed FileId
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal ("docs/" ++ dirName ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".js")
        |> Glob.toBackendTask
        |> BackendTask.allowFatal


readDefaultTryNowFiles : String -> BackendTask FatalError (Dict String String)
readDefaultTryNowFiles dirName =
    findDefaultTryNowFiles dirName
        |> BackendTask.map
            (List.map
                (\fileId ->
                    File.rawFile fileId.filepath
                        |> BackendTask.map (Tuple.pair fileId.key)
                        |> BackendTask.allowFatal
                )
            )
        |> BackendTask.resolve
        |> BackendTask.map Dict.fromList


type alias ExampleId =
    { filepath : String
    , key : String
    , name : String
    }


findTryNowExampleFiles : String -> BackendTask FatalError (List ExampleId)
findTryNowExampleFiles dirName =
    Glob.succeed ExampleId
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal ("docs/" ++ dirName ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".js")
        |> Glob.toBackendTask
        |> BackendTask.allowFatal


type alias FullExample =
    { key : String
    , name : String
    , code : String
    }


readTryNowExampleFiles : String -> BackendTask FatalError (Dict String (List Example))
readTryNowExampleFiles dirName =
    findTryNowExampleFiles dirName
        |> BackendTask.map
            (List.map
                (\exampleId ->
                    File.rawFile exampleId.filepath
                        |> BackendTask.map (FullExample exampleId.key exampleId.name)
                        |> BackendTask.allowFatal
                )
            )
        |> BackendTask.resolve
        |> BackendTask.map toExampleDict


toExampleDict : List FullExample -> Dict String (List Example)
toExampleDict =
    Dict.Extra.groupBy .key
        >> Dict.map (\_ -> List.map toExample)


toExample : FullExample -> Example
toExample example =
    { name = String.Extra.humanize example.name
    , code = example.code
    }


makeDocFile : List ( String, StandardDoc ) -> Dict String String -> Dict String (List Example) -> Elm.File
makeDocFile docs defaultTryNows namedExamples =
    Elm.file [ "Documentation" ]
        [ Elm.declaration "entries" (Elm.list (List.map (docEntryExpr defaultTryNows namedExamples) docs)) ]


docEntryExpr : Dict String String -> Dict String (List Example) -> ( String, StandardDoc ) -> Elm.Expression
docEntryExpr defaultTryNows namedExamples ( key, doc ) =
    Gen.DocHelpers.make_.entry
        { name = Elm.string key
        , docs =
            Gen.DocHelpers.standardDocs
                (Gen.DocHelpers.make_.standardDoc
                    { title = Elm.string doc.title
                    , blurb = Elm.string doc.blurb
                    , parameters =
                        Elm.list
                            (List.map
                                (\p ->
                                    Gen.DocHelpers.make_.parameter
                                        { name = Elm.string p.name, type_ = Elm.string p.type_, description = Elm.string p.description }
                                )
                                doc.parameters
                            )
                    , return = Elm.string doc.return
                    }
                )
        , defaultTryNow = Dict.get key defaultTryNows |> Maybe.withDefault "" |> Elm.string
        , tryNowOptions = Dict.get key namedExamples |> Maybe.withDefault [] |> List.map exampleExpr |> Elm.list
        }


exampleExpr : Example -> Elm.Expression
exampleExpr example =
    Gen.DocHelpers.make_.example
        { name = Elm.string example.name
        , code = Elm.string example.code
        }


writeDocFile : Elm.File -> BackendTask FatalError ()
writeDocFile file =
    Script.writeFile { path = "generated/" ++ file.path, body = file.contents } |> BackendTask.allowFatal


parameterDecoder : Decoder Parameter
parameterDecoder =
    JD.succeed Parameter
        |> JDPipe.required "name" JD.string
        |> JDPipe.required "type" JD.string
        |> JDPipe.required "description" JD.string
