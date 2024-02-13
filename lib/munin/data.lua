local sql = require("lsqlite3")
local logger = require("munin.logger")

local M = { tracing_enabled = false }

local function table_unpack(...)
    if table.unpack then
        return table.unpack(...)
    else
        return unpack(...)
    end
end

local function format_sqlite_error(code, msg)
    local preamble = "SQLite Error"
    if code then
        preamble = preamble.." ("..code..")"
    end
    if msg then
        return preamble..": "..msg
    else
        return preamble
    end
end

local function begin_tracing(db)
    db:trace(function (_, traced_sql) logger.trace("SQL:"..traced_sql) end)
end

local function exec_statements(db_file, statements)
    local db, open_error_code, open_error_msg = sql.open(db_file)
    if not db then
        return format_sqlite_error(open_error_code, open_error_msg)
    end

    if M.tracing_enabled then begin_tracing(db) end

    for _, statement in ipairs(statements) do
        local stmt, prepare_error_msg = db:prepare(statement.sql)
        if not stmt then
            db:close()
            return format_sqlite_error(1, prepare_error_msg)
        end

        local parameters = statement.args
        if parameters and #parameters > 0 then
            stmt:bind_values(table_unpack(parameters))
        end

        local step_error_code = stmt:step()
        if (step_error_code and step_error_code ~= 0 and step_error_code ~= 101) then
            db:close()
            return format_sqlite_error(step_error_code)
        end
    end

    db:close()
end

local function exec_query(db_file, query)
    local db, open_error_code, open_error_msg = sql.open(db_file)
    if not db then
        return nil, format_sqlite_error(open_error_code, open_error_msg)
    end

    if M.tracing_enabled then begin_tracing(db) end

    local stmt, prepare_error_msg = db:prepare(query.sql)
    if not stmt then
        db:close()
        return nil, format_sqlite_error(1, prepare_error_msg)
    end

    local parameters = query.args
    if parameters and #parameters > 0 then
        stmt:bind_values(table_unpack(parameters))
    end

    local results = {}
    for result in stmt:nrows() do
        table.insert(results, result)
    end

    db:close()

    return results
end

local function create_statement(text, args)
    return { sql = text, args = args }
end

local function query_notes(db_file, condition, args)
    condition = condition or ''
    args = args or {}
    return exec_query(
        db_file,
        create_statement(string.format([=[
            SELECT
                notes.path,
                notes.title,
                notes.category,
                t.tags,
                notes_search.content
            FROM notes
            INNER JOIN notes_search
                ON notes_search.path = notes.path
            LEFT JOIN (
                SELECT note_path, GROUP_CONCAT(tag, ',') as tags
                FROM note_tags
            ) AS t
                ON t.note_path = notes.path
            WHERE 1=1
            %s;
        ]=], condition),
        args))
end

local function replace_tags(db_file, note_path, tags)
    local statements = {}
    table.insert(
        statements,
        create_statement([=[ DELETE FROM note_tags WHERE note_path = :note_path; ]=], { note_path }))

    for _, tag in ipairs(tags) do
        table.insert(
            statements,
            create_statement([=[ INSERT INTO note_tags (note_path, tag) VALUES (:note_path, :tag); ]=], { note_path, tag }))
    end

    return exec_statements(db_file, statements)
end

function M.create_database(db_file)
    return exec_statements(db_file, {
        create_statement([=[
            CREATE TABLE notes (
                path text PRIMARY KEY,
                title text NOT NULL,
                category text NULL
            );
        ]=]),
        create_statement([=[
            CREATE VIRTUAL TABLE notes_search USING FTS5(
                path UNINDEXED,
                title,
                content
            );
        ]=]),
        create_statement([=[
            CREATE TABLE note_tags (
                tag text NOT NULL,
                note_path text NOT NULL,
                FOREIGN KEY (note_path) REFERENCES notes (path)
            );
        ]=])
    })
end

function M.add_note(db_file, new_note)
    local note_inserts = {
        create_statement(
            [=[ INSERT INTO notes (title, category, path) VALUES (:title, :category, :path); ]=],
            { new_note.title, new_note.category, new_note.path }),
        create_statement(
            [=[ INSERT INTO notes_search (path, title, content) VALUES (:path, :title, :content); ]=],
            { new_note.path, new_note.title, new_note.content })
    }
    local note_insert_error = exec_statements(db_file, note_inserts)
    if note_insert_error then
        return note_insert_error
    end

    if new_note.tags and #new_note.tags > 0 then
        return replace_tags(db_file, new_note.path, new_note.tags)
    end
end

function M.update_note(db_file, note)
    local note_update = create_statement(
        [=[
            UPDATE notes_search
            SET content = :content
            WHERE path = :path
        ]=],
        { note.content, note.path })
    local note_update_error = exec_statements(db_file, { note_update })
    if note_update_error then
        return note_update_error
    end

    if note.tags and #note.tags > 0 then
        return replace_tags(db_file, note.path, note.tags)
    end
end

function M.query_notes_by_path(db_file, path)
    return query_notes(
        db_file,
        [=[ AND (notes.path = :path) ]=],
        { path })
end

function M.query_notes_by_category(db_file, category)
    local subcategory = category.."/%"
    local condition = [=[ AND (notes.category = :category OR notes.category like :subcategory) ]=]
    local arguments = { category, subcategory }
    return query_notes(db_file, condition, arguments)
end

function M.query_notes_by_title(db_file, title)
    return query_notes(
        db_file,
        [=[ AND (notes.title = :title) ]=],
        { title })
end

function M.query_notes_by_tag(db_file, tag)
    return exec_query(
        db_file,
        create_statement([=[
            SELECT
                notes.path,
                notes.title,
                notes.category,
                note_tags.tag,
                notes_search.content
            FROM note_tags
            INNER JOIN notes
                ON note_tags.note_path = notes.path
            INNER JOIN notes_search
                ON notes.path = notes_search.path
            WHERE note_tags.tag = :tag
        ]=],
        { tag }))
end

function M.search_notes(db_file, search_term)
    local query = create_statement([=[
        SELECT
            n.path,
            n.title,
            n.category,
            t.tags,
            ns.content,
            snippet(notes_search, -1, '', '', '', 16) as snippet
        FROM notes_search(:search_term) AS ns
        INNER JOIN notes AS n
            ON ns.path = n.path
        LEFT JOIN (
            SELECT note_path, GROUP_CONCAT(tag, ',') as tags
            FROM note_tags
        ) AS t
            ON n.path = t.note_path
        ]=],
        { search_term })
    return exec_query(db_file, query)
end

function M.all_notes(db_file)
    return query_notes(db_file)
end

return M
