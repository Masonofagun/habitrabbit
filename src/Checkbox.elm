module Checkbox exposing (Model, Msg, view, init, update)

import Util
import Element exposing (Element)
import Element.Input as Input
import Dict exposing (Dict)

type alias Item =
  { name: String
  , checked: Bool
  , index: Int
  }

type alias Model =
  { items: Dict Int Item
  , fontProps: Util.FontProps
  }

init: Util.FontProps -> Model
init fontProps =
  Model Dict.empty fontProps

makeCheckItem: Int -> Bool -> Msg
makeCheckItem ix b =
  CheckItem (ix, b)

type Msg
  = AddItem String
  | RemoveItem Int
  | CheckItem (Int, Bool)

--max: List Int -> Maybe Int
--max l =
--  case l of
--    [] ->
--      Nothing
--    [x] ->
--      Just x
getNextIndex: Dict Int Item -> Int
getNextIndex items =
  case List.maximum (Dict.keys items) of
    Nothing ->
      0
    Just ix ->
      ix + 1

update : Msg -> Model -> Model
update msg model =
  case msg of
    AddItem itemName ->
      let
        ix = getNextIndex model.items
        item = Item itemName False ix
        items = Dict.insert ix item model.items
      in
        { model | items = items }
    RemoveItem ix ->
      let
        items = Dict.remove ix model.items
      in
        { model | items = items }
    CheckItem (ix, isChecked) ->
      let
        items =
          case Dict.get ix model.items of
            Just item ->
              Dict.insert ix {item | checked = isChecked} model.items
            Nothing ->
              model.items
      in
        { model | items = items }

viewCheckbox : (Int, Item) -> Element Msg
viewCheckbox (ix, item) =
  Input.checkbox []
  { onChange = makeCheckItem ix
  , icon = Input.defaultCheckbox
  , checked = item.checked
  , label = Input.labelLeft [] (Element.text item.name)
  }


addItemButton: Element Msg
addItemButton =
      Input.button
        []
        { onPress = Just (AddItem "Default")
        , label = Element.text "Add Item"
        }

view: Model -> Element Msg
view model =
  [addItemButton] ++ (List.map viewCheckbox (Dict.toList model.items))
  |> Element.column []

