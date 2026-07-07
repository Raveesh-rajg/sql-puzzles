CREATE OR REPLACE TABLE employees (
    emp_id     INTEGER NOT NULL,
    name       VARCHAR NOT NULL,
    manager_id INTEGER          -- NULL = CEO
);

INSERT INTO employees VALUES
(1, 'Dana',  NULL),   -- CEO
(2, 'Alex',  1),
(3, 'Sam',   1),
(4, 'Priya', 2),
(5, 'Chen',  2),
(6, 'Lee',   4),      -- depth 4: Dana > Alex > Priya > Lee
(7, 'Kim',   3);
