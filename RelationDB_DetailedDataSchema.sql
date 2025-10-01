/* ---------- DROP TABLES (каскадне видалення обмежень) ---------- */
DROP TABLE Authorizations CASCADE CONSTRAINTS;
DROP TABLE Identification CASCADE CONSTRAINTS;
DROP TABLE Notification CASCADE CONSTRAINTS;
DROP TABLE Recommendation CASCADE CONSTRAINTS;
DROP TABLE Threat CASCADE CONSTRAINTS;
DROP TABLE Delivery CASCADE CONSTRAINTS;
DROP TABLE Order_t CASCADE CONSTRAINTS;
DROP TABLE Restaurant CASCADE CONSTRAINTS;
DROP TABLE "USER" CASCADE CONSTRAINTS;
DROP TABLE System CASCADE CONSTRAINTS;

/* ======================= CREATE TABLES ======================== */

-- Користувач
CREATE TABLE "USER" (
    User_id NUMBER(10),
    Name VARCHAR2(100),
    Preferences VARCHAR2(200),
    Notification_settings VARCHAR2(100)
);
ALTER TABLE "USER" ADD CONSTRAINT Pk_user PRIMARY KEY (User_id);
ALTER TABLE "USER" MODIFY (Name NOT NULL);

-- Система
CREATE TABLE System (
    System_id NUMBER(10),
    Version VARCHAR2(20)
);
ALTER TABLE System ADD CONSTRAINT Pk_system PRIMARY KEY (System_id);
ALTER TABLE System MODIFY (Version NOT NULL);
ALTER TABLE System ADD CONSTRAINT Chk_system_version
CHECK (REGEXP_LIKE(Version, '^[0-9]+(\.[0-9]+){1,2}$'));
-- формат: 1.0 або 1.2.3

-- Ресторан (БЕЗ order_id)
CREATE TABLE Restaurant (
    Restaurant_id NUMBER(10),
    Name VARCHAR2(150),
    Address VARCHAR2(200)
);
ALTER TABLE Restaurant ADD CONSTRAINT Pk_restaurant PRIMARY KEY (Restaurant_id);
ALTER TABLE Restaurant MODIFY (Name NOT NULL);

-- Замовлення (Order) — уникаємо ключового слова ORDER
CREATE TABLE Order_t (
    Order_id NUMBER(12),
    Dishes VARCHAR2(500),
    Status VARCHAR2(20),
    Delivery_time DATE,
    User_id NUMBER(10),
    Restaurant_id NUMBER(10)
);
ALTER TABLE Order_t ADD CONSTRAINT Pk_order PRIMARY KEY (Order_id);
ALTER TABLE Order_t MODIFY (User_id NOT NULL);
ALTER TABLE Order_t MODIFY (Restaurant_id NOT NULL);
ALTER TABLE Order_t ADD CONSTRAINT Fk_order_user
FOREIGN KEY (User_id) REFERENCES "USER" (User_id);
ALTER TABLE Order_t ADD CONSTRAINT Fk_order_restaurant
FOREIGN KEY (Restaurant_id) REFERENCES Restaurant (Restaurant_id);
ALTER TABLE Order_t ADD CONSTRAINT Chk_order_status
CHECK (Status IN ('new', 'processing', 'delivered', 'cancelled'));

-- Доставка (1:1 з ORDER_T)
CREATE TABLE Delivery (
    Delivery_id NUMBER(12),
    Address VARCHAR2(200),
    Time DATE,
    Order_id NUMBER(12)
);
ALTER TABLE Delivery ADD CONSTRAINT Pk_delivery PRIMARY KEY (Delivery_id);
ALTER TABLE Delivery MODIFY (Order_id NOT NULL);
ALTER TABLE Delivery ADD CONSTRAINT Uq_delivery_order UNIQUE (Order_id);
ALTER TABLE Delivery ADD CONSTRAINT Fk_delivery_order
FOREIGN KEY (Order_id) REFERENCES Order_t (Order_id);


