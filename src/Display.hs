module Display
  ( printActiveTasks
  , printTaskDone
  , printStatus
  , printHelp
  , printSuccess
  , printWarning
  , printInfo
  ) where

import Task

import qualified Data.Text as T
import System.Console.ANSI

-- ---------------------------------------------------------------------------
-- Low-level color helpers
-- ---------------------------------------------------------------------------

withYellow, withGreen, withRed, withCyan :: IO () -> IO ()
withYellow action = setSGR [SetColor Foreground Dull Yellow]  >> action >> setSGR [Reset]
withGreen  action = setSGR [SetColor Foreground Dull Green]   >> action >> setSGR [Reset]
withRed    action = setSGR [SetColor Foreground Dull Red]     >> action >> setSGR [Reset]
withCyan   action = setSGR [SetColor Foreground Dull Cyan]    >> action >> setSGR [Reset]

bold :: IO () -> IO ()
bold action = setSGR [SetConsoleIntensity BoldIntensity] >> action >> setSGR [Reset]

-- ---------------------------------------------------------------------------
-- Public display functions
-- ---------------------------------------------------------------------------

printSuccess :: String -> IO ()
printSuccess msg = withGreen $ putStrLn $ "  " <> msg

printWarning :: String -> IO ()
printWarning msg = withRed $ putStrLn $ "  " <> msg

printInfo :: String -> IO ()
printInfo msg = withCyan $ putStrLn $ "  " <> msg

-- | Render the numbered list of active tasks.
printActiveTasks :: [Task] -> IO ()
printActiveTasks [] = printInfo "No active tasks. Add up to 3 tasks to get started."
printActiveTasks tasks = do
  putStrLn ""
  bold $ putStrLn "  Active Tasks"
  putStrLn $ "  " <> replicate 28 '-'
  mapM_ printActiveTask (zip [1 ..] tasks)
  putStrLn ""
  let slots = maxActive - length tasks
  if slots > 0
    then withCyan $ putStrLn $ "  " <> show slots <> " slot(s) remaining."
    else withRed  $ putStrLn   "  You're full. Finish a task before adding another."

-- | Render a single active task row.
printActiveTask :: (Int, Task) -> IO ()
printActiveTask (i, t) = do
  withYellow $ putStr $ "  " <> show i <> ". "
  putStr $ T.unpack (description t)
  if null (tags t)
    then pure ()
    else withCyan $ putStr $ "  [" <> T.unpack (T.intercalate ", " (tags t)) <> "]"
  putStrLn ""

-- | Confirm a task was completed, showing elapsed time.
printTaskDone :: Task -> Int -> IO ()
printTaskDone t secs = do
  withGreen $ putStr "  Done: "
  putStr $ T.unpack (description t)
  withCyan $ putStrLn $ "  (" <> formatElapsed secs <> ")"

-- | One-line summary of today's progress.
printStatus :: [Task] -> IO ()
printStatus tasks = do
  let active    = length (activeTasks tasks)
      completed = length tasks - active
  putStrLn ""
  bold $ putStr "  Status: "
  withGreen $ putStr $ show completed <> " done"
  putStr ", "
  withYellow $ putStr $ show active <> " active"
  case (active, completed) of
    (0, 0) -> withCyan  $ putStrLn ". Add your first task!"
    (0, _) -> withGreen $ putStrLn " — All done! Run 'task reset' to start fresh."
    _      -> putStrLn  $ " (" <> show (maxActive - active) <> " slot(s) free)"
  putStrLn ""

printHelp :: IO ()
printHelp = do
  putStrLn ""
  bold $ putStrLn "  Tasker — focus on 3 tasks a day"
  putStrLn ""
  withCyan $ putStrLn "  Commands:"
  putStrLn "    task <description>                   Add a new task"
  putStrLn "    task \"<description> #tag\"            Add a task with one or more tags"
  putStrLn "    task list                            Show active tasks"
  putStrLn "    task <n> done                        Mark task number n as done"
  putStrLn "    task status                          Show today's progress"
  putStrLn "    task reset                           Archive completed tasks, start fresh"
  putStrLn "    task help                            Show this message"
  putStrLn ""
  withCyan $ putStrLn "  Examples:"
  putStrLn "    task write the blog post"
  putStrLn "    task \"work on the newsletter #content #writing\""
  putStrLn "    task list"
  putStrLn "    task 2 done"
  putStrLn ""
  withCyan $ putStrLn "  Note:"
  putStrLn "    Descriptions with #tags must be quoted to prevent the shell"
  putStrLn "    treating # as a comment character."
  putStrLn ""

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- | Format a duration in seconds as a human-readable string.
formatElapsed :: Int -> String
formatElapsed secs
  | secs < 60   = show secs <> "s"
  | secs < 3600 = show (secs `div` 60) <> "m " <> show (secs `mod` 60) <> "s"
  | otherwise   =
      show (secs `div` 3600) <> "h "
      <> show ((secs `mod` 3600) `div` 60) <> "m"
