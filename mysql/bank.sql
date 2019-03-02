SELECT VERSION(), USER(), DATABASE(), NOW();

SELECT DISTINCT cust_id FROM account;

SELECT emp_id, 'ACTIVE', emp_id * 2, UPPER(fname) FROM employee;

-- псевдонимы
SELECT emp_id, 'ACTIVE' status, emp_id * 3.14159 empid_x_pi,
    UPPER(lname) last_name_upper FROM employee;

SELECT emp_id AS id, 'ACTIVE' AS status FROM employee;

-- подзапросы
SELECT t.open_date
FROM (SELECT * FROM account WHERE avail_balance > 5000) AS t;

SELECT t.emp_id, t.fname, t.lname
FROM (SELECT emp_id, fname, lname, start_date, title FROM employee) t;

-- Представления (виртуальные таблицы)
CREATE VIEW employee_vw AS SELECT emp_id, fname, lname,
    YEAR(start_date) start_year FROM employee;
SELECT emp_id, start_year FROM employee_vw;
DROP VIEW employee_vw;





/*-------------------------------------------------------------------------
                                 ФИЛЬТРАЦИЯ
--------------------------------------------------------------------------- */
SELECT emp_id, fname, lname, start_date, title FROM employee
WHERE title = 'Head Teller' AND start_date > '2002-01-01';

SELECT emp_id, fname, lname, start_date, title FROM employee
WHERE (title = 'Head Teller' AND start_date > '2002-01-01') OR
    (title = 'Teller' AND start_date > '2003-01-01');

-- поиск по длине имени
SELECT emp_id, fname, lname FROM employee WHERE LENGTH(lname) = 5;
-- поиск по первой букве
SELECT emp_id, fname, lname FROM employee WHERE LEFT(lname, 1) = 'T';

-- ORDER BY
SELECT emp_id, title, start_date, fname, lname FROM employee ORDER BY 2, 5;
SELECT emp_id, title, start_date, fname, lname FROM employee ORDER BY title, lname;
SELECT * FROM account ORDER BY open_date DESC;
-- сортировка по последним трем разрядам fed_id
SELECT cust_id, cust_type_cd, city, state, fed_id FROM customer
ORDER BY RIGHT(fed_id, 3);

-- LIMIT
SELECT * FROM account LIMIT 5;  --count
SELECT * FROM account LIMIT 8, 3; --offset, count

-- BETWEEN
SELECT account_id, product_cd, cust_id, avail_balance FROM account
WHERE avail_balance BETWEEN 3000 AND 5000;

SELECT * FROM account WHERE open_date BETWEEN '2002-01-01' AND '2002-12-31';

-- IN
SELECT account_id, product_cd, cust_id, avail_balance FROM account
WHERE product_cd IN ('CHK','SAV','CD','MM');
-- в подзапросе должен быть 1 столбец
SELECT account_id, product_cd, cust_id, avail_balance FROM account
WHERE product_cd IN (SELECT product_cd FROM product WHERE product_type_cd = 'ACCOUNT');

-- NOT IN
SELECT account_id, product_cd, cust_id, avail_balance FROM account
WHERE product_cd NOT IN ('CHK','SAV','CD','MM');

-- LIKE (поиск по маске)
SELECT emp_id, fname, lname FROM employee 

WHERE lname LIKE 'F%' OR lname LIKE 'G%';
SELECT lname FROM employee WHERE lname LIKE '_a%e%';

SELECT cust_id, fed_id FROM customer
WHERE fed_id LIKE '___-__-____';

-- REGEXP (поиск по регулярному выражению) (в MySQL POSIX)
SELECT emp_id, fname, lname FROM employee WHERE lname REGEXP '^[FG]';

SELECT emp_id, fname, lname FROM employee 
WHERE lname REGEXP 'ing$' OR LOWER(lname) REGEXP '^p.+an$';

--NULL
SELECT * FROM employee WHERE superior_emp_id IS NULL;
SELECT * FROM employee WHERE superior_emp_id IS NOT NULL;





/*-------------------------------------------------------------------------
                          СОЕДИНЕНИЕ JOIN
--------------------------------------------------------------------------- */
-- CROSS JOIN (декартово произведение)
SELECT e.fname, e.lname, d.name FROM employee e JOIN department d;

-- INNER JOIN
SELECT e.fname, e.lname, d.name
FROM employee AS e
INNER JOIN department AS d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-- старый синтаксиc
SELECT e.fname, e.lname, d.name 
FROM employee e
INNER JOIN department d WHERE e.dept_id = d.dept_id;

