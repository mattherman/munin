notes = {}

function add_note(title, text, category, tags)
    notes[title] = text
end

function get_note(title)
    return notes[title]
end

return {
    add_note = add_note,
    get_note = get_note
}
