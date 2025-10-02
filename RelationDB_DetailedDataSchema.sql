/* ---------- DROP TABLES (каскадне видалення обмежень) ---------- */
DROP TABLE Authorizations CASCADE CONSTRAINTS;
DROP TABLE Identification CASCADE CONSTRAINTS;
DROP TABLE Notification  CASCADE CONSTRAINTS;
DROP TABLE Recommendation CASCADE CONSTRAINTS;
DROP TABLE Threat CASCADE CONSTRAINTS;
DROP TABLE Delivery CASCADE CONSTRAINTS;
DROP TABLE ORDER_T CASCADE CONSTRAINTS;
DROP TABLE Restaurant CASCADE CONSTRAINTS;
DROP TABLE "USER" CASCADE CONSTRAINTS;
DROP TABLE "SYSTEM" CASCADE CONSTRAINTS;

/* ======================= CREATE TABLES ======================== */

-- Користувач
CREATE TABLE "USER" (
  user_id               NUMBER(10),
  name                  VARCHAR2(100),
  preferences           VARCHAR2(200),
  notification_settings VARCHAR2(100)
);
ALTER TABLE "USER" ADD CONSTRAINT pk_user PRIMARY KEY (user_id);
ALTER TABLE "USER" MODIFY (name NOT NULL);

-- Система
CREATE TABLE "SYSTEM" (
  system_id NUMBER(10),
  version   VARCHAR2(20)
);
ALTER TABLE "SYSTEM" ADD CONSTRAINT pk_system PRIMARY KEY (system_id);
ALTER TABLE "SYSTEM" MODIFY (version NOT NULL);
ALTER TABLE "SYSTEM" ADD CONSTRAINT chk_system_version
  CHECK ( REGEXP_LIKE(version, '^[0-9]+(\.[0-9]+){1,2}$') );
  -- формат: 1.0 або 1.2.3

-- Ресторан (БЕЗ order_id)
CREATE TABLE Restaurant (
  restaurant_id NUMBER(10),
  name          VARCHAR2(150),
  address       VARCHAR2(200)
);
ALTER TABLE Restaurant ADD CONSTRAINT pk_restaurant PRIMARY KEY (restaurant_id);
ALTER TABLE Restaurant MODIFY (name NOT NULL);

-- Замовлення (Order) — уникаємо ключового слова ORDER
CREATE TABLE ORDER_T (
  order_id      NUMBER(12),
  dishes        VARCHAR2(500),
  status        VARCHAR2(20),
  delivery_time DATE,
  user_id       NUMBER(10),
  restaurant_id NUMBER(10)
);
ALTER TABLE ORDER_T ADD CONSTRAINT pk_order PRIMARY KEY (order_id);
ALTER TABLE ORDER_T MODIFY (user_id NOT NULL);
ALTER TABLE ORDER_T MODIFY (restaurant_id NOT NULL);
ALTER TABLE ORDER_T ADD CONSTRAINT fk_order_user
  FOREIGN KEY (user_id) REFERENCES "USER"(user_id);
ALTER TABLE ORDER_T ADD CONSTRAINT fk_order_restaurant
  FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id);
ALTER TABLE ORDER_T ADD CONSTRAINT chk_order_status
  CHECK (status IN ('new','processing','delivered','cancelled'));

-- Доставка (1:1 з ORDER_T)
CREATE TABLE Delivery (
  delivery_id NUMBER(12),
  address     VARCHAR2(200),
  time        DATE,
  order_id    NUMBER(12)
);
ALTER TABLE Delivery ADD CONSTRAINT pk_delivery PRIMARY KEY (delivery_id);
ALTER TABLE Delivery MODIFY (order_id NOT NULL);
ALTER TABLE Delivery ADD CONSTRAINT uq_delivery_order UNIQUE (order_id);
ALTER TABLE Delivery ADD CONSTRAINT fk_delivery_order
  FOREIGN KEY (order_id) REFERENCES ORDER_T(order_id);