-- USING
SELECT e.fname, e.lname, d.name 
FROM employee e 
INNER JOIN department d USING (dept_id);

-- соединение 3 таблиц
SELECT e.fname, e.lname, d.name department, b.name branch, b.city
FROM employee e
INNER JOIN department d ON e.dept_id = d.dept_id
INNER JOIN branch b ON e.assigned_branch_id = b.branch_id
ORDER BY e.emp_id;


-- Запрос, по которому возвращаются все счета, открытые
-- операционистами (нанятыми до 2003-года), в настоящее время приписанными
-- к отделению Woburn (1 вариант).
SELECT a.account_id, a.cust_id, a.open_date, a.product_cd
FROM account a 
INNER JOIN employee e ON a.open_emp_id = e.emp_id
INNER JOIN branch b ON e.assigned_branch_id = b.branch_id
WHERE e.start_date <= '2003-01-01'
    AND (e.title = 'Teller' OR e.title = 'Head Teller')
    AND b.name = 'Woburn Branch';


-- Запрос, возвращающий работника открывшего счет, ID счета и идентификационный номер
-- федерального налога для всех бизнес-счетов.
SELECT a.account_id, c.fed_id, e.fname, e.lname
FROM customer c 
INNER JOIN account a ON a.cust_id = c.cust_id
INNER JOIN employee e ON a.open_emp_id = e.emp_id
WHERE c.cust_type_cd = 'B';


-- Запрос, по которому возвращаются все счета, открытые опытными
-- операционистами (нанятыми до 2003-года), в настоящее время приписанными
-- к отделению Woburn (2 вариант).
SELECT a.account_id, a.cust_id, a.open_date, a.product_cd
FROM account a 
INNER JOIN (SELECT emp_id, assigned_branch_id
            FROM employee
            WHERE start_date <= '2003-01-01'
                AND (title = 'Teller' OR title = 'Head Teller')) e
ON a.open_emp_id = e.emp_id
INNER JOIN (SELECT branch_id
            FROM branch
            WHERE name = 'Woburn Branch') b
ON e.assigned_branch_id = b.branch_id;


--------------- ПОВТОРНОЕ ВКЛЮЧЕНИЕ ОДНОЙ ТАБЛИЦЫ С РАЗНЫМИ ПСЕВДОНИМАМИ---------
-- Этот запрос показывает, кто открыл каждый текущий счет,
-- в каком от делении это произошло и к какому отделению приписан в настоящее
-- время сотрудник, открывший счет.
SELECT a.account_id, e.emp_id, b_a.name open_branch, b_e.name emp_branch
FROM account AS a
INNER JOIN branch AS b_a ON a.open_branch_id = b_a.branch_id
INNER JOIN employee AS e ON a.open_emp_id = e.emp_id
INNER JOIN branch  AS b_e ON e.assigned_branch_id = b_e.branch_id
WHERE a.product_cd = 'CHK';


-------------------- РЕКУРСИВНОЕ ВКЛЮЧЕНИЕ ТАБЛИЦЫ ------------------------------
-- У работника есть начальник (другой работник), ключ superior_emp_id является
-- внешним ключом, который ссылается на эту же таблицу к первичному ключу, id работника.
SELECT e.fname, e.lname, chief.fname chief_fname, chief.lname chief_lname
FROM employee e 
INNER JOIN employee chief ON e.superior_emp_id = chief.emp_id;


---------------NO-EUIV-JOINS:
SELECT e.emp_id, e.fname, e.lname, e.start_date
FROM employee e 
INNER JOIN product p ON e.start_date >= p.date_offered
    AND e.start_date <= p.date_retired;


-- Управляющий операциями решил провести шахматный турнир между всеми
-- операционистами банка. Требуется создать список всех пар игроков.
SELECT e1.fname, e1.lname, 'VS' vs, e2.fname, e2.lname
FROM employee e1 
INNER JOIN employee e2 ON e1.emp_id < e2.emp_id
WHERE e1.title = 'Teller' AND e2.title = 'Teller';





/*-------------------------------------------------------------------------
                      ОПЕРАЦИИ С МНОЖЕСТВАМИ
--------------------------------------------------------------------------- */
-- UNION (без дублей)
SELECT 1 num, 'abc' str UNION SELECT 9 num, 'xyz' str;

SELECT cust_id, lname name FROM individual
UNION
SELECT cust_id, name FROM business;

-- UNION ALL (с дублями)
SELECT cust_id, lname name FROM individual
UNION ALL
SELECT cust_id, name FROM business
UNION ALL
SELECT cust_id, name FROM business;


