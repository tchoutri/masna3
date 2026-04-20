module Main where

import Arbiter.Migrations qualified as Mig
import Data.Proxy (Proxy (..))
import Effectful
import System.Exit (die)

import BackgroundJobs.Environment
import BackgroundJobs.Registry

main :: IO ()
main = do
  env <- runEff getBackgroundJobsEnv
  result <- Mig.runMigrationsForRegistry (Proxy @AppRegistry) env.connectionString "public" Mig.defaultMigrationConfig
  case result of
    Mig.MigrationSuccess -> putStrLn "Migrations complete"
    Mig.MigrationError err -> die $ "Migration failed: " <> err
