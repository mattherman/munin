local M = {}

local patterns = {
    file = "[^/]*$",
    category = "(.*)%/",
    title = "(.*)%.",
    extension = "%.(.*)$"
}

local function get_note_path(title, category)
    if category then
        return string.format("%s/%s", category, title)
    else
        return title
    end
end

function M.parse_file_path(file_path, repo_path)
    local escaped_repo_path = repo_path:gsub("%-", "%%-")
    local relative_file_path = file_path:gsub(escaped_repo_path .. "/", "")
    local category = relative_file_path:match(patterns.category)
    local file = relative_file_path:match(patterns.file)
    local title = file:match(patterns.title)
    local extension = file:match(patterns.extension)

    return {
        original_file_path = file_path,
        relative_file_path = relative_file_path,
        path = get_note_path(title, category),
        title = title,
        category = category,
        extension = extension
    }
end

function M.get_absolute_path(note_path, repo_path)
    return string.format("%s/%s.md", repo_path, note_path)
end

return M
