# Munin Documentation

Creating a new notes repository:
```
local repo = require("munin").init("your/repo/path")
local err = repo.create_new()
```

This will create a `/your/repo/path/.munin` directory with a `notes.db` file in it.

To add a new note:
```
local note, err = repo.add_note("My Note", "This is the content of the note", "category/subcategory")
```

To retrieve that note by title:
```
local note, err = repo.get_note("My Note")
```
