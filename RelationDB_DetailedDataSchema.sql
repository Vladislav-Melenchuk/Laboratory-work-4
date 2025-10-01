/* ---------- DROP TABLES (каскадне видалення обмежень) ---------- */
DROP TABLE authorizations CASCADE CONSTRAINTS;
DROP TABLE identification CASCADE CONSTRAINTS;
DROP TABLE notification CASCADE CONSTRAINTS;
DROP TABLE recommendation CASCADE CONSTRAINTS;
DROP TABLE threat CASCADE CONSTRAINTS;
DROP TABLE delivery CASCADE CONSTRAINTS;
DROP TABLE order_t CASCADE CONSTRAINTS;
DROP TABLE restaurant CASCADE CONSTRAINTS;
DROP TABLE "USER" CASCADE CONSTRAINTS;
DROP TABLE system CASCADE CONSTRAINTS;

/* ======================= CREATE TABLES ======================== */

-- Користувач
CREATE TABLE "USER" (
    user_id NUMBER(10),
    name VARCHAR2(100),
    preferences VARCHAR2(200),
    notification_settings VARCHAR2(100)
);
ALTER TABLE "USER" ADD CONSTRAINT pk_user PRIMARY KEY (user_id);
ALTER TABLE "USER" MODIFY (name NOT NULL);

-- Система
CREATE TABLE system (
    system_id NUMBER(10),
    version VARCHAR2(20)
);
ALTER TABLE system ADD CONSTRAINT pk_system PRIMARY KEY (system_id);
ALTER TABLE system MODIFY (version NOT NULL);
ALTER TABLE system ADD CONSTRAINT chk_system_version
    CHECK (REGEXP_LIKE(version, '^[0-9]+(\.[0-9]+){1,2}$'));
-- формат: 1.0 або 1.2.3

-- Ресторан
CREATE TABLE restaurant (
    restaurant_id NUMBER(10),
    name VARCHAR2(150),
    address VARCHAR2(200)
);
ALTER TABLE restaurant ADD CONSTRAINT pk_restaurant PRIMARY KEY (restaurant_id);
ALTER TABLE restaurant MODIFY (name NOT NULL);

-- Замовлення (уникаємо ключового слова ORDER)
CREATE TABLE order_t (
    order_id NUMBER(12),
    dishes VARCHAR2(500),
    status VARCHAR2(20),
    delivery_time DATE,
    user_id NUMBER(10),
    restaurant_id NUMBER(10)
);
ALTER TABLE order_t ADD CONSTRAINT pk_order PRIMARY KEY (order_id);
ALTER TABLE order_t MODIFY (user_id NOT NULL);
ALTER TABLE order_t MODIFY (restaurant_id NOT NULL);
ALTER TABLE order_t ADD CONSTRAINT fk_order_user
    FOREIGN KEY (user_id) REFERENCES "USER" (user_id);
ALTER TABLE order_t ADD CONSTRAINT fk_order_restaurant
    FOREIGN KEY (restaurant_id) REFERENCES restaurant (restaurant_id);
ALTER TABLE order_t ADD CONSTRAINT chk_order_status
    CHECK (status IN ('new', 'processing', 'delivered', 'cancelled'));

-- Доставка (1:1 з ORDER_T)
CREATE TABLE delivery (
    delivery_id NUMBER(12),
    address VARCHAR2(200),
    time DATE,
    order_id NUMBER(12)
);
ALTER TABLE delivery ADD CONSTRAINT pk_delivery PRIMARY KEY (delivery_id);
ALTER TABLE delivery MODIFY (order_id NOT NULL);
ALTER TABLE delivery ADD CONSTRAINT uq_delivery_order UNIQUE (order_id);
ALTER TABLE delivery ADD CONSTRAINT fk_delivery_order
    FOREIGN KEY (order_id) REFERENCES order_t (order_id);

-- Рекомендація
CREATE TABLE recommendation (
    recommendation_id NUMBER(12),
    text VARCHAR2(300),
    criteria VARCHAR2(200),
    system_id NUMBER(10),
    user_id NUMBER(10)
);
ALTER TABLE recommendation ADD CONSTRAINT pk_recommendation PRIMARY KEY (recommendation_id);
ALTER TABLE recommendation MODIFY (system_id NOT NULL);
ALTER TABLE recommendation MODIFY (user_id NOT NULL);
ALTER TABLE recommendation ADD CONSTRAINT fk_rec_system
    FOREIGN KEY (system_id) REFERENCES system (system_id);
