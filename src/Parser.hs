module Parser
  ( Command (..)
  , parseCommand
  , extractTags
  , stripTags
  ) where

import Data.Char (isDigit)
import Data.Text (Text)
import qualified Data.Text as T

-- | All possible actions the user can take from the CLI.
data Command
  = AddTask Text [Text]  -- ^ description (tags stripped), list of tags
  | ListTasks
  | CompleteTask Int      -- ^ 1-indexed position in the active list
  | ShowStatus
  | ResetTasks
  | ShowHelp

-- | Parse raw CLI arguments into a Command.
--
-- Supported forms:
--   []                      -> ShowHelp
--   ["help"]                -> ShowHelp
--   ("list":_)              -> ListTasks
--   ["status"]              -> ShowStatus
--   ["reset"]               -> ResetTasks
--   [n, "done"]             -> CompleteTask n   (n is a positive integer)
--   (n:"done":_)            -> CompleteTask n
--   (words...)              -> AddTask description tags
parseCommand :: [String] -> Command
parseCommand []            = ShowHelp
parseCommand ["help"]      = ShowHelp
parseCommand ("list":_)    = ListTasks
parseCommand ["status"]    = ShowStatus
parseCommand ["reset"]     = ResetTasks
parseCommand [n, "done"]
  | isPositiveInt n        = CompleteTask (read n)
parseCommand (n:"done":_)
  | isPositiveInt n        = CompleteTask (read n)
parseCommand ws            =
  let raw  = T.unwords (map T.pack ws)
      tgs  = extractTags raw
      desc = stripTags raw
  in AddTask desc tgs

-- | A string is a positive integer if it is non-empty and all digits.
isPositiveInt :: String -> Bool
isPositiveInt s = not (null s) && all isDigit s

-- | Extract tags: words that start with '#', returned without the '#' prefix.
--
-- >>> extractTags "write the blog post #content #writing"
-- ["content","writing"]
extractTags :: Text -> [Text]
extractTags = map (T.drop 1) . filter (T.isPrefixOf "#") . T.words

-- | Remove all #tag words from a piece of text, collapsing extra spaces.
--
-- >>> stripTags "write the blog post #content #writing"
-- "write the blog post"
stripTags :: Text -> Text
stripTags = T.unwords . filter (not . T.isPrefixOf "#") . T.words
