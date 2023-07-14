local lfs = require("lfs")

local repo_path = lfs.currentdir()

local repo = require("munin.repo").init(repo_path)

if arg[1] == "init" then
    local init_err = repo.create_new()
    if init_err then
        print("[Error] Failed to initialize repository at "..repo._path..": "..init_err)
    else
        print("Initialized new repository at "..repo._path)
    end
elseif arg[1] == "sync" then
    local index_err = require("munin.indexer").index(repo)
    if index_err then
        print("[Error] Failed to index repository at "..repo._path..": "..index_err)
    end
elseif arg[1] == "get-note" then
    local path = arg[2]
    local note, err = repo.get_note(path)
    if note then
        print(note.title)
        print(note.content)
    elseif err then
        print("[Error] "..err)
    else
        print("Note titled '"..path.."' not found")
    end
elseif arg[1] == "get-notes" then
    local notes, err = repo.get_notes()
    if err then
        print("[Error] "..err)
    elseif notes then
        for _, note in ipairs(notes) do
            print(note.path)
        end
    end
elseif arg[1] == "save-note" then
    local title = arg[2]
    local category = arg[3]
    local content = io.read("*a")
    local _, err = repo.save_note(title, content, category)
    if err then
        print("[Error] "..err)
    end
elseif arg[1] == "search" then
    local search = arg[2]
    local notes, err = repo.search_notes(search)
    if err then
        print("[Error] "..err)
    elseif notes then
        for _, note in ipairs(notes) do
            print(note.path, note.snippet)
        end
    end
else
    print([[
Munin

init                                        Create a new repository in the current directory
sync                                        Indexes all markdown files in the current directory and saves them as notes
save-note <title> <category> <content>      Reads note content from stdin and saves as title
get-note <path>                             Retrieves and displays the note with title
get-notes                                   Retrieves all notes
search <search_term>                        Searches note titles and content for the search term (uses SQLite FTS5 query syntax)
    ]])
end
