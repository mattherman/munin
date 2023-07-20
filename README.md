# Munin

Munin is a note-taking library and knowledge base written in Lua. It is named after one of [Odin's ravens](https://en.wikipedia.org/wiki/Huginn_and_Muninn) in Norse mythology and means "memory" in Old Norse.

## Development

Development of Munin requires Lua 5.1 and depends on `luafilesystem` and `lsqlite3` which can be installed via LuaRocks.
Running `./repl` will open a Lua REPL with the library loaded into the table `munin`.

To install `luafilesystem` you can just run `luarocks install --local luafilesystem`. If you have multiple versions of Lua installed you will need to also provide `--lua-version 5.1` to the commmand (this requires LuaRocks 3.x).

Installing `lsqlite3` is a little more complex. In order to use the module you need to have a valid install of SQLite on your system. On Linux this includes the `sqlite3` andcd `libsqlite3-dev` packages. The `-dev` package provides the `sqlite3.h` file that will need to be found in the `SQLITE_DIR` variable provided to the install command:

```
luarocks install --local lsqlite3 SQLITE_DIR=/usr
```

On my system it was installed in `/usr/include`, but it may be installed in `/usr/local/include` or somewhere else entirely. Again, you can provide `--lua-version 5.1` if you have multiple Lua versions installed.

Once it is installed you need to update your `LUA_CPATH` to reference the location of `lsqlite3.so`. You can find that location by running `luarocks show lsqlite3`. In my case it is `/home/matt/.luarocks/lib/lua/5.1/lqlite3.so` so I would add `/home/matt/.luarocks/lib/lua/5.1/?.so;;` to my `LUA_CPATH` variable. The `;;` suffix ensures that the default path will be appended along with the added value when Lua starts (but I'm not sure why this works).

## API

The primary data structure is a *Note*.

Example:
```
{
    title = "Lua Syntax Cheatsheet",
    tags = { "programming", "lua" }
    category = "programming/reference/lua"
    links = { "programming/reference/lua/maps" }
    content = "..."
}
```

The `munin.repo` module supports operations for updating the index of notes as well as searching for notes by title, text, tags, or category. To use these functions you must first initialize your repository, ex. `repo = require("munin.repo").init("/path/to/repo")`.

```
function create_new() -> Error

function save_note(title: string, text: string, category: string) -> (Note, Error)

function get_note(path: string) -> (Note, Error)

function get_notes() -> ({ Note }, Error)
function get_notes_by_title(title: stirng) -> ({ Note }, Error)
function get_notes_by_tag(tag: string) -> ({ Note }, Error)
function get_notes_by_category(category: string) -> ({ Note }, Error)
function search_notes(search_term: string) -> ({ SearchNote }, Error)
```

The `munin.indexer` module allows you to index all of the files in a directory into a repository. It requires a `repo` object initialized using `munin.repo`.

```
function index(repo: Repo) -> Error
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

Error = "string"

SearchNote = {
    title = "string",
    tags = { "string" },
    category = "string"
    links = { "string" },
    content = "string"
    snippet = "string"
}
```

*Database Schema*

```
CREATE TABLE notes (
    path text PRIMARY KEY,
    title text NOT NULL,
    category text NULL
);

CREATE VIRTUAL TABLE notes_search USING FTS5(
    path UNINDEXED,
    title,
    content
);

CREATE TABLE note_tags (
    tag text NOT NULL,
    note_path text NOT NULL,
    FOREIGN KEY (note_path) REFERENCES notes (path)
);
```

## CLI

The following commands are supported by the CLI:
```
init                                        Create a new repository in the current directory
sync                                        Indexes all markdown files in the current directory and saves them as notes
save-note <title> <category> <content>      Reads note content from stdin and saves as title
get-note <path>                             Retrieves and displays the note with title
get-notes                                   Retrieves all notes
search <search_term>                        Searches note titles and content for the search term (uses SQLite FTS5 query syntax)
```
