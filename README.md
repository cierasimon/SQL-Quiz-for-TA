# The Runway Exam: A SQL Quiz on Designer Shoes

A 20-point SQL quiz that students take against a live, hosted PostgreSQL database. Sign in, pick a question, write a query, run it, and see the result table.

**Live quiz site:** https://cierasimon.github.io/SQL-Quiz-for-TA/

> Messy code is so last season. Clean architecture never goes out of style.

## Organization for Grading

| Required item | Where to find it |
|---|---|
| 1. Hosted PostgreSQL database | Supabase project (Session pooler, `sslmode=require`); schema and data in `init.sql` and `quiz_setup.sql` |
| 2. Authentication | Supabase Auth (email + password) on the quiz site; signed-out users cannot run queries or save answers |
| 3. GitHub Actions with GitHub Secrets | `.github/workflows/ci.yml`; see the **Actions** tab for the run; credentials come from repository secrets, never from the file |
| 4. 20-point SQL quiz | 5 questions x 4 points, stored in the `quiz_questions` table (also in `query.py`); each has a hint with the expected SQL and expected result |

## How to Take the Quiz

1. Open the quiz site and **Sign up** with an email and a password of at least 6 characters. If email confirmation is enabled, click the link in the confirmation email, then return to the site.
2. **Sign in.** You will see five questions, called "Looks".
3. Click a question, type a `SELECT` query, and press **Strike a pose: Run** to see the result table.
4. **Save answer** stores your SQL. **Show hint** displays the expected SQL and runs it live to show the expected result.
5. Answers are judged by the result set, not by matching the SQL text.

### Quick grader check
- Signed out: only the login form is visible.
- Signed in, Look 01: run `SELECT * FROM garments` and confirm rows appear.
- Run `SELECT * FROM auth.users` and confirm it is refused.
- Run `DELETE FROM garments` and confirm it is refused (only `SELECT` or `WITH` is accepted).

## The Quiz

| Look | Points | Skill | Question |
|---|---|---|---|
| 01 | 4 | Filtering and sorting | Name and `retail_price` of every garment priced above 1200, most expensive first |
| 02 | 4 | `GROUP BY` | Number of garments in each category, highest count first |
| 03 | 4 | `JOIN` | Name and brand of every ankle boot, ordered by brand |
| 04 | 4 | Multi-table aggregate | Total revenue per brand from paid and shipped sales, highest first |
| 05 | 4 | CTE | Brands whose revenue is above the average brand revenue |

## Dataset

Topic: designer shoes. Three related tables support joins, aggregates, and CTEs.

| Table | Rows | Contents |
|---|---|---|
| `collections` | 11 | brand, season, release year, concept |
| `garments` | 22 | shoe name, category, colorway, material, retail price, stock |
| `sales` | 22 | garment, date, customer city, status, quantity, unit price |

The brand, season, and concept details for the first six collections (Vivienne Westwood, Chanel, Dior, Gucci, Ralph Lauren, Alexander McQueen) are based on Vogue Runway coverage, with sources listed at the top of `init.sql`. The remaining five collections, all shoe names, prices, inventory, and sales are simulated practice data, not official brand information.

## Architecture

```
Browser (GitHub Pages: docs/index.html + supabase-js)
   |  sign in / sign up                 -> Supabase Auth
   |  rpc("run_quiz_sql")               -> Postgres function (SECURITY DEFINER)
   |  select quiz_questions             -> RLS: signed-in users only
   |  insert quiz_attempts              -> RLS: own rows only
   v
Supabase PostgreSQL (Session pooler)
```

How student SQL is kept safe:

- `run_quiz_sql(q)` is executable only by signed-in users; `anon` and `PUBLIC` are revoked.
- It is owned by a `quiz_runner` role that can `SELECT` only `collections`, `garments`, and `sales`. It cannot read `auth.users` or the answer log.
- It accepts a single `SELECT` or `WITH` statement, has a 5 second timeout, and returns at most 200 rows.
- The data tables are not reachable directly through the API. All access goes through the function.

## File Structure

