module DocHelpers exposing (..)

import Components.Card
import Element exposing (Element, fill, height, width)
import Element.Background
import Element.Font
import Element.Region
import Style exposing (eachZero)


type alias Entry msg =
    { name : String
    , docs : Element msg
    , defaultTryNow : String
    , tryNowOptions : List { name : String, code : String }
    }


type alias StandardDoc =
    { title : String
    , blurb : String
    , parameters : List { name : String, type_ : String, description : String }
    , return : String
    }


standardDocs : StandardDoc -> Element msg
standardDocs doc =
    Components.Card.view doc.title
        (Element.column
            [ width fill
            , height fill
            , Element.spacing Style.margin
            , Element.padding (Style.margin * 3)
            ]
            [ Element.text doc.blurb
            , viewParameters doc
            , h2 "Return"
            , Element.text doc.return
            ]
        )


viewParameters : StandardDoc -> Element msg
viewParameters doc =
    case doc.parameters of
        [] ->
            Element.none

        _ ->
            Element.column [ width fill, Element.spacing Style.margin ]
                [ h2 "Parameters"
                , Element.indexedTable [ width fill ]
                    { data = doc.parameters
                    , columns =
                        [ { header = viewTableHeader "Name", width = Element.shrink, view = viewTableCell .name }
                        , { header = viewTableHeader "Type", width = Element.shrink, view = viewTableCell .type_ }
                        , { header = viewTableHeader "Description", width = fill, view = viewTableCell .description }
                        ]
                    }
                ]


viewTableHeader : String -> Element msg
viewTableHeader header =
    Element.el
        [ Element.Background.color Style.secondaryHeaderGhost
        , height (Element.px 40)
        , width fill
        , Element.Font.color Style.primaryBrandDarkBlueSapphire
        , Element.paddingEach { eachZero | left = 16, right = 16 }
        ]
        (Element.el [ Element.centerY ] (Element.text header))


viewTableCell : (a -> String) -> Int -> a -> Element msg
viewTableCell toText index item =
    Element.el
        [ width fill
        , height (Element.shrink |> Element.minimum 40)
        , Element.padding Style.margin
        , Element.Background.color
            (if modBy 2 index == 0 then
                Style.white

             else
                Style.extendedSalt
            )
        ]
        (Element.paragraph
            [ Element.centerY
            ]
            [ Element.text (toText item) ]
        )


h1 : String -> Element msg
h1 =
    Element.el [ Element.Region.heading 1, Element.Font.size 32 ] << Element.text


h2 : String -> Element msg
h2 =
    Element.el [ Element.Region.heading 2, Element.Font.size 16 ] << Element.text


standardQueryReturn : String
standardQueryReturn =
    "Returns a promise that will resolve with the results of the query."
