local database = require("munin.data")
local lfs = require("lfs")

local function config_path(repo_path)
    return repo_path.."/.munin"
end

local function db_path(repo_path)
    return repo_path.."/.munin/notes.db"
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

    local note = {
        title = title,
        category = category,
        path = category.."/"..title,
        content = text
    }
    local error_msg = database.add_note(db_path(repo._path), note)
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
    local notes, error_msg = database.query_notes(db_path(repo._path), query)

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
    return database.query_notes(db_path(repo._path), query)
end

function repo.get_notes_by_category(category)
    if not repo_exists(repo._path) then
        return nil, "Repository at "..repo._path.." does not exist"
    end

    local category_query = {
        category = { type = "match", value = category }
    }
    local category_notes, category_error = database.query_notes(db_path(repo._path), category_query)
    if category_error then
        return nil, category_error
    end

    local subcategory_query = {
        category = { type = "like", value = category.."/%" }
    }
    local subcategory_notes, subcategory_error = database.query_notes(db_path(repo._path), subcategory_query)
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

    return database.query_notes(db_path(repo._path), {})
end

function repo.create_new()
    local config = config_path(repo._path)
    local db = db_path(repo._path)

    local config_dir, _ = lfs.attributes(config)
    if not config_dir then
        lfs.mkdir(config)
    end

    local database_file, _ = lfs.attributes(db)
    if not database_file then
        local error_msg = database.create_database(db)
        if error_msg then
            return error_msg
        end
    end
end

return {
    init = function(repo_path)
        repo._path = repo_path
        return repo
    end
}
