module Masna3.Test.StructuredOutput where

import Data.Aeson
import Data.Text qualified as Text
import Data.Vector qualified as Vector
import Effectful
import Effectful.FileSystem
import Effectful.FileSystem.IO.ByteString.Lazy qualified as FileSystem
import Effectful.State.Static.Shared (State)
import Effectful.State.Static.Shared qualified as State
import GHC.Generics
import Lucid
import System.FilePath

data OutputTable = OutputTable
  { tableName :: Text
  , header :: Vector Text
  , rows :: Vector (Vector Text)
  }
  deriving stock (Eq, Generic, Ord, Show)
  deriving anyclass (FromJSON, ToJSON)

writeTable :: FileSystem :> es => FilePath -> OutputTable -> Eff es ()
writeTable destinationDirectory table = do
  let html = renderBS $ toHTML table
  let fileName = Text.unpack table.tableName
  FileSystem.writeFile (destinationDirectory </> fileName <.> ".html") html

setHeader :: State OutputTable :> es => Vector Text -> Eff es ()
setHeader newHeader = State.modify $ \table ->
  table{header = newHeader}

addRow :: State OutputTable :> es => Vector Text -> Eff es ()
addRow newRow = State.modify $ \table ->
  table{rows = Vector.snoc table.rows newRow}

toHTML :: OutputTable -> Html ()
toHTML table = do
  html_ [lang_ "en"] $ do
    head_ $ do
      meta_ [charset_ "UTF-8"]
      meta_ [name_ "viewport", content_ "width=device-width, initial-scale=1"]
    body_ [] $ do
      table_ $ do
        caption_ [style_ "white-space: nowrap; and overflow: hidden;"] (toHtml table.tableName)
        thead_ $ do
          tr_ $ do
            forM_ table.header $ \header ->
              th_ (toHtml header)
        tbody_ $ do
          forM_ table.rows $ \row -> do
            tr_ $ do
              let cells = Vector.tail row
              th_ (toHtml $ Vector.head row)
              forM_ cells $ \cell -> do
                td_ (toHtml cell)
