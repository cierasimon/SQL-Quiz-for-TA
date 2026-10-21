# SQL Quiz project

## Activate the Python environment on Windows

Choose the instructions for the terminal you are using. The screenshot shows
Git Bash (`MINGW64`), which uses a different activation command from PowerShell.

### Git Bash

From inside the `SQL-Quiz-For-TA` project folder:

```bash
source .venv/Scripts/activate
```

From the `dataEng` parent folder:

```bash
source SQL-Quiz-For-TA/.venv/Scripts/activate
```

### PowerShell

The virtual environment is named `.venv` and is inside the `SQL-Quiz-For-TA`
project folder. In PowerShell, the activation path depends on your current
directory.

From the `dataEng` parent folder:

```powershell
.\SQL-Quiz-For-TA\.venv\Scripts\Activate.ps1
```

From inside the `SQL-Quiz-For-TA` project folder:

```powershell
.\.venv\Scripts\Activate.ps1
```

To change into the project folder first:

```powershell
Set-Location "C:\Users\cece2\Desktop\mids\dataEng\SQL-Quiz-For-TA"
.\.venv\Scripts\Activate.ps1
```

Check the prompt for `(.venv)` after activation. In Git Bash, use `source` and
forward slashes; do not type the PowerShell `.\.venv\Scripts\Activate.ps1`
command there. In PowerShell, use the commands in the section above. The
environment folder is `.venv` (with a leading dot).

If the `.venv` folder does not exist, create it from the project folder and
install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

For Git Bash, use `source .venv/Scripts/activate` instead of the PowerShell
activation line.