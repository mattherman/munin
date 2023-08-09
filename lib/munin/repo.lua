local database = require("munin.data")
local lfs = require("lfs")

local function config_path(repo_path)
    return repo_path.."/.munin"
end

local function db_path(repo_path)
    return repo_path.."/.munin/notes.db"
end

local function backup_path(repo_path)
    return repo_path.."/.munin/notes.db.backup"
end

local function parse_tags(text)
    local tags = {}
    for tag in text:gmatch("%@([%w-_]+)") do
        table.insert(tags, tag)
    end
    return tags
end

local repo = {}

function repo.exists()
    local db, err = lfs.attributes(repo._db_path)
    return db ~= nil, err
end

function repo.save_note(title, text, category)
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local tags = parse_tags(text)

    local path = title
    if category then
        path = category.."/"..path
    end

    local note = {
        title = title,
        category = category,
        tags = tags,
        path = path,
        content = text
    }

    local existing_note, get_note_error = repo.get_note(path)
    if get_note_error then
        return nil, "Failed to check for existing note: "..get_note_error
    end

    if existing_note then
        local update_note_error = database.update_note(repo._db_path, note)
        if update_note_error then
            return nil, "Failed to update note: "..update_note_error
        end
    else
        local error_msg = database.add_note(repo._db_path, note)
        if error_msg then
            return nil, "Failed to add new note: "..error_msg
        end
    end
    return note
end

function repo.get_note(path)
    local notes, error_msg = database.query_notes_by_path(repo._db_path, path)

    if notes then
        return notes[1]
    else
        return nil, error_msg
    end
end

function repo.get_notes_by_title(title)
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.query_notes_by_title(repo._db_path, title)
end

function repo.get_notes_by_category(category)
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.query_notes_by_category(repo._db_path, category)
end

function repo.get_notes_by_tag(tag)
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.query_notes_by_tag(repo._db_path, tag)
end

function repo.get_notes()
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.all_notes(repo._db_path)
end

function repo.search_notes(search_term)
    if not repo.exists() then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.search_notes(repo._db_path, search_term)
end

function repo.create_new()
    local config_dir, _ = lfs.attributes(repo._config_path)
    if not config_dir then
        lfs.mkdir(repo._config_path)
    end

    local database_file, _ = lfs.attributes(repo._db_path)
    if not database_file then
        local error_msg = database.create_database(repo._db_path)
        if error_msg then
            return error_msg
        end
    end
end

return {
    init = function(repo_path)
        repo._path = repo_path
        repo._config_path = config_path(repo_path)
        repo._db_path = db_path(repo_path)
        repo._backup_path = backup_path(repo_path)
        return repo
    end
}
