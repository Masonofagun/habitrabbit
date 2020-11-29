module Main exposing (view)

import Util
import Browser
import TextEntry
import Checkbox
import Html exposing (Html)
import Dict exposing (Dict)
import Element exposing (Element)
import Element.Input as Input

main =
  Browser.sandbox { init = init, update = update, view = view }

init: Model
init =
  Model Dict.empty (Util.FontProps 10 20)
type FormComponent
  = TextEntryModel TextEntry.Model
  | CheckboxModel Checkbox.Model

type alias Model =
  { components: Dict Int FormComponent
  , fontProps: Util.FontProps
  }

type FormComponentMsg
  = TextEntryMsg TextEntry.Msg
  | CheckboxMsg Checkbox.Msg

type Msg
  = AddFormComponent FormComponent
  | RemoveFormComponent Int
  | DispatchMsg (Int, FormComponentMsg)

makeDispatchMsg: Int -> FormComponentMsg -> Msg
makeDispatchMsg ix msg =
  DispatchMsg (ix, msg)

dispatchMsg: Dict Int FormComponent -> Int -> FormComponentMsg -> Dict Int FormComponent
dispatchMsg components k msg =
  let
    updatedComp =
      case Dict.get k components of
        Just comp ->
          case (comp, msg) of -- TODO should this all be done with static configurtation instead of types?
            (TextEntryModel model, TextEntryMsg cmsg) ->
              Just (TextEntryModel (TextEntry.update cmsg model))
            (CheckboxModel model, CheckboxMsg cmsg) ->
              Just (CheckboxModel (Checkbox.update cmsg model))
            _ ->
              Nothing
        Nothing ->
          Nothing
  in
    case updatedComp of
      Just comp ->
        Dict.insert k comp components
      Nothing ->
        components


getNextIndex: Dict Int FormComponent -> Int
getNextIndex items =
  case List.maximum (Dict.keys items) of
    Nothing ->
      0
    Just ix ->
      ix + 1

update : Msg -> Model -> Model
update msg model =
  case msg of
    AddFormComponent itemName ->
      let
        ix = getNextIndex model.components
        components = Dict.insert ix itemName model.components
      in
        { model | components = components }
    RemoveFormComponent ix ->
      let
        components = Dict.remove ix model.components
      in
        { model | components = components }
    DispatchMsg (ix, dmsg) ->
      let
        components = dispatchMsg model.components ix dmsg
      in
        { model | components = components }

dispatchView: (Int, FormComponent) -> Element Msg
dispatchView (ix, formComponent) =
  case formComponent of
    TextEntryModel model ->
      TextEntry.view model |> Element.map TextEntryMsg |> Element.map (makeDispatchMsg ix)
    CheckboxModel model ->
      Checkbox.view model |> Element.map CheckboxMsg |> Element.map (makeDispatchMsg ix)

view: Model -> Html Msg
view model =
  let
    compViews = List.map dispatchView (Dict.toList model.components)
  in
    Element.layout [] (Element.column [] (compViews ++ [viewAddForms model]))

addFormButton: Msg -> String -> Element Msg
addFormButton msg txt =
    let
      props =
        [
        ]
    in
      Input.button
        props
        { onPress = Just msg
        , label = Element.text txt
        }

viewAddForms: Model -> Element Msg
viewAddForms model =
  Element.row []
  [ addFormButton (AddFormComponent (CheckboxModel (Checkbox.init model.fontProps))) "Checkbox" 
  , addFormButton (AddFormComponent (TextEntryModel (TextEntry.init model.fontProps))) "Text Input" 
  ]