-- Найти работников которые работают отделе 2 (Woburn Branch),
-- и работников которые открывали счета в этом отделе.
SELECT emp_id FROM employee
WHERE assigned_branch_id = 2
    AND (title = 'Teller' OR title = 'Head Teller')
UNION
SELECT open_emp_id FROM account
WHERE open_branch_id = 2;


-- INTSERSECT (ALL) (нет в MySQL)
-- Найти работников которые открывали счета в отделе 2 и сейчас работают там же.
SELECT emp_id FROM employee
WHERE assigned_branch_id = 2
    AND (title = 'Teller' OR title = 'Head Teller')
INTERSECT
SELECT DISTINCT open_emp_id FROM account
WHERE open_branch_id = 2;


-- EXCEPT (ALL) (нет в MySQL)
-- Найти работников которые сейчас в отделе 2, и никогда не открывали счета в этом отделе.
SELECT emp_id FROM employee
WHERE assigned_branch_id = 2
    AND (title = 'Teller' OR title = 'Head Teller')
EXCEPT
SELECT DISTINCT open_emp_id FROM account
WHERE open_branch_id = 2;







-------------7 ГЛАВА------------------
SELECT LENGTH(char_fld) char_length,
LENGTH(vchar_fld) varchar_length,
LENGTH(text_fld) text_length
FROM string_tbl;



SELECT CONCAT(fname, ' ', lname, ' has been a ',
    title, ' since ', start_date) emp_narrative
FROM employee
WHERE title = 'Teller' OR title = 'Head Teller';


SELECT POW(2, 10) kilobyte, POW(2, 20) megabyte, POW(2, 30) gigabyte, POW(2, 40) terabyte;


SELECT ROUND(72.0909, 1), ROUND(72.0909, 2), ROUND(72.0909, 3);
SELECT TRUNCATE(72.0909, 1), TRUNCATE(72.0909, 2), TRUNCATE(72.0909, 3);
SELECT ROUND(155, -1), TRUNCATE(155, -1), ROUND(155, -2), TRUNCATE(155, -2);

SELECT account_id, SIGN(avail_balance), ABS(avail_balance)
FROM account;


SELECT CAST('2005-03-27' AS DATE) date_field,
CAST('108:17:57' AS TIME) time_field;


INSERT INTO ch (date) 
VALUES (STR_TO_DATE('March 27, 2005', '%M %d, %Y'));

SELECT CURRENT_DATE(), CURRENT_TIME(), CURRENT_TIMESTAMP(), NOW();

SELECT DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY);






-------------8 ГЛАВА------------------
SELECT open_emp_id FROM account
GROUP BY open_emp_id;

SELECT open_emp_id, COUNT(*) how_many FROM account
GROUP BY open_emp_id;



SELECT open_emp_id, how_many
FROM (SELECT open_emp_id, COUNT(*) how_many FROM account GROUP BY open_emp_id) AS t
WHERE how_many > 4;


SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
HAVING how_many > 4;



SELECT MAX(avail_balance) max_balance, MIN(avail_balance) min_balance,
    AVG(avail_balance) avg_balance, SUM(avail_balance) tot_balance,
    COUNT(*) num_accounts
FROM account
WHERE product_cd = 'CHK';


SELECT product_cd, MAX(avail_balance) max_balance, MIN(avail_balance) min_balance,
    AVG(avail_balance) avg_balance, SUM(avail_balance) tot_balance, COUNT(*) num_accts
FROM account
GROUP BY product_cd;


-- NULL значения не считает
SELECT count(distinct open_emp_id) FROM account;

SELECT max(pending_balance - avail_balance) max_uncleared FROM account;

SELECT diff FROM (SELECT (pending_balance - avail_balance) diff from account) t
where t.diff > 0;

----:
SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
GROUP BY product_cd;


SELECT product_cd, open_branch_id, SUM(avail_balance) tot_balance
FROM account
GROUP BY product_cd, open_branch_id;


SELECT YEAR(start_date) year, COUNT(*) how_many
FROM employee
GROUP BY YEAR(start_date);


SELECT product_cd, open_branch_id,
SUM(avail_balance) tot_balance
FROM account
GROUP BY product_cd  , open_branch_id WITH ROLLUP;


SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
WHERE status = 'ACTIVE'
GROUP BY product_cd
HAVING SUM(avail_balance) >= 10000;


SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
WHERE status = 'ACTIVE'
GROUP BY product_cd
HAVING MIN(avail_balance) >= 1000
    AND MAX(avail_balance) <= 10000;