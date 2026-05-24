# Tasker

A focused, minimal CLI task manager built in Haskell.

The idea is simple: start each day by picking **three tasks** you know you can finish, then finish them. No more than three active tasks at any time — no endless lists, no noise.

---

## Features

- Hard limit of 3 active tasks — forces prioritization
- Tag support via `#word` syntax
- Elapsed time tracking when a task is completed
- Color-coded terminal output (yellow, green, red, cyan)
- Persistent storage in `~/.tasker/tasks.csv` — never inside the repo
- Safe-by-default: refuses to overwrite a corrupted data file

---

## Requirements

- [GHC](https://www.haskell.org/ghc/) (tested with GHC 9.10)
- [Cabal](https://www.haskell.org/cabal/) 3.0+

Install both via [GHCup](https://www.haskell.org/ghcup/):

```sh
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

---

## Build

```sh
git clone https://github.com/prasannakumarr/tasker.git
cd tasker
cabal build
```

To install the `task` binary to your Cabal bin path:

```sh
cabal install
```

Make sure `~/.cabal/bin` is on your `PATH`:

```sh
export PATH="$HOME/.cabal/bin:$PATH"
```

---

## Usage

```
task <description>                   Add a new task
task "<description> #tag"            Add a task with one or more tags
task list                            Show active tasks
task <n> done                        Mark task number n as done
task status                          Show today's progress
task reset                           Archive completed tasks, start fresh
task help                            Show this message
```

---

## Examples

```sh
# Add tasks
task write the blog post
task "review PR for the API changes #dev"
task "send the weekly update #writing"

# List active tasks
task list

# Mark the second task done
task 2 done

# Check progress
task status

# Start fresh (keeps completed task history)
task reset
```

**Note:** Descriptions containing `#tags` must be quoted to prevent the shell from treating `#` as a comment character.

---

## Data storage

Tasks are stored in `~/.tasker/tasks.csv` — outside the repo and never committed. Both active and completed tasks are kept in the same file as a permanent history.

The directory is created automatically on first use.

---

## Project structure

```
tasker/
├── app/
│   └── Main.hs        Entry point — arg parsing and IO dispatch
├── src/
│   ├── Task.hs        Task domain type, business rules, CSV instances
│   ├── Parser.hs      Pure command parser ([String] → Command)
│   ├── Store.hs       Load/save ~/.tasker/tasks.csv
│   └── Display.hs     Colored terminal output
├── tasker.cabal
└── claude.txt         Full spec and design document
```

---

## License

MIT
