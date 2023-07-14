local lfs = require("lfs")

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

local patterns = {
    extension = ".+%.(%a*)",
    category = "(.*)%/",
    title = "(.+)%."
}

local function index_directory(repo, path)
    log("\t"..path)
    local notes = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." and file ~= ".munin" then
            local file_path = path..'/'..file
            local file_attr, error_msg = lfs.attributes(file_path)
            if error_msg then
                log("Skipping "..file_path..": "..error_msg)
            end

            if file_attr.mode == "directory" then
                local dir_notes = index_directory(repo, file_path)
                for _, n in ipairs(dir_notes or {}) do
                    table.insert(notes, n)
                end
            elseif file:match(patterns.extension) == "md" then
                local note_path = file_path:sub(string.len(repo._path) + 2)
                table.insert(notes, {
                    title = file:match(patterns.title),
                    category = note_path:match(patterns.category),
                    note_path = note_path
                })
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

function M.index(repo)
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
    local note_files = index_directory(repo, repo._path)

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
