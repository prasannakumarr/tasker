module Task
  ( Task (..)
  , TaskStatus (..)
  , maxActive
  , activeTasks
  , nextId
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Time
import Data.Csv
import Data.Vector ()  -- instances only

-- ---------------------------------------------------------------------------
-- Domain types
-- ---------------------------------------------------------------------------

-- | Whether a task is still being worked on or has been finished.
data TaskStatus = Active | Completed
  deriving (Show, Read, Eq, Ord)

-- | A single task with all its metadata.
data Task = Task
  { taskId         :: Int
  , description    :: Text          -- stored without #tag markers
  , status         :: TaskStatus
  , createdAt      :: UTCTime
  , completedAt    :: Maybe UTCTime
  , elapsedSeconds :: Maybe Int     -- stored as plain seconds in CSV
  , tags           :: [Text]        -- parsed from #words, semicolon-separated in CSV
  } deriving (Show, Eq)

-- ---------------------------------------------------------------------------
-- Business rules
-- ---------------------------------------------------------------------------

-- | The maximum number of tasks allowed to be active at once.
maxActive :: Int
maxActive = 3

-- | Filter down to only the tasks that are currently active.
activeTasks :: [Task] -> [Task]
activeTasks = filter (\t -> status t == Active)

-- | Generate the next available task ID given the current task list.
nextId :: [Task] -> Int
nextId [] = 1
nextId ts = maximum (map taskId ts) + 1

-- ---------------------------------------------------------------------------
-- CSV serialisation (cassava instances live here to avoid orphans)
-- ---------------------------------------------------------------------------

timeFormat :: String
timeFormat = "%Y-%m-%dT%H:%M:%SZ"

formatUtc :: UTCTime -> String
formatUtc = formatTime defaultTimeLocale timeFormat

parseUtc :: String -> Maybe UTCTime
parseUtc = parseTimeM True defaultTimeLocale timeFormat

instance ToField TaskStatus where
  toField Active    = "active"
  toField Completed = "completed"

instance FromField TaskStatus where
  parseField "active"    = pure Active
  parseField "completed" = pure Completed
  parseField other       = fail $ "Unknown status: " <> show other

instance ToNamedRecord Task where
  toNamedRecord t = namedRecord
    [ "id"              .= taskId t
    , "description"     .= description t
    , "status"          .= status t
    , "created_at"      .= formatUtc (createdAt t)
    , "completed_at"    .= maybe ("" :: String) formatUtc (completedAt t)
    , "elapsed_seconds" .= maybe ("" :: String) show (elapsedSeconds t)
    , "tags"            .= T.intercalate ";" (tags t)
    ]

instance FromNamedRecord Task where
  parseNamedRecord r = do
    tid    <- r .: "id"
    desc   <- r .: "description"
    st     <- r .: "status"
    catStr <- r .: "created_at"
    cmpStr <- r .: "completed_at"
    elStr  <- r .: "elapsed_seconds"
    tagStr <- r .: "tags"

    cat <- case parseUtc (T.unpack catStr) of
      Just t  -> pure t
      Nothing -> fail $ "Cannot parse created_at: " <> T.unpack catStr

    cmp <- if T.null cmpStr
      then pure Nothing
      else case parseUtc (T.unpack cmpStr) of
        Just t  -> pure (Just t)
        Nothing -> fail $ "Cannot parse completed_at: " <> T.unpack cmpStr

    el <- if T.null elStr
      then pure Nothing
      else case reads (T.unpack elStr) :: [(Int, String)] of
        [(n, "")] -> pure (Just n)
        _         -> fail $ "Cannot parse elapsed_seconds: " <> T.unpack elStr

    let tgs = if T.null tagStr then [] else T.splitOn ";" tagStr

    pure $ Task tid desc st cat cmp el tgs

instance DefaultOrdered Task where
  headerOrder _ = header
    [ "id", "description", "status"
    , "created_at", "completed_at", "elapsed_seconds"
    , "tags"
    ]