-- Рекомендація
CREATE TABLE Recommendation (
  recommendation_id NUMBER(12),
  text              VARCHAR2(300),
  criteria          VARCHAR2(200),
  system_id         NUMBER(10),
  user_id           NUMBER(10)
);
ALTER TABLE Recommendation ADD CONSTRAINT pk_recommendation PRIMARY KEY (recommendation_id);
ALTER TABLE Recommendation MODIFY (system_id NOT NULL);
ALTER TABLE Recommendation MODIFY (user_id NOT NULL);
ALTER TABLE Recommendation ADD CONSTRAINT fk_rec_system
  FOREIGN KEY (system_id) REFERENCES "SYSTEM"(system_id);
ALTER TABLE Recommendation ADD CONSTRAINT fk_rec_user
  FOREIGN KEY (user_id)   REFERENCES "USER"(user_id);

-- Сповіщення
CREATE TABLE Notification (
  notification_id NUMBER(12),
  message         VARCHAR2(300),
  date_sent       DATE,
  system_id       NUMBER(10),
  user_id         NUMBER(10)
);
ALTER TABLE Notification ADD CONSTRAINT pk_notification PRIMARY KEY (notification_id);
ALTER TABLE Notification MODIFY (system_id NOT NULL);
ALTER TABLE Notification MODIFY (user_id NOT NULL);
ALTER TABLE Notification ADD CONSTRAINT fk_notif_system
  FOREIGN KEY (system_id) REFERENCES "SYSTEM"(system_id);
ALTER TABLE Notification ADD CONSTRAINT fk_notif_user
  FOREIGN KEY (user_id)   REFERENCES "USER"(user_id);

-- Загроза
CREATE TABLE Threat (
  threat_id   NUMBER(12),
  description VARCHAR2(300),
  risk_level  VARCHAR2(10),
  system_id   NUMBER(10)
);
ALTER TABLE Threat ADD CONSTRAINT pk_threat PRIMARY KEY (threat_id);
ALTER TABLE Threat MODIFY (system_id NOT NULL);
ALTER TABLE Threat ADD CONSTRAINT fk_threat_system
  FOREIGN KEY (system_id) REFERENCES "SYSTEM"(system_id);
ALTER TABLE Threat ADD CONSTRAINT chk_threat_risk
  CHECK (risk_level IN ('low','medium','high'));

-- Ідентифікація (1:1 з User)
CREATE TABLE Identification (
  identification_id NUMBER(12),
  identifier        VARCHAR2(64),
  user_id           NUMBER(10)
);
ALTER TABLE Identification ADD CONSTRAINT pk_identification PRIMARY KEY (identification_id);
ALTER TABLE Identification MODIFY (identifier NOT NULL);
ALTER TABLE Identification ADD CONSTRAINT uq_ident_user UNIQUE (user_id);
ALTER TABLE Identification ADD CONSTRAINT fk_ident_user
  FOREIGN KEY (user_id) REFERENCES "USER"(user_id);
ALTER TABLE Identification ADD CONSTRAINT chk_identifier_format
  CHECK (REGEXP_LIKE(identifier, '^[A-Za-z0-9_-]{3,64}$'));

-- Авторизація (1:1 з Identification)
CREATE TABLE Authorizations (
  authorization_id   NUMBER(12),
  access_level       VARCHAR2(20),
  identification_id  NUMBER(12)
);
ALTER TABLE Authorizations ADD CONSTRAINT pk_authorization PRIMARY KEY (authorization_id);
ALTER TABLE Authorizations MODIFY (identification_id NOT NULL);
ALTER TABLE Authorizations ADD CONSTRAINT uq_auth_ident UNIQUE (identification_id);
ALTER TABLE Authorizations ADD CONSTRAINT fk_auth_ident
  FOREIGN KEY (identification_id) REFERENCES Identification(identification_id);
ALTER TABLE Authorizations ADD CONSTRAINT chk_access_level
  CHECK (access_level IN ('user','support','admin'));

-- Додаткові перевірки змісту
ALTER TABLE "USER" ADD CONSTRAINT chk_user_prefs_len
  CHECK (LENGTH(preferences) <= 200);
ALTER TABLE "USER" ADD CONSTRAINT chk_user_notif_len
  CHECK (LENGTH(notification_settings) <= 100);
ALTER TABLE ORDER_T ADD CONSTRAINT chk_order_dishes_len
  CHECK (LENGTH(dishes) <= 500);
