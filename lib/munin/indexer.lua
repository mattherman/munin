local lfs = require("lfs")
local utils = require("munin.utils")

local M = {}

local function backup_database(repo)
    return os.rename(repo._db_path, repo._backup_path)
end

local function drop_backup_database(repo)
    os.remove(repo._backup_path)
end

local function get_file_path(repo, note)
    return repo._path.."/"..note.note_path
end

local function log(msg)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print("["..timestamp.."] "..msg)
end

local function matches_extension(file_extension, allowed_file_extensions)
    for _, ext in ipairs(allowed_file_extensions) do
        if ext == file_extension then return true end
    end
end

local function starts_with(str, str_to_match)
    return str:sub(1, string.len(str_to_match)) == str_to_match
end

local function index_directory(repo, path, extensions_to_match)
    log("\t"..path)
    local notes = {}
    for file in lfs.dir(path) do
        log("\t\t"..file)
        if not starts_with(file, ".") then
            local file_path = path..'/'..file
            local file_attr, error_msg = lfs.attributes(file_path)
            if error_msg then
                log("Skipping "..file_path..": "..error_msg)
            end

            if file_attr.mode == "directory" then
                local dir_notes = index_directory(repo, file_path, extensions_to_match)
                for _, n in ipairs(dir_notes or {}) do
                    table.insert(notes, n)
                end
            else
                local parsed_path = utils.parse_file_path(file_path, repo._path)
                if matches_extension(parsed_path.extension, extensions_to_match) then
                    table.insert(notes, {
                        title = parsed_path.title,
                        category = parsed_path.category,
                        note_path = parsed_path.relative_file_path
                    })
                end
            end
        end
    end
    return notes
end

local function add_note(repo, note)
    local file_path = get_file_path(repo, note)
    local file = assert(io.open(file_path, "r"))
    local content = file:read("*all")
    if file then file:close() end

    return repo.save_note(note.title, content, note.category)
end

function M.index(repo, file_extensions)
    log("Starting to index "..repo._path)
    local created_backup = false
    local existing_db, _ = lfs.attributes(repo._db_path)
    if existing_db then
        log("Creating backup at "..repo._backup_path.."...")
        local _, error_msg = backup_database(repo)
        if error_msg then
            return "Failed to backup old database at "..repo._backup_path..": "..error_msg
        end
        created_backup = true
        log("\tDone")
    end

    log("Creating new database...")
    local db_create_error_msg = repo.create_new()
    if db_create_error_msg then
        return "Failed to create new database: "..db_create_error_msg
    end
    log("\tDone")

    log("Gathering files...")
    file_extensions = file_extensions or { "md" }
    local note_files = index_directory(repo, repo._path, file_extensions)

    log("Adding files to database...")
    for _, n in ipairs(note_files or {}) do
        log("\t"..n.note_path)
        local _, error_msg = add_note(repo, n)
        if error_msg then
            return "Failed to add note to repository: "..error_msg
        end
    end

    if created_backup then
        log("Deleting backup database at "..repo._backup_path.."...")
        local _, error_msg = drop_backup_database(repo)
        if error_msg then
            return "Failed to remove backup database after indexing: "..error_msg
        end
        log("\tDone")
    end

    log("Indexing complete!")
end

return M
