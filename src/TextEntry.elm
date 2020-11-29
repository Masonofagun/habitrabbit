module TextEntry exposing (Model, Msg, view, init, update)

import Util
--import Html exposing (Html, Attribute, div, input, text)
--import Html.Attributes exposing (..)
--import Html.Events exposing (onInput)
--import Element exposing (Element, el, text, row, alignRight, fill, width, rgb255, spacing, centerY, padding)
import Element exposing (Element)
import Element.Input as Input

type Msg
  = UpdateContent String
  | UpdateTitle String

type alias Model =
  { title: String
  , content: String
  --, placeHolder: String
  , fontProps: Util.FontProps
  }

update : Msg -> Model -> Model
update msg model =
  case msg of
    UpdateContent newContent ->
      { model | content = newContent }
    UpdateTitle newTitle ->
      { model | title = newTitle }

init : Util.FontProps -> Model
init fontProps =
  { title =  ""
  , content =  ""
  , fontProps =  fontProps
  }

-- VIEW


view : Model -> Element Msg
view model =
  Element.column []
      [ Element.row []
        [ Input.text []
          { onChange = UpdateTitle
          , text = model.title
          , placeholder = Just (Input.placeholder [] (Element.text "Title..."))
          , label = Input.labelHidden  "update title"
          }
        ]
      , Element.row []
        [ Input.text []
          { onChange = UpdateContent
          , text = model.content
          , placeholder = Just (Input.placeholder [] (Element.text "Content..."))
          , label = Input.labelHidden  "update content"
          }
        ]
      ]

  --div []
  --    [
  --  --[ div [] [ input [ placeholder model.placeholder, value model.content, onInput Change ] [] ]
  --  --, 
  --  ]
