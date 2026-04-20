import gleam/uri.{type Uri}

import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem

import domain/file/confirm_file
import domain/file/delete_file
import domain/file/register_file
import domain/process/cancel_process
import domain/process/complete_process
import domain/process/register_process
import types/model.{type Model, Model}
import types/msg.{type Msg, UserNavigatedTo}
import types/route.{type Route}

import components/navbar
import views/file/confirm_file as confirm_file_view
import views/file/delete_file as delete_file_view
import views/file/register_file as register_file_view
import views/index
import views/not_found
import views/process/cancel_process as cancel_process_view
import views/process/complete_process as complete_process_view
import views/process/register_process as register_process_view

fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> route.Index
    ["file", ..action] ->
      case action {
        ["register"] -> route.RegisterFile
        ["confirm"] -> route.ConfirmFile
        ["delete"] -> route.DeleteFile
        _ -> route.NotFound(uri:)
      }
    ["process", ..action] ->
      case action {
        ["register"] -> route.RegisterProcess
        ["complete"] -> route.CompleteProcess
        ["cancel"] -> route.CancelProcess
        _ -> route.NotFound(uri:)
      }
    _ -> route.NotFound(uri:)
  }
}

pub fn init(_) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> route.Index
  }

  let model =
    Model(
      route:,
      register_file: register_file.init(),
      confirm_file: confirm_file.init(),
      delete_file: delete_file.init(),
      register_process: register_process.init(),
      complete_process: complete_process.init(),
      cancel_process: cancel_process.init(),
    )

  let effect =
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })

  #(model, effect)
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    navbar.view(),
    html.main([], {
      case model.route {
        route.Index -> index.view()
        route.RegisterFile -> register_file_view.view(model)
        route.ConfirmFile -> confirm_file_view.view(model)
        route.DeleteFile -> delete_file_view.view(model)
        route.RegisterProcess -> register_process_view.view(model)
        route.CompleteProcess -> complete_process_view.view(model)
        route.CancelProcess -> cancel_process_view.view(model)
        route.NotFound(_) -> not_found.view()
      }
    }),
  ])
}
