module Documentation exposing (entrys)

import DocHelpers exposing (..)


entrys : List (Entry msg)
entrys =
    [ getDataForCurrentObject
    , queryRecord
    ]


getDataForCurrentObject =
    { name = "getDataForCurrentObject"
    , docs =
        standardDocs
            { title = "getDataForCurrentObject(object, field)"
            , blurb = "Asynchronously fetches a field from the current object."
            , parameters =
                [ { name = "object", type_ = "string", description = "The API name of the object that you wish to query." }
                , Parameter "field" "string" "The API name of the field that you wish to query."
                ]
            , return = standardQueryReturn
            }
    , defaultTryNow = """ds.getDataForCurrentObject("User", "Name").then(console.log, console.warn);
// get the name of the current user"""
    , tryNowOptions =
        [ { name = "Log", code = "console.log('log')" }
        , { name = "Warn", code = "console.warn('warning')" }
        , { name = "Error", code = "console.error('error')" }
        , { name = "All three", code = "console.log('log') \nconsole.warn('warning') \nconsole.error('error')" }
        ]
    }


queryRecord =
    { name = "queryRecord"
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
