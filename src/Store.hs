module Store
  ( loadTasks
  , saveTasks
  , taskerFile
  ) where

import Task

import qualified Data.ByteString.Lazy as BL
import Data.Csv
import Data.Vector (toList)
import System.Directory
import System.FilePath

-- ---------------------------------------------------------------------------
-- File paths
-- ---------------------------------------------------------------------------

taskerDir :: IO FilePath
taskerDir = (</> ".tasker") <$> getHomeDirectory

taskerFile :: IO FilePath
taskerFile = (</> "tasks.csv") <$> taskerDir

-- ---------------------------------------------------------------------------
-- Load / save
-- ---------------------------------------------------------------------------

-- | Load all tasks from ~/.tasker/tasks.csv.
-- Returns Right [] if the file does not exist yet.
-- Returns Left err if the file exists but cannot be parsed — callers must
-- treat this as fatal and refuse to overwrite the file.
loadTasks :: IO (Either String [Task])
loadTasks = do
  fp     <- taskerFile
  exists <- doesFileExist fp
  if not exists
    then pure (Right [])
    else do
      bs <- BL.readFile fp
      if BL.null bs
        then pure (Right [])
        else case decodeByName bs of
          Left err     -> pure (Left err)
          Right (_, v) -> pure (Right (toList v))

-- | Persist the full task list to ~/.tasker/tasks.csv.
-- Creates the directory if it does not exist.
saveTasks :: [Task] -> IO ()
saveTasks tasks = do
  dir <- taskerDir
  createDirectoryIfMissing True dir
  fp  <- taskerFile
  BL.writeFile fp (encodeDefaultOrderedByName tasks)
