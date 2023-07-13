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
elseif (arg[1] == "get-note") then
    print("Is this working?")
    local title = arg[2]
    local note, err = repo.get_notes_by_title(title)
    if note then
        print(note.title)
        print(note.content)
    elseif err then
        print("[Error] "..err)
    else
        print("Note titled '"..title.."' not found")
    end
elseif (arg[1] == "add-note") then
    local title = arg[2]
    local category = arg[3]
    local content = io.read("*a")
    local _, err = repo.add_note(title, content, category)
    if err then
        print("[Error] "..err)
    end
else
    print([[
Munin

init                Create a new repository in the current directory
add-note <title>    Reads note content from stdin and saves as title
get-note <title>    Retrieves and displays the note with title
    ]])
end
