module Components.Card exposing (view)

import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Style exposing (eachZero)


view : String -> Element msg -> Element msg
view title body =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.shrink
        , Element.Border.rounded 16
        , Element.Background.color Style.white
        , Element.Border.shadow { offset = ( 0, 4 ), size = 0, blur = 20, color = Style.cardShadow }
        ]
        [ viewHeader title
        , body
        ]


viewHeader : String -> Element msg
viewHeader title =
    Element.el
        [ Element.Border.widthEach { eachZero | bottom = 1 }
        , Element.Border.color Style.extendedMist
        , Element.paddingEach { eachZero | left = 16 }
        , Element.height (Element.px 40)
        , Element.width Element.fill
        , Element.Font.size 18
        ]
        (Element.el [ Element.centerY ]
            (Element.text title)
        )
