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

local function replace_tags(db_file, note_path, tags)
    local tag_insert_values = {}
    for _, tag in ipairs(tags) do
        table.insert(
            tag_insert_values,
            string.format("('%s', '%s')", note_path, tag))
    end
    local tag_delete = string.format("DELETE FROM note_tags WHERE note_path = '%s'", note_path)
    local tag_insert = "INSERT INTO note_tags (note_path, tag) VALUES "..table.concat(tag_insert_values, ", ")
    local tag_replace = tag_delete..";"..tag_insert
    local tag_replace_error = exec_statement(db_file, tag_replace)
    if tag_replace_error then
        return tag_replace_error
    end
end

function M.add_note(db_file, new_note)
    local note_insert = string.format([=[
        INSERT INTO notes (title, category, path) VALUES ('%s', '%s', '%s');
        INSERT INTO notes_search (path, title, content) VALUES ('%s', '%s', '%s');
        ]=],
        new_note.title,
        new_note.category or "NULL",
        new_note.path,
        new_note.path,
        new_note.title,
        new_note.content)
    local note_insert_error = exec_statement(db_file, note_insert)
    if note_insert_error then
        return note_insert_error
    end

    if new_note.tags and #new_note.tags > 0 then
        return replace_tags(db_file, new_note.path, new_note.tags)
    end
end

function M.update_note(db_file, note)
    local note_update = string.format([=[
        UPDATE notes_search
        SET content = '%s'
        WHERE path = '%s'
        ]=],
        note.content,
        note.path)
    local note_update_error = exec_statement(db_file, note_update)
    if note_update_error then
        return note_update_error
    end

    if note.tags and #note.tags > 0 then
        return replace_tags(db_file, note.path, note.tags)
    end
end

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
                t.tags,
                ns.content
            FROM notes AS n
            INNER JOIN notes_search AS ns
                ON n.path = ns.path
            LEFT JOIN (
                SELECT note_path, GROUP_CONCAT(tag, ',') as tags
                FROM note_tags
            ) AS t
                ON n.path = t.note_path
            WHERE 1=1
        ]=]
    }

    for k, c in pairs(conditions) do
        add_condition[c.type](query_parts, k, c.value)
    end

    local query = table.concat(query_parts, " ")
    return exec_query(db_file, query)
end

function M.query_notes_by_tag(db_file, tag)
    local query = string.format([=[
        SELECT
            n.path,
            n.title,
            n.category,
            t.tags,
            ns.content
        FROM note_tags AS t
        INNER JOIN notes AS n
            ON t.note_path = n.path
        INNER JOIN notes_search AS ns
            ON n.path = ns.path
        WHERE t.tag = '%s'
        ]=],
        tag)

    return exec_query(db_file, query)
end

-- TODO: Underline control characters = \x1B[4m<my_text>\x1B[0m
function M.search_notes(db_file, search_term)
    local query = string.format([=[
        SELECT
            n.path,
            n.title,
            n.category,
            t.tags,
            ns.content,
            snippet(notes_search, -1, '', '', '', 16) as snippet
        FROM notes_search('%s') AS ns
        INNER JOIN notes AS n
            ON ns.path = n.path
        LEFT JOIN (
            SELECT note_path, GROUP_CONCAT(tag, ',') as tags
            FROM note_tags
        ) AS t
            ON n.path = t.note_path
        ]=],
        search_term)
    return exec_query(db_file, query)
end

return M
