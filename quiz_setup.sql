-- Run AFTER init.sql, in the Supabase SQL editor.

-- 1. A role that can only SELECT the three data tables. Quiz SQL runs as this role.
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'quiz_runner') THEN
    CREATE ROLE quiz_runner NOLOGIN;
  END IF;
END $$;
GRANT quiz_runner TO postgres;
GRANT USAGE ON SCHEMA public TO quiz_runner;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM quiz_runner;
GRANT SELECT ON collections, garments, sales TO quiz_runner;

-- Nobody reaches the data tables directly through the API; only through run_quiz_sql().
REVOKE ALL ON collections, garments, sales FROM anon, authenticated;

-- 2. Quiz tables
CREATE TABLE IF NOT EXISTS quiz_questions (
  id INT PRIMARY KEY,
  prompt TEXT NOT NULL,
  points INT NOT NULL,
  hint_sql TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS quiz_attempts (   -- doubles as the audit log
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  question_id INT NOT NULL REFERENCES quiz_questions(id),
  sql_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts  ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON quiz_questions, quiz_attempts FROM anon, authenticated;
GRANT SELECT ON quiz_questions TO authenticated;
GRANT SELECT, INSERT ON quiz_attempts TO authenticated;   -- no UPDATE/DELETE: takers can't edit the log

DROP POLICY IF EXISTS q_read ON quiz_questions;
CREATE POLICY q_read ON quiz_questions FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS a_read ON quiz_attempts;
CREATE POLICY a_read ON quiz_attempts FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS a_insert ON quiz_attempts;
CREATE POLICY a_insert ON quiz_attempts FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- 3. The function the website calls. Owned by quiz_runner, so it can only read the 3 data tables.
CREATE OR REPLACE FUNCTION run_quiz_sql(q TEXT) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
SET statement_timeout = '5s'
AS $$
DECLARE cleaned TEXT; result JSONB;
BEGIN
  cleaned := btrim(regexp_replace(q, ';\s*$', ''));
  IF cleaned ~ ';' THEN RAISE EXCEPTION 'Only one statement is allowed.'; END IF;
  IF cleaned !~* '^(select|with)\s' THEN RAISE EXCEPTION 'Only SELECT queries are allowed.'; END IF;
  EXECUTE 'SELECT coalesce(jsonb_agg(t), ''[]''::jsonb) FROM (SELECT * FROM ('
          || cleaned || E'\n) x LIMIT 200) t' INTO result;
  RETURN result;
END $$;

GRANT CREATE ON SCHEMA public TO quiz_runner;      -- needed only for the owner change
ALTER FUNCTION run_quiz_sql(TEXT) OWNER TO quiz_runner;
REVOKE CREATE ON SCHEMA public FROM quiz_runner;
REVOKE EXECUTE ON FUNCTION run_quiz_sql(TEXT) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION run_quiz_sql(TEXT) TO authenticated;   -- signed-in only

-- 4. Questions: 5 x 4 = 20 points. The site runs hint_sql live to show the expected result.
INSERT INTO quiz_questions (id, prompt, points, hint_sql) VALUES
(1, 'List the name and retail_price of every garment priced above 1200, most expensive first.', 4,
 'SELECT name, retail_price FROM garments WHERE retail_price > 1200 ORDER BY retail_price DESC'),
(2, 'How many garments are in each category? Show category and garment_count, highest count first (ties alphabetical).', 4,
 'SELECT category, COUNT(*) AS garment_count FROM garments GROUP BY category ORDER BY garment_count DESC, category ASC'),
(3, 'Show the garment name and brand for every ankle boot, ordered by brand then name.', 4,
 'SELECT g.name, c.brand FROM garments g JOIN collections c ON c.collection_id = g.collection_id WHERE g.category = ''ankle boot'' ORDER BY c.brand, g.name'),
(4, 'What is the total revenue (quantity * unit_price) per brand, counting only paid and shipped sales? Highest first.', 4,
 'SELECT c.brand, SUM(s.quantity * s.unit_price) AS revenue FROM sales s JOIN garments g ON g.garment_id = s.garment_id JOIN collections c ON c.collection_id = g.collection_id WHERE s.status IN (''paid'', ''shipped'') GROUP BY c.brand ORDER BY revenue DESC, c.brand'),
(5, 'Using a CTE, list brands whose paid/shipped revenue is above the average brand revenue.', 4,
 'WITH brand_revenue AS (SELECT c.brand, SUM(s.quantity * s.unit_price) AS revenue FROM sales s JOIN garments g ON g.garment_id = s.garment_id JOIN collections c ON c.collection_id = g.collection_id WHERE s.status IN (''paid'', ''shipped'') GROUP BY c.brand) SELECT brand, revenue FROM brand_revenue WHERE revenue > (SELECT AVG(revenue) FROM brand_revenue) ORDER BY revenue DESC')
ON CONFLICT (id) DO UPDATE SET prompt = EXCLUDED.prompt, points = EXCLUDED.points, hint_sql = EXCLUDED.hint_sql;
