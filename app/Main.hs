module Main where

import Task
import Parser
import Store
import Display

import qualified Data.Text as T
import Data.Time (getCurrentTime, diffUTCTime)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, stderr, utf8)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  let cmd = parseCommand args
  case cmd of
    -- Help never needs the CSV.
    ShowHelp -> printHelp
    -- Everything else loads the CSV first and fails closed on parse errors.
    _ -> do
      result <- loadTasks
      case result of
        Left err -> do
          printWarning "Could not read your tasks file — it may be corrupted."
          printWarning $ "Parse error: " <> err
          printWarning "Fix or back up ~/.tasker/tasks.csv before running any task commands."
          exitFailure
        Right tasks -> dispatch cmd tasks

-- | Dispatch a command once we have a known-good task list.
dispatch :: Command -> [Task] -> IO ()
dispatch cmd tasks = case cmd of
  AddTask desc tgs -> handleAdd      tasks desc tgs
  ListTasks        -> handleList     tasks
  CompleteTask pos -> handleComplete tasks pos
  ShowStatus       -> handleStatus   tasks
  ResetTasks       -> handleReset    tasks
  ShowHelp         -> printHelp  -- unreachable here, but keeps the match total

-- ---------------------------------------------------------------------------
-- Command handlers
-- ---------------------------------------------------------------------------

handleAdd :: [Task] -> T.Text -> [T.Text] -> IO ()
handleAdd tasks desc tgs
  | T.null (T.strip desc) =
      printWarning "Task description cannot be empty."
  | length (activeTasks tasks) >= maxActive =
      printWarning "You're full. You already have 3 active tasks. Finish one before adding another."
  | otherwise = do
      now <- getCurrentTime
      let newTask = Task
            { taskId         = nextId tasks
            , description    = T.strip desc
            , status         = Active
            , createdAt      = now
            , completedAt    = Nothing
            , elapsedSeconds = Nothing
            , tags           = tgs
            }
          updatedTasks = tasks <> [newTask]
      saveTasks updatedTasks
      printSuccess $ "Added: " <> T.unpack desc
      let remaining = maxActive - length (activeTasks updatedTasks)
      if remaining == 0
        then printWarning "You're now full. Focus and get them done!"
        else printInfo $ show remaining <> " slot(s) remaining."

handleList :: [Task] -> IO ()
handleList = printActiveTasks . activeTasks

handleComplete :: [Task] -> Int -> IO ()
handleComplete tasks pos = do
  let active = activeTasks tasks
  if pos < 1 || pos > length active
    then printWarning $
      "No task at position " <> show pos <> ". "
      <> "You have " <> show (length active) <> " active task(s)."
    else do
      now <- getCurrentTime
      let task        = active !! (pos - 1)
          elapsed     = diffUTCTime now (createdAt task)
          elapsedSecs = round elapsed :: Int
          updated     = task
            { status         = Completed
            , completedAt    = Just now
            , elapsedSeconds = Just elapsedSecs
            }
          newTasks    = map (\t -> if taskId t == taskId updated then updated else t) tasks
      saveTasks newTasks
      printTaskDone updated elapsedSecs

handleStatus :: [Task] -> IO ()
handleStatus = printStatus

handleReset :: [Task] -> IO ()
handleReset tasks = do
  let active    = activeTasks tasks
      completed = filter (\t -> status t == Completed) tasks
  if null tasks
    then printInfo "Nothing to reset. No tasks found."
    else do
      putStr "\n  This will discard active tasks and start fresh. Continue? [y/N] "
      answer <- getLine
      if answer `elem` ["y", "Y", "yes"]
        then do
          saveTasks completed
          printSuccess "Reset complete. Ready for a fresh start."
          if null active
            then printInfo "No active tasks were discarded."
            else printInfo $ show (length active) <> " active task(s) discarded."
          printInfo $ show (length completed) <> " completed task(s) kept in history."
        else printInfo "Reset cancelled."
