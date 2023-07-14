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

local function repo_exists(repo_path)
    local db, err = lfs.attributes(db_path(repo_path))
    return db ~= nil, err
end

local repo = {}

function repo.add_note(title, text, category)
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local path = title
    if category then
        path = category.."/"..path
    end

    local note = {
        title = title,
        category = category,
        path = path,
        content = text
    }
    local error_msg = database.add_note(repo._db_path, note)
    if error_msg then
        return nil, "Failed to add new note: "..error_msg
    else
        return note
    end
end

function repo.get_note(path)
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local query = {
        path = { type = "match", value = path }
    }
    local notes, error_msg = database.query_notes(repo._db_path, query)

    if notes then
        return notes[1]
    else
        return nil, error_msg
    end
end

function repo.get_notes_by_title(title)
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local query = {
        title = { type = "match", value = title }
    }
    return database.query_notes(repo._db_path, query)
end

function repo.get_notes_by_category(category)
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local category_query = {
        category = { type = "match", value = category }
    }
    local category_notes, category_error = database.query_notes(repo._db_path, category_query)
    if category_error then
        return nil, category_error
    end

    local subcategory_query = {
        category = { type = "like", value = category.."/%" }
    }
    local subcategory_notes, subcategory_error = database.query_notes(repo._db_path, subcategory_query)
    if subcategory_error then
        return nil, category_error
    end

    local notes = category_notes or {}
    for _, v in ipairs(subcategory_notes or {}) do
        table.insert(notes, v)
    end

    return notes
end

function repo.get_notes()
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    return database.query_notes(repo._db_path, {})
end

function repo.search_notes(search_term)
    if not repo_exists(repo._path) then
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
