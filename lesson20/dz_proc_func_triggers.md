## Домашнее задание: Триггеры, поддержка заполнения витрин

### Цель: Создать триггер для поддержки витрины в актуальном состоянии.


> Описание/Пошаговая инструкция выполнения домашнего задания:
> Скрипт и развернутое описание задачи – в ЛК (файл hw_triggers.sql) или по ссылке: https://disk.yandex.ru/d/l70AvknAepIJXQ
> В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).
> Есть запрос для генерации отчета – сумма продаж по каждому товару.
> БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.
> Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)
> Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE
> Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
> Подсказка: В реальной жизни возможны изменения цен.



*Создаём таблицы и запролняем данные*
```
DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path = pract_functions, public;

-- товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);
	


-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);


SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;



CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);
```


*Перед добавлением процедур добавляем текущие данные на ветрину*

```
insert into good_sum_mart (good_name,sum_sale)
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

select * from good_sum_mart;
--
Автомобиль Ferrari FXX K	185000000.01
Спички хозайственные	65.50
```


*Cоздаём триггерную процедуру на добавляение записей в таблицу sales*
```

CREATE OR REPLACE FUNCTION pract_functions.add_sales() RETURNS TRIGGER AS
$BODY$
begin

	-- перед добавлением продажи проверяем есть ли данная позиция на ветрине
	-- при отсутсвии добавляем позицию с нулевой ценой
	if  not exists (select 1 from good_sum_mart GM inner join goods G on G.good_name=GM.good_name where G.goods_id=new.good_id)
	then 
	INSERT into good_sum_mart(good_name,sum_sale) select good_name,0 from goods where goods_id=new.good_id;
	end if;

	-- пересчёт цен для данной позиции на ветрине
	update good_sum_mart set sum_sale=(SELECT sum(G.good_price * S.sales_qty) FROM goods G INNER JOIN sales S ON S.good_id = G.goods_id where G.goods_id = new.good_id)
	where good_name = (select GM.good_name from good_sum_mart GM inner join goods G on G.good_name=GM.good_name where G.goods_id=new.good_id)	;
	RETURN new;   
END;
$BODY$
language plpgsql;

-- триггер будет срабатывать после вставки в таблицу sales
CREATE TRIGGER triger_add_sales after INSERT ON sales FOR EACH row EXECUTE PROCEDURE pract_functions.add_sales();

```


*Триггерная функция для обновления наименования товара в таблицы goods*
```
-- вызывается перед обновлением таблицы и обновляет имя товара на ветрине

CREATE OR REPLACE FUNCTION pract_functions.update_name_goods() RETURNS TRIGGER AS
$BODY$
begin
	-- проверяем существование товара на ветрине
	if  exists (select 1 from good_sum_mart GM inner join goods G on G.good_name=GM.good_name where G.goods_id=old.goods_id)
	then 

	-- обновляем имя товара на ветрине
	update good_sum_mart set good_name = new.good_name where good_name in (select GM.good_name from good_sum_mart GM inner join goods G on G.good_name=GM.good_name where G.goods_id=old.goods_id);	

	end if;

	RETURN new;   
END;
$BODY$
language plpgsql;


CREATE TRIGGER triger_update_name_goods BEFORE UPDATE ON goods FOR EACH row EXECUTE PROCEDURE pract_functions.update_name_goods();
```


*Триггерная функция для пересчёта цен на ветрине*
```
-- вызывается при обновлении товара после апдейта таблицы goods
CREATE OR REPLACE FUNCTION pract_functions.update_price_goods() RETURNS TRIGGER AS
$BODY$
begin
	-- проверяем существование товара на ветрине
	if  exists (select 1 from good_sum_mart GM inner join goods G on G.good_name=GM.good_name where G.goods_id=old.goods_id)
	then 

	-- пересчитываем цены на товар на ветрине
	update good_sum_mart set sum_sale=(SELECT sum(G.good_price * S.sales_qty) FROM goods G INNER JOIN sales S ON S.good_id = G.goods_id where G.good_name = new.good_name)
	where good_name=new.good_name;
	end if;

	RETURN new;   
END;
$BODY$
language plpgsql;


CREATE TRIGGER triger_update_price_goods AFTER UPDATE ON goods FOR EACH row EXECUTE PROCEDURE pract_functions.update_price_goods();
```





*Смотрим на созданные процедуры и триггеры*

```

select routine_name from information_schema.routines where routine_type = 'FUNCTION' and routine_schema = 'pract_functions';
--
add_sales
update_name_goods
update_price_goods

   
SELECT  event_object_table AS table_name ,trigger_name FROM information_schema.triggers  GROUP BY table_name , trigger_name ORDER BY table_name ,trigger_name ;   
--
goods	triger_update_name_goods
goods	triger_update_price_goods
sales	triger_add_sales

```


**Проверяем работу процедур/триггеров**
   
   
*1) добавление товара*
```

-- добавим товар и продажи по товару
INSERT INTO goods (goods_id, good_name, good_price) VALUES 	(3, 'кофе', 500);
INSERT INTO sales (good_id, sales_qty) VALUES (3, 2);

select * from goods;
--
1	Спички хозайственные	0.50
2	Автомобиль Ferrari FXX K	185000000.01
3	кофе	500.00

select * from good_sum_mart;
--
Автомобиль Ferrari FXX K	185000000.01
Спички хозайственные	65.50
кофе	1000.00
```


*2) добавление нескольких продаж*
```
INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (2, 1), (3, 5);
select * from good_sum_mart;
--
Спички хозайственные	70.50
Автомобиль Ferrari FXX K	370000000.02
кофе	3500.00

SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
--
Автомобиль Ferrari FXX K	370000000.02
Спички хозайственные	70.50
кофе	3500.00
```


*3) обновление наименования товара и его цену*
```

update goods set good_name = 'кофе в зёрнах', good_price=1000 where goods_id=3;
select * from goods;
--
1	Спички хозайственные	0.50
2	Автомобиль Ferrari FXX K	185000000.01
3	кофе в зёрнах	1000.00


-- произошло обновление как самого товара, так и пересчёт цен
select * from good_sum_mart;
--
Спички хозайственные	70.50
Автомобиль Ferrari FXX K	370000000.02
кофе в зёрнах	7000.00


-- ещё раз проверяем корректность работы ветрине на запросе
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
--
Автомобиль Ferrari FXX K	370000000.02
Спички хозайственные	70.50
кофе в зёрнах	7000.00
```





