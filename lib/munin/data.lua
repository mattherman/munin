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
            path text PRIMARY KEY,
            title text NOT NULL,
            category text NULL
        );

        CREATE VIRTUAL TABLE notes_search USING FTS5(
            path UNINDEXED,
            title,
            content
        );

        CREATE TABLE note_tags (
            tag text NOT NULL,
            note_path text NOT NULL,
            FOREIGN KEY (note_path) REFERENCES notes (path)
        );
    ]=]
    return exec_statement(db_file, statement)
end

function M.add_note(db_file, new_note)
    local query = string.format([=[
        INSERT INTO notes (title, category, path) VALUES ('%s', '%s', '%s');
        INSERT INTO notes_search (path, title, content) VALUES ('%s', '%s', '%s');
        ]=],
        new_note.title,
        new_note.category or "NULL",
        new_note.path,
        new_note.path,
        new_note.title,
        new_note.content)
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
        table.insert(t, string.format("AND n.%s = '%s'", k, v))
    end
    local add_like = function(t, k, v)
        table.insert(t, string.format("AND n.%s like '%s'", k, v))
    end

    local add_condition = {
        match = add_match,
        like = add_like
    }

    local query_parts = {
        [=[
            SELECT
                n.path,
                n.title,
                n.category,
                ns.content
            FROM notes AS n
            INNER JOIN notes_search AS ns
                ON n.path = ns.path
            WHERE 1=1
        ]=]
    }

    for k, c in pairs(conditions) do
        add_condition[c.type](query_parts, k, c.value)
    end

    local query = table.concat(query_parts, " ")
    return exec_query(db_file, query)
end

-- Underline control characters = \x1B[4m<my_text>\x1B[0m
function M.search_notes(db_file, search_term)
    local query = string.format([=[
        SELECT
            n.path,
            n.title,
            n.category,
            ns.content,
            snippet(notes_search, -1, '', '', '', 16) as snippet
        FROM notes_search('%s') AS ns
        INNER JOIN notes AS n
            ON ns.path = n.path
        ]=],
        search_term)
    return exec_query(db_file, query)
end

return M
