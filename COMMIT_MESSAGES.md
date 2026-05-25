# Suggested Git Commit Messages

Realistic commit history in chronological order. Copy these as you build the project — they mix proper messages with the kind of lazy ones that actually appear in real repos.

```
git commit -m "initial commit"

git commit -m "add project structure, data dictionary, sql folder"

git commit -m "eda notebook first pass — data loading and basic cleaning"

git commit -m "fix date parsing, dayfirst=False was swapping month and day on older records"

git commit -m "handle missing customer IDs, document decision in notebook"

git commit -m "add monthly revenue and top products sql queries"

git commit -m "finally got the returns calc right — was double counting C-invoices"

git commit -m "excel builder working, added conditional formatting for MoM revenue drops"

git commit -m "add looker studio dashboard config"

git commit -m "clean up notebook, write findings section, add readme"
```

> Note: push with `git push -u origin main` after your first commit. The project uses `main` as the default branch — set it with `git branch -M main` before pushing.
