SET XACT_ABORT ON;
BEGIN TRANSACTION;

/* =========================================================
   Users
   ========================================================= */
CREATE TABLE dbo.Users (
    id               UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_users_id         DEFAULT NEWSEQUENTIALID(),
    entra_tenant_id  UNIQUEIDENTIFIER NOT NULL,
    entra_object_id  UNIQUEIDENTIFIER NOT NULL,
    email            NVARCHAR(320)    NOT NULL,
    first_name       NVARCHAR(200)    NULL,
    last_name        NVARCHAR(200)    NULL,
    is_active        BIT              NOT NULL CONSTRAINT df_users_is_active  DEFAULT (1),
    last_login_at    DATETIME2        NULL,
    created_at       DATETIME2        NOT NULL CONSTRAINT df_users_created_at DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2        NOT NULL CONSTRAINT df_users_updated_at DEFAULT SYSUTCDATETIME(),

    CONSTRAINT pk_users PRIMARY KEY CLUSTERED (id)
);

CREATE UNIQUE NONCLUSTERED INDEX ux_users_entra_identity
    ON dbo.Users (entra_tenant_id, entra_object_id);

CREATE NONCLUSTERED INDEX ix_users_email
    ON dbo.Users (email);


/* =========================================================
   Products
   ========================================================= */
CREATE TABLE dbo.Products (
    id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_products_id         DEFAULT NEWSEQUENTIALID(),
    name        NVARCHAR(400)    NOT NULL,
    price       DECIMAL(12,2)    NOT NULL,
    stock       INT              NOT NULL,
    category    VARCHAR(100)     NOT NULL,
    updated_at  DATETIME2        NOT NULL CONSTRAINT df_products_updated_at DEFAULT SYSUTCDATETIME(),
    created_at  DATETIME2        NOT NULL CONSTRAINT df_products_created_at DEFAULT SYSUTCDATETIME(),

    CONSTRAINT pk_products       PRIMARY KEY CLUSTERED (id),
    CONSTRAINT ck_products_price CHECK (price > 0),
    CONSTRAINT ck_products_stock CHECK (stock >= 0)
);

CREATE NONCLUSTERED INDEX ix_products_category
    ON dbo.Products (category);

/* =========================================================
   Orders
   ========================================================= */
CREATE TABLE dbo.Orders (
    id            UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_orders_id         DEFAULT NEWSEQUENTIALID(),
    user_id       UNIQUEIDENTIFIER NOT NULL,
    total         DECIMAL(12,2)    NOT NULL,
    payment_type  VARCHAR(100)     NULL,
    status        VARCHAR(100)     NULL,
    updated_at    DATETIME2        NOT NULL CONSTRAINT df_orders_updated_at DEFAULT SYSUTCDATETIME(),
    created_at    DATETIME2        NOT NULL CONSTRAINT df_orders_created_at DEFAULT SYSUTCDATETIME(),

    CONSTRAINT pk_orders       PRIMARY KEY CLUSTERED (id),
    CONSTRAINT fk_orders_users FOREIGN KEY (user_id) REFERENCES dbo.Users (id),
    CONSTRAINT ck_orders_total CHECK (total > 0)
);

CREATE NONCLUSTERED INDEX ix_orders_user_created_at
    ON dbo.Orders (user_id, created_at);

/* =========================================================
   OrderItem
   ========================================================= */
CREATE TABLE dbo.OrderItem (
    id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT df_order_item_id         DEFAULT NEWSEQUENTIALID(),
    product_id  UNIQUEIDENTIFIER NOT NULL,
    order_id    UNIQUEIDENTIFIER NOT NULL,
    unit_price  DECIMAL(12,2)    NOT NULL,
    quantity    INT              NOT NULL,
    updated_at  DATETIME2        NOT NULL CONSTRAINT df_order_item_updated_at DEFAULT SYSUTCDATETIME(),
    created_at  DATETIME2        NOT NULL CONSTRAINT df_order_item_created_at DEFAULT SYSUTCDATETIME(),

    CONSTRAINT pk_order_item            PRIMARY KEY CLUSTERED (id),
    CONSTRAINT fk_order_item_orders     FOREIGN KEY (order_id)   REFERENCES dbo.Orders (id),
    CONSTRAINT fk_order_item_products   FOREIGN KEY (product_id) REFERENCES dbo.Products (id),
    CONSTRAINT ck_order_item_unit_price CHECK (unit_price > 0),
    CONSTRAINT ck_order_item_quantity   CHECK (quantity > 0)
);

CREATE NONCLUSTERED INDEX ix_order_item_order_id
    ON dbo.OrderItem (order_id);

CREATE NONCLUSTERED INDEX ix_order_item_product_id
    ON dbo.OrderItem (product_id);

COMMIT TRANSACTION;