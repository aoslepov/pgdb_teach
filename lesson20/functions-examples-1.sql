SELECT current_database();

DROP SCHEMA IF EXISTS pract_functions CASCADE;

CREATE SCHEMA IF NOT EXISTS pract_functions;
SET search_path = pract_functions, public;

-- #1 (слайд 12-13)
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS void
AS
'SELECT NULL;'
LANGUAGE sql;   -- пока используем "чистый" sql

SELECT do_nothing();
SELECT pract_functions.do_nothing();

-- то же, но всместо апострофов - "скобки-доллары"
CREATE OR REPLACE FUNCTION do_nothing()
RETURNS void
AS
$BODY$
    SELECT NULL;
$BODY$
LANGUAGE sql;

-- "скобки-доллары" упрощают работу со строками внутри функции
CREATE OR REPLACE FUNCTION do_text()
RETURNS text
AS
$BODY$
    SELECT 'Hello, world!';
$BODY$
LANGUAGE sql;
-- (!) функция уже не "void" - она возвращает строку (text)

SELECT do_text();
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #2 функция с параметрами
--- простые примеры
CREATE OR REPLACE FUNCTION add(integer, integer)    -- не лучший стиль
RETURNS integer
AS 'SELECT $1 + $2;'
LANGUAGE SQL;

SELECT add (100, 1);

CREATE OR REPLACE FUNCTION add(first_val integer, second_val integer)
RETURNS integer
AS 'SELECT first_val + second_val;'
LANGUAGE SQL;

-- забегая вперед - в ф-циях, написанных на plpgsql возможен этакий компромисный вариант:
DROP FUNCTION IF EXISTS add(integer, integer);

CREATE OR REPLACE FUNCTION add(integer, integer)
RETURNS integer
AS
$BODY$
DECLARE
    first_val   ALIAS FOR $1;
    second_val  ALIAS FOR $2;
BEGIN
    RETURN first_val + second_val;
END
$BODY$
LANGUAGE plpgsql;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #3 OUT-параметры и возвращаемые значения
CREATE OR REPLACE FUNCTION add(IN first_val integer, IN second_val integer, OUT result integer)
RETURNS integer  -- RETURNS не обязателен, но, если есть - должен быть согласован с OUT-параметрами
AS
$BODY$
    SELECT first_val + second_val;
$BODY$
LANGUAGE SQL;

SELECT add (100, 22);

CREATE OR REPLACE FUNCTION arithmetic(IN first_val integer, IN second_val integer, OUT add_result integer, OUT sub_result integer)
RETURNS record
AS
$BODY$
    SELECT first_val + second_val, first_val - second_val;
$BODY$
LANGUAGE SQL;

SELECT arithmetic(101, 1);
SELECT * FROM arithmetic(101, 1);
SELECT sub_result FROM arithmetic(101, 1);

-- То же без использования OUT-параметров
DROP FUNCTION IF EXISTS arithmetic(integer, integer);

CREATE OR REPLACE FUNCTION arithmetic(IN first_val integer, IN second_val integer)
RETURNS record		-- псевдотип, описывает запись без уточнения структуры
AS
$BODY$
    SELECT first_val + second_val, first_val - second_val;
$BODY$
LANGUAGE SQL;

-- столбцы возвращаемой записи не поименованы, что делать?
SELECT arithmetic(101, 1);          -- работает
SELECT * FROM arithmetic(101, 1);   -- не работает!	псевдотип record не задает структуру записи!

SELECT * FROM arithmetic(101, 1) а (add_result integer, sub_result integer);	-- уточняем структуру
SELECT sub_result FROM arithmetic(101, 1) а (add_result integer, sub_result integer);


-- аргументы INOUT
CREATE or replace function add10(inout result1 int)
as
$$
    SELECT result1 + 10
$$ language sql;

SELECT add10(6);

