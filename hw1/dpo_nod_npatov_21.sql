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
CREATE TABLE Pharmacy (
    id SERIAL PRIMARY KEY,
    number INTEGER NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    metro_station VARCHAR(100)
);

-- Таблица: Категории лекарств
CREATE TABLE Category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Таблица: Лекарства
CREATE TABLE Medicine (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    volume VARCHAR(50),
    manufacturer VARCHAR(100) NOT NULL,
    requires_prescription BOOLEAN NOT NULL DEFAULT FALSE,
    price NUMERIC(10, 2) NOT NULL CHECK (price > 0)
);

-- Таблица: Провизоры
CREATE TABLE Pharmacist (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    birth_date DATE NOT NULL CHECK (birth_date < CURRENT_DATE),
    inn CHAR(12) NOT NULL UNIQUE,
    passport_series CHAR(4) NOT NULL,
    passport_number CHAR(6) NOT NULL,
    pharmacy_id INTEGER NOT NULL REFERENCES Pharmacy(id) ON DELETE RESTRICT,
    CONSTRAINT unique_passport UNIQUE (passport_series, passport_number)
);

-- Связующая таблица: Лекарство ↔ Категория (M:M)
CREATE TABLE Medicine_Category (
    medicine_id INTEGER NOT NULL REFERENCES Medicine(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES Category(id) ON DELETE CASCADE,
    PRIMARY KEY (medicine_id, category_id)
);

-- Таблица: Наличие лекарств в аптеке (M:M между Pharmacy и Medicine)
CREATE TABLE Stock (
    pharmacy_id INTEGER NOT NULL REFERENCES Pharmacy(id) ON DELETE CASCADE,
    medicine_id INTEGER NOT NULL REFERENCES Medicine(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0) DEFAULT 0,
    PRIMARY KEY (pharmacy_id, medicine_id)
);

-- Таблица: Продажи
CREATE TABLE Sale (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL REFERENCES Pharmacy(id) ON DELETE RESTRICT,
    medicine_id INTEGER NOT NULL REFERENCES Medicine(id) ON DELETE RESTRICT,
    pharmacist_id INTEGER NOT NULL REFERENCES Pharmacist(id) ON DELETE RESTRICT,
    sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);