-- Рекомендація
CREATE TABLE Recommendation (
    Recommendation_id NUMBER(12),
    Text VARCHAR2(300),
    Criteria VARCHAR2(200),
    System_id NUMBER(10),
    User_id NUMBER(10)
);
ALTER TABLE Recommendation ADD CONSTRAINT Pk_recommendation PRIMARY KEY (
    Recommendation_id
);
ALTER TABLE Recommendation MODIFY (System_id NOT NULL);
ALTER TABLE Recommendation MODIFY (User_id NOT NULL);
ALTER TABLE Recommendation ADD CONSTRAINT Fk_rec_system
FOREIGN KEY (System_id) REFERENCES System (System_id);
ALTER TABLE Recommendation ADD CONSTRAINT Fk_rec_user
FOREIGN KEY (User_id) REFERENCES "USER" (User_id);

-- Сповіщення
CREATE TABLE Notification (
    Notification_id NUMBER(12),
    Message VARCHAR2(300),
    Date_sent DATE,
    System_id NUMBER(10),
    User_id NUMBER(10)
);
ALTER TABLE Notification ADD CONSTRAINT Pk_notification PRIMARY KEY (
    Notification_id
);
ALTER TABLE Notification MODIFY (System_id NOT NULL);
ALTER TABLE Notification MODIFY (User_id NOT NULL);
ALTER TABLE Notification ADD CONSTRAINT Fk_notif_system
FOREIGN KEY (System_id) REFERENCES System (System_id);
ALTER TABLE Notification ADD CONSTRAINT Fk_notif_user
FOREIGN KEY (User_id) REFERENCES "USER" (User_id);

-- Загроза
CREATE TABLE Threat (
    Threat_id NUMBER(12),
    Description VARCHAR2(300),
    Risk_level VARCHAR2(10),
    System_id NUMBER(10)
);
ALTER TABLE Threat ADD CONSTRAINT Pk_threat PRIMARY KEY (Threat_id);
ALTER TABLE Threat MODIFY (System_id NOT NULL);
ALTER TABLE Threat ADD CONSTRAINT Fk_threat_system
FOREIGN KEY (System_id) REFERENCES System (System_id);
ALTER TABLE Threat ADD CONSTRAINT Chk_threat_risk
CHECK (Risk_level IN ('low', 'medium', 'high'));

-- Ідентифікація (1:1 з User)
CREATE TABLE Identification (
    Identification_id NUMBER(12),
    Identifier VARCHAR2(64),
    User_id NUMBER(10)
);
ALTER TABLE Identification ADD CONSTRAINT Pk_identification PRIMARY KEY (
    Identification_id
);
ALTER TABLE Identification MODIFY (Identifier NOT NULL);
ALTER TABLE Identification ADD CONSTRAINT Uq_ident_user UNIQUE (User_id);
ALTER TABLE Identification ADD CONSTRAINT Fk_ident_user
FOREIGN KEY (User_id) REFERENCES "USER" (User_id);
ALTER TABLE Identification ADD CONSTRAINT Chk_identifier_format
CHECK (REGEXP_LIKE(Identifier, '^[A-Za-z0-9_-]{3,64}$'));

-- Авторизація (1:1 з Identification)
CREATE TABLE Authorizations (
    Authorization_id NUMBER(12),
    Access_level VARCHAR2(20),
    Identification_id NUMBER(12)
);
ALTER TABLE Authorizations ADD CONSTRAINT Pk_authorization PRIMARY KEY (
    Authorization_id
);
ALTER TABLE Authorizations MODIFY (Identification_id NOT NULL);
ALTER TABLE Authorizations ADD CONSTRAINT Uq_auth_ident UNIQUE (
    Identification_id
);
ALTER TABLE Authorizations ADD CONSTRAINT Fk_auth_ident
FOREIGN KEY (Identification_id) REFERENCES Identification (Identification_id);
ALTER TABLE Authorizations ADD CONSTRAINT Chk_access_level
CHECK (Access_level IN ('user', 'support', 'admin'));

-- Додаткові перевірки змісту
ALTER TABLE "USER" ADD CONSTRAINT chk_user_prefs_len
CHECK (LENGTH(preferences) <= 200);
ALTER TABLE "USER" ADD CONSTRAINT chk_user_notif_len
CHECK (LENGTH(notification_settings) <= 100);
ALTER TABLE order_t ADD CONSTRAINT chk_order_dishes_len
CHECK (LENGTH(dishes) <= 500);
