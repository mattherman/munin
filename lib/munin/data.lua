local sql = require("lsqlite3")


local M = {}

local function format_sqlite_error(code, msg)
    local preamble = "SQLite Error ("..code..")"
    if msg then
        return preamble..": "..msg
    else
        return preamble
    end
end

local function exec_statement(db_file, statement)
    local db, open_error_code, open_error_msg = sql.open(db_file)
    if not db then
        return format_sqlite_error(open_error_code, open_error_msg)
    end

    local exec_error_code = db:exec(statement)
    db:close()

    if (exec_error_code and exec_error_code ~= 0) then
        return format_sqlite_error(exec_error_code)
    end
end

local function exec_query(db_file, query)
    local db, open_error_code, open_error_msg = sql.open(db_file)
    if not db then
        return nil, format_sqlite_error(open_error_code, open_error_msg)
    end

    local results = {}

    -- TODO: Investigate error handling here, pcall?
    for result in db:nrows(query) do
        table.insert(results, result)
    end
    db:close()

    return results
end

function M.create_database(db_file)
    local statement = [=[
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
    ]=]
    exec_statement(db_file, statement)
end

function M.add_note(db_file, new_note)
    local query = string.format("INSERT INTO notes (title, category, content) VALUES ('%s', '%s', '%s')", new_note.title, new_note.category, new_note.content)
    return exec_statement(db_file, query)
end

function M.get_note(db_file, title)
    local query = string.format("SELECT * FROM notes WHERE title = '%s'", title)
    local notes, error_msg = exec_query(db_file, query)
    if notes then
        return notes[1]
    else
        return nil, error_msg
    end
end

return M
