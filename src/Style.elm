module Style exposing (..)

import Element exposing (Color)


margin : number
margin =
    8


eachZero : { left : number, right : number, top : number, bottom : number }
eachZero =
    { left = 0, right = 0, top = 0, bottom = 0 }


eachMargin : { left : number, right : number, top : number, bottom : number }
eachMargin =
    { left = margin, right = margin, top = margin, bottom = margin }



-- Colors


white : Color
white =
    Element.rgb 1 1 1


background : Color
background =
    Element.rgb255 0xFA 0xFA 0xFA


warningBackground : Color
warningBackground =
    Element.rgba255 0xFF 0xCC 0x00 0.25


errorBackground : Color
errorBackground =
    Element.rgba255 0xCE 0x13 0x00 (0x14 / 0xFF)


cardShadow : Color
cardShadow =
    Element.rgba255 0x02 0x1F 0x3A 0.1


silverLight : Color
silverLight =
    Element.rgb255 0xEE 0xEE 0xEE


extendedMist : Color
extendedMist =
    Element.rgb255 0xCD 0xCD 0xCD


extendedSalt : Color
extendedSalt =
    Element.rgb255 0xFA 0xFA 0xFB


extendedCoal : Color
extendedCoal =
    Element.rgb255 0x33 0x33 0x33


blueDefault : Color
blueDefault =
    Element.rgb255 0x14 0x53 0xB8


primaryBrandDarkBlueSapphire : Color
primaryBrandDarkBlueSapphire =
    Element.rgb255 0x00 0x4C 0x93


secondaryHeaderGhost : Color
secondaryHeaderGhost =
    Element.rgb255 0xF2 0xF6 0xF9
