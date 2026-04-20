import gleam/list

import gleeunit/should

import domain/process/cancel_process.{
  UserChangedProcessId, UserSubmittedForm, init, update,
}

// Validate Client Input 

pub fn empty_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(1)
}

pub fn valid_submit_test() {
  let model = init()
  let #(new_model, _) =
    update(model, UserChangedProcessId("019c3064-4ee1-761e-abe5-b4fe90adbd98"))
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(0)
}
