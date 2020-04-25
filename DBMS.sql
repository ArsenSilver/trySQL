 SELECT *
 WHERE NOT EXISTS
 (
 SELECT replace('correct all syntax errors', 'Correct All', 'there is no')
 WHERE ALL( SELECT 1) = 1 
 	OR (1,2) = (SELECT 1,2) --any()
)
 CREATE TABLE cars
(
    id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, --increment may cause harm in table relationship because it incs even in fault queries
    model VARCHAR(100) NOT NULL,
    description TEXT,
    on_testdrive BOOL DEFAULT 1,
    selling_start DATETIME(0), -- 3 для миллисекунд, 6 дня микросекунд 
	UNIQUE KEY model(model),
	INDEX date_index(selling_start),
	FULLTEXT INDEX desc_index(description)
);

ALTER TABLE cars
	ADD COLUMN amount NOT NULL DEFAULT 0,--rare types ENUM('','') or SET('','')(which is not allowed is 1st normal form)  FIND_IN_SET() 
	DROP PRIMARY KEY,
	MODIFY id BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT AFTER selling_start, 
	CHANGE on_testdrive on_TD BOOL DEFAULT 1,
	RENAME TABLE cars TO cars_models;


CREATE TRIGGER update_datetime
	before INSERT 
	ON 
	cars_models
	for each row 
	BEGIN
		SET NEW.selling_start = CURRENT_TIMESTAMP;
	   		IF NEW.amount < 0 THEN
           		SET NEW.amount = 0;
	   		ELSEIF NEW.amount > 100 THEN
          		SET NEW.amount = 100;
           	END IF;
	END;

INSERT INTO cars_models (model, description) 
 VALUES 
 	("honda sol", "desc honda car 1"),
 	("lexus T", "desc lexus 1"),
 	("lada 2110", "desc lada 1");

UPDATE cars_models
	SET description = "new descs" 
	WHERE  description is NULL OR LENGTH(description) = 0;--byte lenght  or CHAR_LENGTH() for string length if char>byte


SHOW INDEX FROM cars_models;
DROP INDEX  desc_index on cars_models;
CREATE UNIQUE INDEX date_ind ON cars_models(selling_start); --the same as unique key

CREATE TABLE cars
(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    model_id INT UNSIGNED NOT NULL,
    description TEXT,
    UNIQUE model_id (model_id),
    FOREIGN KEY (model_id) REFERENCES cars_models(id).
    ON DELETE CASCADE  --SET NULL / RESTRICT
    ON UPDATE CASCADE 
);

SELECT --NULL doesn't includes in SELECT so we add OR IS NULL
    COUNT(m.amount) as amt
    ROUND(AVG(m.amount, 2) as rndamt
FROM
    cars_models as m
JOIN 
	cars as c ON m.id = c.model_id
GROUP BY 
	c.model_id
HAVING 
	COUNT(c.model_id) > 0
ORDER BY 
	COUNT(c.model_id) DESC, m.model

UNION --in mysql we use to make full outer join
SELECT * 
FROM 
	MAX(cars_models) 
WHERE 
	model IN ('honda', 'bugatti') OR amount NOT BETWEEN 10 AND 20 
ORDER BY 
	model,id
LIMIT 2,5;

SELECT DISTINCT
	DATE_FORMAT(selling_start, '%d.%m.%y') + INTERVAL 7 DAY AS date
FROM 
	cars
WHERE 
	model NOT LIKE '_a%'; -- BINARY gives opportunity to compare register sensetive

SELECT *
FROM (
    SELECT
        sum(amount) OVER w,
        avg(amount) OVER w,
        
    --if ORDER BY has been used count starts again in each partition 
    FROM 
    	cars_models
    WINDOW w AS (PARTITION BY model ORDER BY id DESC);
    ORDER BY 
    	amount
) count
WHERE
	MATCH(description) AGAINST('-new +red*' IN BOOLEAN MODE);--match is more effective than LIKE
																--with CONCAT() to match multiple columns
SELECT *
FROM 
	cars
WHERE (SELECT model, on_testdrive FROM cars_models)=("honda", 1)


TRUNCATE cars;-- rollback is not provided after truncate unlike
DELETE * FROM cars_model