```
├── init.sql                   # creates and seeds collections, garments, sales
├── quiz_setup.sql             # quiz tables, RLS policies, run_quiz_sql(), quiz_runner role, 5 questions
├── query.py                   # runs each question's answer SQL (parameterized) and prints the results
├── requirements.txt           # psycopg2-binary, python-dotenv
├── docs/
│   └── index.html             # the quiz website (served by GitHub Pages)
├── .github/workflows/ci.yml   # GitHub Actions: runs query.py against the live database using secrets
├── .gitignore                 # ignores .venv/, __pycache__/, *.pyc, .env
└── README.md                  # this file
```

## GitHub Actions and Secrets

`ci.yml` runs on every push and can also be started manually. It installs dependencies and runs `python query.py`, which executes all five answer queries against the live Supabase database.

The password is never in the repository. The workflow reads it from repository secrets:

| Secret | Value |
|---|---|
| `POSTGRES_USER` | Session pooler user, in the form `postgres.<project-ref>` |
| `POSTGRES_PASSWORD` | Database password |
| `DB_HOST` | Session pooler host, e.g. `aws-0-<region>.pooler.supabase.com` |

The database name, port (5432), and `sslmode=require` are set directly in the workflow because they are not secret.

## Setup (to reproduce this project)

1. Create a free Supabase project. In the SQL editor, run `init.sql`, then `quiz_setup.sql`. Supabase may warn about "destructive operations" because the script uses `REVOKE`; it does not delete any data.
2. In `docs/index.html`, set `SUPABASE_URL` to the project URL (`https://<project-ref>.supabase.co`, with nothing after `.supabase.co`) and `ANON_KEY` to the publishable key. This key is public by design. Never use the secret or `service_role` key.
3. In Supabase, go to Authentication > URL Configuration and set the Site URL to the quiz site URL, so confirmation emails redirect to the site.
4. In the GitHub repository, go to Settings > Secrets and variables > Actions and add the three secrets above.
5. Go to Settings > Pages, choose "Deploy from a branch", then `main` with the `/docs` folder.

### Run the Python script locally

Create a `.env` file in the project folder. It is listed in `.gitignore` and must never be committed:

```
POSTGRES_DB=postgres
POSTGRES_USER=postgres.<project-ref>
POSTGRES_PASSWORD=<database-password>
DB_HOST=aws-0-<region>.pooler.supabase.com
DB_PORT=5432
DB_SSLMODE=require
```

Create and activate a virtual environment, then install dependencies and run:

```
python -m venv .venv
```

| Terminal | Activate |
|---|---|
| Git Bash | `source .venv/Scripts/activate` |
| PowerShell | `.\.venv\Scripts\Activate.ps1` |

```
pip install -r requirements.txt
python query.py
```

`python query.py` prints each question and the table its answer returns. You can also test a taker-style query with `python query.py "SELECT * FROM garments LIMIT 3"`.

## Extra Credit

- **Parameterized queries:** `query.py` passes values as `%s` parameters and never builds SQL with f-strings. Because `%s` is a Python placeholder, not SQL, the copies of the answers stored for the website (in `quiz_setup.sql`) use plain literal values instead.
- **Audit log:** the `quiz_attempts` table records the user id, question, SQL text, and timestamp of every saved answer. Runs that are not saved are not logged.
- **Integrity:** signed-in users have only `SELECT` and `INSERT` on `quiz_attempts`, with no `UPDATE` or `DELETE`, and row-level security limits each user to their own rows. A taker cannot edit or remove the log.

## What I Learned

- **Row-level security hides data silently.** My first queries returned 0 rows, not an error, because the tables had RLS on and the `quiz_runner` role had no policy. Adding a `SELECT` policy for that role fixed it.
- **Separate the role that runs student SQL from the role that owns the data.** Running student queries as a role that can read only three tables is a stronger guard than checking the query text alone.
- **Session pooler, not Direct.** The Direct connection is IPv6-only and fails on many networks, so every connection here uses the Session pooler with `sslmode=require`.
- **Public keys versus secrets.** The browser can safely carry the publishable key because the database enforces access, while the database password lives only in `.env` and GitHub Secrets.
- **Public hosting needs its own redirect setup.** Confirmation emails defaulted to `localhost:3000` until I set the Site URL in Supabase.