-- в функции на "чистом" SQL может быть несколько запросов, возвращается результат последнего
CREATE TABLE IF NOT EXISTS customer_account
(
    transaction_id      bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    customer_id         integer NOT NULL, -- REFERENCES ...
    transact_value      numeric (10, 2) NOT NULL,
    transact_ts         timestamp with time zone NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION create_transact  (
                                            p_customer_id integer,
                                            p_transact_value numeric    -- модификаторы типа в ппараметрах ф-ций игноринуются
                                            )                           --     numeric (10, 2) ->  numeric
RETURNS record
AS
$BODY$
    INSERT INTO customer_account (customer_id, transact_value) VALUES (p_customer_id, p_transact_value);

    SELECT COUNT(*), SUM(transact_value)
    FROM customer_account
    WHERE customer_id = p_customer_id;
$BODY$
LANGUAGE SQL;

SELECT create_transact (201, 15000.00);
SELECT cnt, balance FROM create_transact (201, 15000.00) ct (cnt bigint, balance numeric);
SELECT cnt, balance FROM create_transact (201, -145.50) ct (cnt bigint, balance numeric);
SELECT cnt, balance FROM create_transact (202, -900.00) ct (cnt bigint, balance numeric);

-- как еще можно вернуть запись?
CREATE TYPE the_balance
AS (cnt bigint, balance numeric);

DROP FUNCTION IF EXISTS create_transact (integer, numeric);

CREATE OR REPLACE FUNCTION create_transact (p_customer_id integer, p_transact_value numeric)
RETURNS the_balance
AS
$BODY$
    INSERT INTO customer_account (customer_id, transact_value) VALUES (p_customer_id, p_transact_value);

    SELECT COUNT(*), SUM(transact_value)
    FROM customer_account
    WHERE customer_id = p_customer_id;
$BODY$
LANGUAGE SQL;

SELECT create_transact (203, 15000.00);
SELECT * FROM create_transact (203, 25000.00);
SELECT balance FROM create_transact (203, 25000.00);



-- табица - тип!
-- При создании таблицы неявно создается одноименный тип
CREATE OR REPLACE FUNCTION get_last_transact ()
RETURNS customer_account
AS
$BODY$
    SELECT * FROM customer_account ORDER BY transaction_id DESC LIMIT 1;
$BODY$
LANGUAGE SQL;

SELECT * FROM get_last_transact ();
-- Команда \dT "прячет" неявно созданные типы, но их можно увидеть непосредственно в таблице pg_type.

SELECT * FROM pg_catalog.pg_type WHERE typname  = 'customer_account';

--======================================================================================================================
/*
    небольшое отступление I:
    значения составных типов данных можно сравнивать между собой,
    например:
*/
DROP TABLE IF EXISTS tab_main;
DROP TABLE IF EXISTS tab_second;

CREATE TABLE tab_main
(
    column_a    integer,
    column_b    double precision,
    column_c    text
);

INSERT INTO tab_main
SELECT ii, ii::double precision / 10., ii::text
FROM generate_series(1, 20) gs (ii);

CREATE TABLE tab_second (LIKE tab_main);

INSERT INTO tab_second
SELECT ii, ii::double precision / 10., ii::text
FROM generate_series(8, 12) gs (ii);

-- запрос
SELECT *
FROM tab_main T1
LEFT JOIN tab_second T2 ON T2 = T1

-- гораздо лаконичнее и читабельнее, чем
SELECT *
FROM tab_main T1
LEFT JOIN tab_second T2 ON T2.column_a = T1.column_a
                       AND T2.column_b = T1.column_b
                       AND T2.column_c = T1.column_c
-- к тому же не "упадет" при изменении структуры таблиц (если, разумеется, сохранится их одинаковость)
--======================================================================================================================


/*
    небольшое отступление II:
    составные типы могут использоваться для определения столбцов таблицы,
    например:
*/
CREATE TABLE tab_over
(
    id          integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    the_value   tab_main
);

INSERT INTO tab_over (the_value) VALUES(ROW(99, 99.99, 'STRING ONE'));          -- используем конструктор составного типа
INSERT INTO tab_over (the_value) VALUES((99, 99.99, 'STRING TWO')::record);     -- используем приведение к типу record
INSERT INTO tab_over (the_value) VALUES((99, 99.99, 'STRING THREE')::tab_main); -- используем приведение к конкретному типу
INSERT INTO tab_over (the_value) VALUES((99, 99.99, 'STRING FOUR'));           -- в простейших случаях можно доверить приведение Postgres'у

-- в этом случае обращаться к элементам составного типа можно так:
SELECT id, (the_value).column_c FROM tab_over;      -- скобки нужны, что бы отличить элемент записи от столбца таблицы
-- или так
SELECT id, (tab_over.the_value).column_c FROM tab_over;
-- или так
SELECT id, (pract_functions.tab_over.the_value).column_c FROM tab_over;

UPDATE tab_over
SET the_value.column_c = 'blank string'
WHERE id > 3;

SELECT ((77, 77.77, 'STRING ZERO')::tab_main).column_c;
--======================================================================================================================

-- функция, возвращающая полноценное отношение, с тем же именем, но с другим набором параметров (пергрузка функций!)
CREATE OR REPLACE FUNCTION get_last_transact (p_limit integer)
RETURNS SETOF customer_account
AS
$BODY$
    SELECT * FROM customer_account ORDER BY transaction_id DESC LIMIT p_limit;
$BODY$
LANGUAGE SQL;

SELECT * FROM get_last_transact (2);
SELECT transaction_id, transact_value FROM get_last_transact (5) WHERE transact_value < 0 ORDER BY transaction_id;
SELECT get_last_transact (2);

--ещё один способ вернуть отношение:
CREATE OR REPLACE FUNCTION get_transacts_by_customer (p_customer_id integer)
RETURNS TABLE (transaction_id bigint, transact_value numeric, transact_ts timestamp with time zone)
AS
$BODY$
    SELECT transaction_id, transact_value, transact_ts FROM customer_account WHERE customer_id = p_customer_id;
$BODY$
LANGUAGE SQL;

SELECT * FROM get_transacts_by_customer (201);

-- можно использовать функции как вычисляемые поля:
CREATE OR REPLACE FUNCTION is_credit(p_balance numeric)
RETURNS boolean
AS
$$
    SELECT p_balance < 0.0
$$ LANGUAGE sql
    IMMUTABLE;

SELECT customer_id, is_credit(SUM(transact_value))
FROM customer_account
GROUP BY customer_id;

-- как сослаться на тип столбца в RETURNS?
CREATE OR REPLACE FUNCTION get_last_transact_time ()
RETURNS customer_account.transact_ts%TYPE
AS
$BODY$
    SELECT MAX(transact_ts) FROM customer_account;
$BODY$
LANGUAGE SQL;

SELECT * FROM get_last_transact_time ();
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #4 значения по умолчанию и именная передача значений параметров
CREATE OR REPLACE FUNCTION arg_sending  (
                                        IN param_1_int integer DEFAULT 0,
                                        IN param_1_real double precision DEFAULT 0.0,
                                        IN param_1_text varchar DEFAULT '',
                                        IN param_2_int integer DEFAULT 1,
                                        IN param_2_real double precision DEFAULT 1.11,
                                        IN param_2_text varchar DEFAULT '1111'
                                        )
RETURNS record
AS
$$
    SELECT param_1_int,  param_1_real, param_1_text, param_2_int,  param_2_real, param_2_text;
$$ LANGUAGE sql;

SELECT arg_sending ();

-- если нужно передать значение для последнего параметра (param_2_text) - придется задавать значения для всех параметров, иначе:
SELECT arg_sending ('2222222');

-- именная передача позволяет обойти эту неприятность
SELECT arg_sending (param_2_text => 'Hello, world!');
SELECT arg_sending (param_2_text => 'Hello, world!', param_1_real => 999.99);
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- #5 Категории изменчивости:
CREATE FUNCTION rand()
RETURNS double precision
AS
$$
    SELECT random();
$$  LANGUAGE sql
    VOLATILE;

SELECT i FROM generate_series(1, 20) gs (i) WHERE rand() > .5;

ALTER FUNCTION rand() STABLE;

SELECT i FROM generate_series(1, 20) gs (i) WHERE rand() > .5;

ALTER FUNCTION rand() IMMUTABLE;

SELECT i FROM generate_series(1, 20) gs (i) WHERE rand() > .5;

EXPLAIN ANALYZE
SELECT i FROM generate_series(1, 20) gs (i) WHERE rand() > .5;

ALTER FUNCTION rand() VOLATILE;
-- -----------------------------------------------------------


-- #5А Категории изменчивости и изоляция
-- В целом использование функций внутри запросов не нарушает установленный уровень изоляции транзакции, но есть аномалии
-- Функции с изменчивостью volatile на уровне изоляции read committed могут приводить к рассогласованию данных 
-- внутри одного запроса.
CREATE TABLE t(n integer);
INSERT INTO t VALUES (1), (2), (3);

CREATE FUNCTION cnt() RETURNS bigint AS $$
SELECT count(*) FROM t;
$$ VOLATILE LANGUAGE SQL;

-- Теперь вызовем ее несколько раз с задержкой, 
-- а в параллельном сеансе вставим в таблицу дополнительную строку.

BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT (SELECT count(*) FROM t), cnt(), pg_sleep(1) FROM generate_series(1,100);

-- в параллельном сеансе
INSERT INTO t VALUES (4);

 count | cnt | pg_sleep 
-------+-----+----------
     3 |   3 | 
     3 |   3 | 
     3 |   4 | 
     3 |   4 | 

-- При изменчивости STABLE или IMMUTABLE, либо использовании более строгих уровней изоляции, такого не происходит.

ALTER FUNCTION cnt() STABLE;
TRUNCATE t;
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT (SELECT count(*) FROM t), cnt(), pg_sleep(1) FROM generate_series(1,4);

-- в 2 окне
INSERT INTO t VALUES (4);

 count | cnt | pg_sleep 
-------+-----+----------
     0 |   0 | 
     0 |   0 | 
     0 |   0 | 
     0 |   0 | 

-- Второй момент связан с видимостью изменений, сделанных собственной транзакцией.
-- Функции с изменчивостью volatile видят все изменения, в том числе сделанные текущим, еще не завершенным оператором SQL.

ALTER FUNCTION cnt() VOLATILE;
TRUNCATE t;
INSERT INTO t SELECT cnt() FROM generate_series(1,5);
SELECT * FROM t;

 n 
---
 0
 1
 2
 3
 4

-- Это верно для любых уровней изоляции.
-- Функции с изменчивостью STABLE или IMMUTABLE видят изменения только уже завершенных операторов.

ALTER FUNCTION cnt() STABLE;
TRUNCATE t;
INSERT INTO t SELECT cnt() FROM generate_series(1,5);
SELECT * FROM t;

 n 
---
 0
 0
 0
 0
 0




-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- #6 SECURITY
DROP SCHEMA IF EXISTS admin CASCADE;
CREATE SCHEMA admin;

CREATE TABLE admin.pwds
(
    username    text PRIMARY KEY,
    pwd         text
);      -- права на таблицу только у владельца ф-ции check_password

INSERT INTO admin.pwds (username, pwd) VALUES ('admin', '1234');

SET search_path = admin;

SHOW search_path;

CREATE OR REPLACE FUNCTION check_password(p_uname TEXT, p_pass TEXT)
RETURNS boolean
AS
$$
    SELECT EXISTS (SELECT 1 FROM pwds WHERE username = p_uname AND pwd = p_pass)
$$ LANGUAGE sql
SECURITY DEFINER;

SELECT check_password ('admin', '1234');

-- действия атакующего:
SELECT check_password ('hacker', '4321');

CREATE TEMP TABLE pwds
(
    username    text PRIMARY KEY,
    pwd         text
);

INSERT INTO pg_temp.pwds (username, pwd) VALUES ('hacker', '4321');
SELECT * FROM pg_temp.pwds

-- Установить безопасный путь поиска: сначала доверенная схема(ы), затем 'pg_temp'.
ALTER FUNCTION check_password(p_uname TEXT, p_pass TEXT) SET search_path = admin, pg_temp;

DROP TABLE IF EXISTS pg_temp.pwds;
DROP SCHEMA IF EXISTS admin CASCADE;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- #7 АНОНИМНЫЙ БЛОК
-- В код PL/pgSQL можно встраивать команды SQL. Наверное, наиболее часто используемый вариант - 
-- команда SELECT, возвращающая одну строку. Пример, который не получилось бы выполнить 
-- с помощью выражения с подзапросом (потому что возвращаются сразу два значения):
CREATE TABLE t(id integer, code text);
INSERT INTO t VALUES (1, 'Раз'), (2, 'Два');

DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO r FROM t WHERE id = 1;
    RAISE NOTICE '%', r;
END;
$$;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #8 про кортежи
CREATE TABLE TABLE1 (f1 text, f3 text);
CREATE TABLE TABLE2 (f1 text, f3 text);
INSERT INTO TABLE1 VALUES(1,2),(3,4);
INSERT INTO TABLE2 VALUES(1,6),(3,8);

CREATE or replace FUNCTION merge_fields(t_row TABLE1) RETURNS text AS $$
DECLARE
	t2_row TABLE2%ROWTYPE;
BEGIN
	SELECT * INTO t2_row FROM TABLE2 WHERE TABLE2.f1=t_row.f1;
	RETURN t_row.f1 || t2_row.f3;
END;
$$ LANGUAGE plpgsql;

SELECT merge_fields(t.*) FROM TABLE1 t;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #9 изменение структуры record на лету
CREATE FUNCTION record_struct()
RETURNS void
AS
$$
DECLARE
    r record;
BEGIN
    r = ROW(2, 'text!');
    RAISE NOTICE '%', r;

    r = ROW(now()::date, 777, 'text!');
    RAISE NOTICE '%', r;
END
$$ LANGUAGE plpgsql;

SELECT record_struct();
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- #10 два способа задания аргументов не явдяются полностью эквивалентными
CREATE OR REPLACE FUNCTION add(first_val integer, second_val integer)
RETURNS integer
AS
$BODY$
BEGIN
    RETURN add.first_val + add.second_val;  -- допустимо
END
$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add(integer, integer)
RETURNS integer
AS
$BODY$
DECLARE
    first_val   ALIAS FOR $1;
    second_val  ALIAS FOR $2;
BEGIN
    RETURN add.first_val + add.second_val;  -- недопустимо
END
$BODY$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS add(integer, integer);

CREATE OR REPLACE FUNCTION add(integer, integer)
RETURNS integer
AS
$BODY$
<<main_block>>
DECLARE
    first_val   ALIAS FOR $1;
    second_val  ALIAS FOR $2;
BEGIN
    RETURN main_block.first_val + main_block.second_val;  -- допустимо
END
$BODY$
LANGUAGE plpgsql;

SELECT add(20, 30);
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- #11 RETURN QUERY
CREATE FUNCTION extended_sales(p_itemno int)
RETURNS TABLE(quantity int, total numeric)
AS
$$
BEGIN
	RETURN QUERY
	SELECT s.quantity, s.quantity * s.price FROM sales s WHERE s.itemno = p_itemno;
END;
$$ LANGUAGE plpgsql;	   -- если бы использовался SQL – “RETURN QUERY” не потребовался бы
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




-- #12 STRICT
-- * STRICT - ровно 1 значение. в варианте SELECT в зависимости от order by будет возвращена 1 запись
-- если order by нет - результат непредсказуем, какая строчка вернется
-- в варианте insert, UPDATE - если больше 1 записи - будет ошибка

DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO STRICT r FROM t;
    RAISE NOTICE '%', r;
END;
$$;

DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO STRICT r FROM t WHERE id = 1;
    RAISE NOTICE '%', r;
END;
$$;

-- вариант - использовать не одну переменную составного типа, а несколько скалярных переменных для каждого поля
-- как думаете сработает?
DO $$
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT id, code INTO id, code FROM t WHERE id = id;
    RAISE NOTICE '%, %', id, code;
END;
$$;
-- Не получится из-за неоднозначности в SELECT: id может означать и имя столбца, и имя переменной

-- Варианты устранения неоднозначностей
-- Есть несколько подходов к устранению неоднозначностей.

-- Первый состоит в том, чтобы неоднозначностей не допускать. Для этого к переменным добавляют префикс, 
-- который обычно выбирается в зависимости от "класса" переменной, например:

DO $$
DECLARE
    l_id   integer := 1;
    l_code text;
BEGIN
    SELECT id, code INTO l_id, l_code FROM t WHERE id = l_id;
    RAISE NOTICE '%, %', l_id, l_code;
END;
$$;

-- Второй способ состоит в использовании квалифицированных имен - к имени объекта через точку 
-- дописывается уточняющий квалификатор:

DO $$
<<local>>
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT t.id, t.code INTO local.id, local.code FROM t WHERE t.id = local.id;
    RAISE NOTICE '%, %', id, code;
END;
$$;



-- Третий вариант - установить приоритет переменных над столбцами или наоборот, столбцов над переменными. 
-- За это отвечает конфигурационный параметр plpgsql.variable_conflict.

-- Здесь устанавливается приоритет переменных, поэтому достаточно квалифицировать только столбцы таблицы:

SET plpgsql.variable_conflict = use_variable;

DO $$
DECLARE
    id   integer := 1;
    code text;
BEGIN
    SELECT t.id, t.code INTO id, code FROM t WHERE t.id = id;
    RAISE NOTICE '%, %', id, code;
END;
$$;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #13 динамический SQL
drop flights_count;
CREATE or replace FUNCTION flights_count(airport text) RETURNS text AS $$
declare
 c text;
BEGIN
    execute 'SELECT count(f.flight_no) FROM bookings.flights f WHERE f.departure_airport = $1;'
    INTO c
   	using airport;
  	return c;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM flights_count('DME');
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #14 управляющие конструкции
CREATE FUNCTION fmt_out_2 (IN phone text, OUT code text, OUT num text)
-- RETURNS можно не писать, предполагается RETURNS record
AS $$
BEGIN
    IF phone ~ '^[0-9]*$' AND length(phone) = 10 THEN
        code := substr(phone,1,3);
        num  := substr(phone,4);
    ELSE
        code := NULL;
        num  := NULL;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Условный оператор CASE (анонимный блок)
DO $$
DECLARE
    code text := (fmt_out_2('8122128506')).code; -- сразу обращаемся к возвращаемой переменной из функции через .
BEGIN
    CASE code
    WHEN '495', '499' THEN
        RAISE NOTICE '% - Москва', code;
    WHEN '812' THEN
        RAISE NOTICE '% - Санкт-Петербург', code;
    WHEN '384' THEN
        RAISE NOTICE '% - Кемеровская область', code;
    ELSE
        RAISE NOTICE '% - Прочие', code;
    END CASE;
END;
$$;



-- Пример использования RETURN NEXT:
CREATE TABLE foo (fooid INT, foosubid INT, fooname TEXT);
INSERT INTO foo VALUES (1, 2, 'three');
INSERT INTO foo VALUES (4, 5, 'six');

CREATE OR REPLACE FUNCTION get_all_foo() RETURNS SETOF foo AS
$BODY$
DECLARE
    r foo%rowtype;
BEGIN
    FOR r IN
        SELECT * FROM foo WHERE fooid > 0
    LOOP
        -- здесь возможна обработка данных
        r.fooid := r.fooid + 10;
        RETURN NEXT r; -- возвращается текущая строка запроса
    END LOOP;
    RETURN;
END
$BODY$
LANGUAGE plpgsql;

SELECT * FROM get_all_foo();
SELECT * FROM foo;

--Пример использования RETURN QUERY:
CREATE or replace FUNCTION get_available_flightid(date) RETURNS SETOF integer AS
$BODY$
BEGIN
    RETURN QUERY SELECT flight_id
                   FROM flights
                  WHERE cast(actual_departure as date) >= $1
                    AND cast(actual_departure as date) < ($1 + 1);

    RETURN QUERY SELECT flight_id
                   FROM flights
                  WHERE cast(actual_departure as date) >= $1
                    AND cast(actual_departure as date) < ($1 + 1);
    -- Так как выполнение ещё не закончено, можно проверить, были ли возвращены строки,
    -- и если нет, выдать исключение.
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Нет рейсов на дату: %.', $1;
    END IF;

    RETURN;
 END
$BODY$
LANGUAGE plpgsql
set search_path to bookings, public;

SELECT get_available_flightid('21161010');


-- Возвращает доступные рейсы либо вызывает исключение, если таковых нет.
SELECT * FROM get_available_flightid('2016-09-14');
SELECT * FROM get_available_flightid(cast('2016-09-14' as date));
SELECT * FROM get_available_flightid(CURRENT_DATE);
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #15 полиморфизм
CREATE FUNCTION biggest (p1 anyelement, p2 anyelement)
RETURNS anyelement
AS
$$
        SELECT CASE WHEN p1 > p2 THEN P1 ELSE P2 END;
$$ IMMUTABLE
LANGUAGE sql;

SELECT biggest (99.6, 4.1);
SELECT biggest (99.6, 4);       -- не работает, почему?
SELECT biggest ('3', '6');      -- не работает, почему? (*: так могут быть представлены не только строки, но и json!)
-- необходимо что бы для используемого типа был определён оператор ">"

-- не самое корректное поведение - 
SELECT biggest (NULL, 4); 
SELECT biggest (4, NULL);
-- как исправить?



CREATE OR REPLACE FUNCTION biggest (p1 anyelement, p2 anyelement, p3 anyelement DEFAULT NULL)
RETURNS anyelement
AS
$$
    SELECT CASE
               WHEN p3 IS NULL THEN x
               ELSE
                   CASE WHEN x > p3 THEN x ELSE p3 END
           END
    FROM (
           SELECT CASE WHEN p1 > p2 THEN p1 ELSE p2 END
         ) choise(x);
$$ IMMUTABLE
LANGUAGE sql;

SELECT biggest (1, 4);  -- не работает, почему?
DROP FUNCTION IF EXISTS biggest(anyelement, anyelement);
SELECT biggest (4, 1, 99);
SELECT biggest (1, 7, -9);
--------------------------------------------------------------------------------------------
-- напишем такую же ф-цию для произвольного к-ва integer-значенй
DROP FUNCTION IF EXISTS biggest (integer[]);

CREATE OR REPLACE FUNCTION biggest(VARIADIC p_arr integer[])
RETURNS integer
AS
$$
DECLARE
    i           integer;
    max_of_ar    integer;
BEGIN
    FOREACH i IN ARRAY p_arr LOOP
        IF i IS NOT NULL AND (max_of_ar IS NULL OR i > max_of_ar) THEN
            max_of_ar = i;
        END IF;
    END LOOP;
    RETURN max_of_ar;
END;
$$ IMMUTABLE
LANGUAGE plpgsql;

SELECT biggest (1, 55, 43, 1, 2, 99, 101, 6, 3);
---------------------------------------------------------------------------------------------

-- Полиморфный вариант с VARIADIC, пробуем:  
CREATE OR REPLACE FUNCTION biggest(VARIADIC p_arr anyarray)
RETURNS anyelement
AS
$$
DECLARE
    x           anyelement;     -- так нельзя! anyelement ддопустим только в опредлении параметров ф-ции и/или выозвращаемых значений,
    max_of_ar    anyelement;     -- но не переменных. Переменные должны иметь реальный тип!         
BEGIN
    FOREACH x IN ARRAY p_arr
    LOOP
        IF x IS NOT NULL AND (max_of_ar IS NULL OR x > max_of_ar) THEN
            max_of_ar := x;
        END IF;
    END LOOP;
    
    RETURN max_of_ar;
END;
$$ IMMUTABLE
LANGUAGE plpgsql;

--- меняем определение:
DROP FUNCTION IF EXISTS biggest(anyarray);

CREATE OR REPLACE FUNCTION biggest(VARIADIC p_arr anyarray, OUT max_of_ar anyelement)     -- "RETURNS" убираем!
AS
$$
DECLARE
-- как поступить с x
	--x           anyelement;
    x   max_of_ar%TYPE;         -- см. п. 42.3.3. Наследование типов данных
BEGIN
    FOREACH x IN ARRAY p_arr
    LOOP
        IF x IS NOT NULL AND (max_of_ar IS NULL OR x > max_of_ar)
        THEN
            max_of_ar := x;
        END IF;
    END LOOP;
    
    -- RETURN max_of_ar;        тоже убираем
END;
$$ IMMUTABLE
LANGUAGE plpgsql;

SELECT biggest (1, 55, 43, 1);
SELECT biggest (1., 55., 43::numeric, 1.11);
SELECT biggest ('one', 'TWO', 'three', 'Four');
SELECT biggest ('one'::varchar, 'TWO'::varchar, 'three'::varchar, 'Four'::varchar);
---------------------------------------------------------------------------------------------
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #16
-- создадим процедуру, возвращающую значение
DROP PROCEDURE IF EXISTS triple;
CREATE PROCEDURE triple(INOUT x int)
LANGUAGE plpgsql
AS $$
BEGIN
    x := x * 3;
END;
$$;

CALL triple(4);

--вызов анонимной процедуры dBeaver  в окне output - ctrl+shift+o
DO $$
DECLARE myvar int := 5;
BEGIN
  CALL triple(myvar);
  RAISE NOTICE 'myvar = %', myvar;  -- выводится 15
end $$;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- #17 EXCEPTIONS
DROP TABLE IF EXISTS t;
CREATE TABLE t(id integer);

DO
$$
DECLARE
    n integer;
BEGIN
    INSERT INTO t(id) VALUES (3);
    SELECT id INTO STRICT n FROM t;
    RAISE NOTICE 'Оператор SELECT INTO выполнился';
EXCEPTION
    WHEN no_data_found THEN
        RAISE NOTICE 'Нет данных';
    WHEN too_many_rows THEN
        RAISE NOTICE 'Слишком много данных';
        RAISE NOTICE 'Строк в таблице: %', (SELECT count(*) FROM t);
END;
$$;

DO $$
DECLARE
    n integer := 1 / 0; -- ошибка в этом месте не перехватывается
BEGIN
    RAISE NOTICE 'OK!';
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'division by zero';
	-- WHEN OTHERS THEN ...
END;
$$;
-- имена и коды ошибок - приложение А
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- #18 SQLSTATE, SQLERRM, GET STACKED DIAGNOSTICS, GET DIAGNOSTICS
DO $$
DECLARE
    n integer;
BEGIN
    RAISE NOTICE 'OK!';
    n = 1/0;
EXCEPTION
    WHEN OTHERS THEN
        RAISE '->  %, ->  %', SQLSTATE, SQLERRM;
END;
$$;

DO
$$
DECLARE
        v_message       text;
        v_detail        text;
        v_hint          text;
        v_ret_sqlstate  text;
		v_context		text;
BEGIN
        RAISE SQLSTATE 'ERR99'
        USING
                message = 'Ошибка!',
                detail  = 'Ощиблись при выполнении функции!',
                hint = 'Обратитесь в службу поддержки';

        RAISE NOTICE 'OK?';
		
        EXCEPTION
                WHEN OTHERS THEN
                        GET STACKED DIAGNOSTICS
                                v_message = message_text,
                                v_detail = pg_exception_detail,
                                v_hint = pg_exception_hint,
                                v_ret_sqlstate = returned_sqlstate,
								v_context = pg_context;
                RAISE NOTICE E'\nmessage = %\ndetail = %\nhint = %\n rsqlstate = %\ncontext = %', v_message, v_detail, v_hint, v_ret_sqlstate, v_context;
END;
$$;
-- см. 42.6.8.1
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




