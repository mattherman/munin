# Munin

Munin is a note-taking library and knowledge base written in Lua. It is named after one of [Odin's ravens](https://en.wikipedia.org/wiki/Huginn_and_Muninn) in Norse mythology and means "memory" in Old Norse.

## Development

In order to use the `repl` or `munin-cli` scripts the library will need to be added to your `LUA_PATH`:
```
LUA_PATH=/path/to/repo/lib/munin/?.lua;;
```

The `;;` at the end ensures the default path is appended after these entries when Lua is loaded.

Running `./repl` will open a Lua REPL with the library loaded into the table `munin`.

## Plans

Notes will be added to a SQLite database. They will support various tagging and categorizing functionality. The full-text search capabilities of SQLite will allow users to search through notes easily.

A CLI will allow users to interact with the library via the command line instead of programatically.

A [Neovim](https://neovim.io) plugin will allow users to interact with their notes in a more user-friendly interface.

The ability to export the notes as a static site may also be added, allowing users to host their notes on the web. Alternatively, this could be an interactive web interface, either read-only with the ability to search an follow links or a fully editable experience.

## Design

### API

The primary data structure will be a *Note*.

Example:
```
{
    title = "Lua Syntax Cheatsheet",
    tags = { "programming", "lua" }
    category = "programming/reference/lua"
    links = { "Lua - Maps" }
    content = "..."
}
```

The Lua API will support operations for updating the index of notes as well as searching for notes by title, text, tags, or category.

```
function find_workspace_root() -> string

function parse_note(raw_content: string) -> Note
function index_note(note: Note) -> (IndexResult, Error)
function remove_note(title: string) -> (IndexResult, Error)
function sync_workspace(workspace_path: string) -> (IndexResult, Error)

function get_note(title: string) -> (Note, Error)
function get_note_links(title: string) -> ({ string }, Error)

function get_notes() -> ({ Note }, Error)
function get_notes_by_tags(tags: { string }) -> ({ Note }, Error)
function get_notes_by_category(category: string) -> { Note }, Error)
function search_notes(search_term: string) -> (SearchResult, Error)
```

*Data Structures*

```
Note = {
    title = "string",
    tags = { "string" },
    category = "string"
    links = { "string" },
    content = "string"
}

IndexResult = "string" ("index_updated" | "no_change")

Error = "string"

SearchResult = {
    total_count = 0,
    matches = {
        title = "string",
        field = "string" ("title" | "tag" | "content"),
        context = "string"
    }
}
```

*Database Schema*

```
CREATE TABLE notes (
    id integer PRIMARY KEY,
    title text NOT NULL,
    category text NOT NULL,
    content text NOT NULL
);

CREATE TABLE tags (
    tag text PRIMARY KEY
);

CREATE TABLE note_tags (
    tag text NOT NULL,
    note_id integer NOT NULL,
    FOREIGN KEY (tag) REFERENCES tags (tag),
    FOREIGN KEY (note_id) REFERENCES notes (id)
);
```
### CLI

The following commands will be supported by the CLI:
```
munin sync
munin index-file <file>
munin move-file <file> <new_file>
munin search <search_term> [--tags <tag,>]
munin edit <file>
```
