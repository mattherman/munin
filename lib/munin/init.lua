local database = require("munin.data")

print(":lib/munin/init.lua")

local M = {}

local function db_path(repo_path)
    return repo_path.."/.munin/notes.db"
end

function M.init(repo_path)
    local error_msg = database.create_database(db_path(repo_path))
    if error_msg then
        return "Failed to initialize new note repository: "..error_msg
    end
end

function M.add_note(repo_path, title, text, category, tags)
    local note = {
        title = title,
        category = category,
        content = text
    }
    local error_msg = database.add_note(db_path(repo_path), note)
    if error_msg then
        return nil, "Failed to add new note: "..error_msg
    else
        return note
    end
end

function M.get_note(repo_path, title)
    return database.get_note(db_path(repo_path), title)
end

return M
