import gleam/list

import gleeunit/should

import domain/file/register_file.{
  UserChangedMimeType, UserChangedOwnerId, UserChangedProcessId,
  UserSubmittedForm, init, update,
}

// Validate Client Input 

pub fn empty_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(2)
}

pub fn missing_owner_uuid_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserChangedMimeType("text/plain"))
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(1)
}

pub fn invalid_owner_uuid_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserChangedMimeType("text/plain"))
  let #(new_model, _) =
    update(new_model, UserChangedOwnerId("invalid_owner_id"))
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(1)
}

pub fn invalid_process_uuid_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserChangedMimeType("text/plain"))
  let #(new_model, _) =
    update(
      new_model,
      UserChangedOwnerId("019c3064-4ee1-761e-abe5-b4fe90adbd98"),
    )
  let #(new_model, _) =
    update(new_model, UserChangedProcessId("invalid_process_id"))
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(1)
}

pub fn missing_mime_type_submit_test() {
  let model = init()
  let #(new_model, _) =
    update(model, UserChangedOwnerId("019c3064-4ee1-761e-abe5-b4fe90adbd98"))
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(1)
}

pub fn valid_submit_test() {
  let model = init()
  let #(new_model, _) = update(model, UserChangedMimeType("text/plain"))
  let #(new_model, _) =
    update(
      new_model,
      UserChangedOwnerId("019c3064-4ee1-761e-abe5-b4fe90adbd98"),
    )
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(0)
}

pub fn valid_submit_with_process_id_test() {
  let model = init()
  let #(new_model, _) = update(model, UserChangedMimeType("text/plain"))
  let #(new_model, _) =
    update(
      new_model,
      UserChangedOwnerId("019c3064-4ee1-761e-abe5-b4fe90adbd98"),
    )
  let #(new_model, _) =
    update(
      new_model,
      UserChangedProcessId("019c3064-4ee1-761e-abe5-b4fe90adbd98"),
    )
  let #(new_model, _) = update(new_model, UserSubmittedForm)

  list.length(new_model.validation_errors)
  |> should.equal(0)
}
