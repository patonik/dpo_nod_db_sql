-- Патов Николай Андреевич
-- Вариант: 21
-- Условие: Описание сети аптек. Включает аптеки, лекарства, категории лекарств, провизоров, наличие и продажи лекарств.
-- Аптеки: адрес, номер, ближайшая станция метро.
-- Лекарства: название, дозировка, количество/объём, производитель, требуется ли рецепт, категории, цена.
-- Категории: только название.
-- Провизоры: ФИО, дата рождения, ИНН, паспорт, аптека.
-- Наличие: аптека + лекарство + количество упаковок.
-- Продажа: аптека + лекарство + провизор + дата + количество упаковок.
-- Одно лекарство может принадлежать нескольким категориям.

-- Таблица: Аптеки
CREATE TABLE Pharmacy
(
    id            SERIAL PRIMARY KEY,
    number        INTEGER      NOT NULL UNIQUE,
    address       VARCHAR(255) NOT NULL,
    metro_station VARCHAR(100)
);

-- Таблица: Категории лекарств
CREATE TABLE Category
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Таблица: Лекарства
CREATE TABLE Medicine
(
    id                    SERIAL PRIMARY KEY,
    name                  VARCHAR(150)   NOT NULL,
    dosage                VARCHAR(50)    NOT NULL,
    volume                VARCHAR(50),
    manufacturer          VARCHAR(100)   NOT NULL,
    requires_prescription BOOLEAN        NOT NULL DEFAULT FALSE,
    price                 NUMERIC(10, 2) NOT NULL CHECK (price > 0)
);

-- Таблица: Провизоры
CREATE TABLE Pharmacist
(
    id              SERIAL PRIMARY KEY,
    last_name       VARCHAR(50) NOT NULL,
    first_name      VARCHAR(50) NOT NULL,
    patronymic      VARCHAR(50),
    birth_date      DATE        NOT NULL CHECK (birth_date < CURRENT_DATE),
    inn             CHAR(12)    NOT NULL UNIQUE,
    passport_series CHAR(4)     NOT NULL,
    passport_number CHAR(6)     NOT NULL,
    pharmacy_id     INTEGER     NOT NULL REFERENCES Pharmacy (id) ON DELETE RESTRICT,
    CONSTRAINT unique_passport UNIQUE (passport_series, passport_number)
);

