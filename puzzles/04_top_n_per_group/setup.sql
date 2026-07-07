CREATE OR REPLACE TABLE sales (
    category VARCHAR NOT NULL,
    product  VARCHAR NOT NULL,
    revenue  INTEGER NOT NULL
);

INSERT INTO sales VALUES
-- electronics: laptop and phone TIE for first place
('electronics', 'laptop', 5000),
('electronics', 'phone',  5000),
('electronics', 'tablet', 3000),
('electronics', 'watch',  1000),
-- grocery: no ties
('grocery', 'milk',  300),
('grocery', 'bread', 200),
('grocery', 'eggs',  100);
