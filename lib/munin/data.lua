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
            path text NOT NULL,
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
    return exec_statement(db_file, statement)
end

function M.add_note(db_file, new_note)
    local query = string.format("INSERT INTO notes (title, category, path, content) VALUES ('%s', '%s', '%s', '%s')", new_note.title, new_note.category, new_note.path, new_note.content)
    return exec_statement(db_file, query)
end

--[[

query = {
    title = {
        type = "match",
        value = "My Title"
    },
    category = {
        type = "like"
        value = "category/%"
    }
}

--]]
function M.query_notes(db_file, conditions)
    local add_match = function(t, k, v)
        table.insert(t, string.format("AND %s = '%s'", k, v))
    end
    local add_like = function(t, k, v)
        table.insert(t, string.format("AND %s like '%s'", k, v))
    end

    local add_condition = {
        match = add_match,
        like = add_like
    }

    local query_parts = {
        "SELECT * FROM notes WHERE 1=1"
    }

    for k, c in pairs(conditions) do
        add_condition[c.type](query_parts, k, c.value)
    end

    local query = table.concat(query_parts, " ")
    return exec_query(db_file, query)
end

return M