-- Связующая таблица: Лекарство ↔ Категория (M:M)
CREATE TABLE Medicine_Category
(
    medicine_id INTEGER NOT NULL REFERENCES Medicine (id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES Category (id) ON DELETE CASCADE,
    PRIMARY KEY (medicine_id, category_id)
);

-- Таблица: Наличие лекарств в аптеке (M:M между Pharmacy и Medicine)
CREATE TABLE Stock
(
    pharmacy_id INTEGER NOT NULL REFERENCES Pharmacy (id) ON DELETE CASCADE,
    medicine_id INTEGER NOT NULL REFERENCES Medicine (id) ON DELETE CASCADE,
    quantity    INTEGER NOT NULL CHECK (quantity >= 0) DEFAULT 0,
    PRIMARY KEY (pharmacy_id, medicine_id)
);

-- Таблица: Продажи
CREATE TABLE Sale
(
    id            SERIAL PRIMARY KEY,
    pharmacy_id   INTEGER NOT NULL REFERENCES Pharmacy (id) ON DELETE RESTRICT,
    medicine_id   INTEGER NOT NULL REFERENCES Medicine (id) ON DELETE RESTRICT,
    pharmacist_id INTEGER NOT NULL REFERENCES Pharmacist (id) ON DELETE RESTRICT,
    sale_date     DATE    NOT NULL DEFAULT CURRENT_DATE,
    quantity      INTEGER NOT NULL CHECK (quantity > 0)
);

-- Заполнение таблиц данными

INSERT INTO Pharmacy (number, address, metro_station)
VALUES (101, 'Москва, Тверская ул., 1', 'Тверская'),
       (102, 'Москва, Арбат ул., 10', 'Арбатская'),
       (103, 'Москва, Ленинский просп., 20', 'Ленинский проспект'),
       (104, 'Москва, Кутузовский просп., 30', 'Кутузовская'),
       (105, 'Москва, Новослободская ул., 40', 'Новослободская');

INSERT INTO Category (name)
VALUES ('Анальгетики'),
       ('Антибиотики'),
       ('Витамины'),
       ('Антигистаминные'),
       ('Противовоспалительные'),
       ('Противовирусные');

INSERT INTO Medicine (name, dosage, volume, manufacturer, requires_prescription, price)
VALUES ('Аспирин', '500 мг', NULL, 'Bayer', FALSE, 50.00),
       ('Парацетамол', '500 мг', NULL, 'Johnson & Johnson', FALSE, 30.00),
       ('Ибупрофен', '200 мг', NULL, 'Pfizer', FALSE, 100.00),
       ('Амоксициллин', '500 мг', NULL, 'GlaxoSmithKline', TRUE, 200.00),
       ('Лоратадин', '10 мг', NULL, 'Schering-Plough', FALSE, 150.00),
       ('Витамин C', '500 мг', NULL, 'Hexal', FALSE, 50.00),
       ('Омепразол', '20 мг', NULL, 'AstraZeneca', TRUE, 300.00),
       ('Диклофенак', '50 мг', NULL, 'Novartis', TRUE, 80.00),
       ('Ципрофлоксацин', '500 мг', NULL, 'Bayer', TRUE, 150.00),
       ('Арбидол', '200 мг', NULL, 'Pharmstandard', FALSE, 500.00);

INSERT INTO Pharmacist (last_name, first_name, patronymic, birth_date, inn, passport_series, passport_number,
                        pharmacy_id)
VALUES ('Иванов', 'Иван', 'Иванович', '1985-05-10', '771401234567', '4601', '123456', 1),
       ('Петрова', 'Анна', 'Сергеевна', '1990-03-15', '771412345678', '4602', '654321', 1),
       ('Сидоров', 'Сергей', 'Петрович', '1978-07-20', '771423456789', '4603', '112233', 2),
       ('Смирнова', 'Ольга', 'Николаевна', '1988-11-25', '771434567890', '4604', '445566', 3),
       ('Кузнецов', 'Алексей', 'Владимирович', '1992-02-05', '771445678901', '4605', '778899', 4),
       ('Федорова', 'Мария', 'Александровна', '1983-09-30', '771456789012', '4606', '990011', 5);

INSERT INTO Medicine_Category (medicine_id, category_id)
VALUES (1, 1), -- Аспирин -> Анальгетики
       (2, 1), -- Парацетамол -> Анальгетики
       (3, 1), -- Ибупрофен -> Анальгетики
       (3, 5), -- Ибупрофен -> Противовоспалительные
       (4, 2), -- Амоксициллин -> Антибиотики
       (5, 4), -- Лоратадин -> Антигистаминные
       (6, 3), -- Витамин C -> Витамины
       (7, 1), -- Омепразол (здесь условно, но на самом деле противоязвенное; для примера)
       (8, 1), -- Диклофенак -> Анальгетики
       (8, 5), -- Диклофенак -> Противовоспалительные
       (9, 2), -- Ципрофлоксацин -> Антибиотики
       (10, 6); -- Арбидол -> Противовирусные

INSERT INTO Stock (pharmacy_id, medicine_id, quantity)
VALUES (1, 1, 50),
       (1, 2, 100),
       (1, 3, 30),
       (1, 4, 20),
       (1, 5, 40),
       (2, 6, 60),
       (2, 7, 25),
       (2, 8, 35),
       (2, 9, 45),
       (2, 10, 55),
       (3, 1, 70),
       (3, 3, 80),
       (4, 4, 90),
       (4, 5, 100),
       (5, 6, 110);

INSERT INTO Sale (pharmacy_id, medicine_id, pharmacist_id, sale_date, quantity)
VALUES (1, 1, 1, '2025-10-01', 2),
       (1, 2, 2, '2025-10-05', 5),
       (2, 3, 3, '2025-10-10', 1),
       (3, 4, 4, '2025-10-15', 3),
       (4, 5, 5, '2025-10-20', 4),
       (5, 6, 6, '2025-10-25', 6);

-- Task 1. Выберите название и дозировку лекарств стоимостью менее 1000 рублей за упаковку, требующих наличие рецепта.
SELECT name, dosage
FROM Medicine
WHERE price < 1000
  AND requires_prescription = TRUE;

-- Task 2. Выберите число лекарств в наличии по каждой группе лекарств, с точки зрения необходимости рецепта (две строки).
SELECT m.requires_prescription, COUNT(DISTINCT m.id) AS medicine_count
FROM Medicine m
         JOIN Stock s ON m.id = s.medicine_id
WHERE s.quantity > 0
GROUP BY m.requires_prescription;