ALTER TABLE recommendation ADD CONSTRAINT fk_rec_user
    FOREIGN KEY (user_id) REFERENCES "USER" (user_id);

-- Сповіщення
CREATE TABLE notification (
    notification_id NUMBER(12),
    message VARCHAR2(300),
    date_sent DATE,
    system_id NUMBER(10),
    user_id NUMBER(10)
);
ALTER TABLE notification ADD CONSTRAINT pk_notification PRIMARY KEY (notification_id);
ALTER TABLE notification MODIFY (system_id NOT NULL);
ALTER TABLE notification MODIFY (user_id NOT NULL);
ALTER TABLE notification ADD CONSTRAINT fk_notif_system
    FOREIGN KEY (system_id) REFERENCES system (system_id);
ALTER TABLE notification ADD CONSTRAINT fk_notif_user
    FOREIGN KEY (user_id) REFERENCES "USER" (user_id);

-- Загроза
CREATE TABLE threat (
    threat_id NUMBER(12),
    description VARCHAR2(300),
    risk_level VARCHAR2(10),
    system_id NUMBER(10)
);
ALTER TABLE threat ADD CONSTRAINT pk_threat PRIMARY KEY (threat_id);
ALTER TABLE threat MODIFY (system_id NOT NULL);
ALTER TABLE threat ADD CONSTRAINT fk_threat_system
    FOREIGN KEY (system_id) REFERENCES system (system_id);
ALTER TABLE threat ADD CONSTRAINT chk_threat_risk
    CHECK (risk_level IN ('low', 'medium', 'high'));

-- Ідентифікація (1:1 з User)
CREATE TABLE identification (
    identification_id NUMBER(12),
    identifier VARCHAR2(64),
    user_id NUMBER(10)
);
ALTER TABLE identification ADD CONSTRAINT pk_identification PRIMARY KEY (identification_id);
ALTER TABLE identification MODIFY (identifier NOT NULL);
ALTER TABLE identification ADD CONSTRAINT uq_ident_user UNIQUE (user_id);
ALTER TABLE identification ADD CONSTRAINT fk_ident_user
    FOREIGN KEY (user_id) REFERENCES "USER" (user_id);
ALTER TABLE identification ADD CONSTRAINT chk_identifier_format
    CHECK (REGEXP_LIKE(identifier, '^[A-Za-z0-9_-]{3,64}$'));

-- Авторизація (1:1 з Identification)
CREATE TABLE authorizations (
    authorization_id NUMBER(12),
    access_level VARCHAR2(20),
    identification_id NUMBER(12)
);
ALTER TABLE authorizations ADD CONSTRAINT pk_authorization PRIMARY KEY (authorization_id);
ALTER TABLE authorizations MODIFY (identification_id NOT NULL);
ALTER TABLE authorizations ADD CONSTRAINT uq_auth_ident UNIQUE (identification_id);
ALTER TABLE authorizations ADD CONSTRAINT fk_auth_ident
    FOREIGN KEY (identification_id) REFERENCES identification (identification_id);
ALTER TABLE authorizations ADD CONSTRAINT chk_access_level
    CHECK (access_level IN ('user', 'support', 'admin'));

-- Додаткові перевірки змісту
ALTER TABLE "USER" ADD CONSTRAINT chk_user_prefs_len
    CHECK (LENGTH(preferences) <= 200);
ALTER TABLE "USER" ADD CONSTRAINT chk_user_notif_len
    CHECK (LENGTH(notification_settings) <= 100);
ALTER TABLE order_t ADD CONSTRAINT chk_order_dishes_len
    CHECK (LENGTH(dishes) <= 500);

-- Рекомендовані індекси на зовнішні ключі (не обов'язково)
CREATE INDEX idx_order_user ON order_t (user_id);
CREATE INDEX idx_order_restaurant ON order_t (restaurant_id);
CREATE INDEX idx_delivery_order ON delivery (order_id);
CREATE INDEX idx_rec_system ON recommendation (system_id);
CREATE INDEX idx_rec_user ON recommendation (user_id);
CREATE INDEX idx_notif_system ON notification (system_id);
CREATE INDEX idx_notif_user ON notification (user_id);
CREATE INDEX idx_threat_system ON threat (system_id);
CREATE INDEX idx_ident_user ON identification (user_id);
CREATE INDEX idx_auth_ident ON authorizations (identification_id);
