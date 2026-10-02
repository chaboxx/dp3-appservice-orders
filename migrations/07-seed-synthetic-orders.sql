/* =========================================================
   Datos sintéticos para el ETL (opcional; NO es un cambio de esquema)
   ---------------------------------------------------------
   Genera 12 meses de historia para que bronze / silver / gold tengan qué procesar:

   - 250 clientes falsos: tenant ficticio DA7A0000-5EED-..., email clienteNNNN@dp3-synthetic.test.
     first_name / last_name quedan NULL: están cifrados y el Query Editor no puede escribirlos
     (09-synthetic-names-ssms.sql los llena desde SSMS).
     Ciudad con peso realista (Lima ~40%) y ~4% sin ciudad, como un token sin el claim city.
     Pocos clientes compran mucho y la mayoría poco; ~2% inactivos.
   - 3000 órdenes con estacionalidad (campaña escolar, Día de la Madre, Fiestas Patrias,
     Black Friday / Cyber, Navidad), más compras de noche y en fin de semana (hora de Lima) y
     ventas que se duplican a lo largo del año.
   - Estados: confirmed (solo existen aquí: la API todavía no tiene flujo de pago), cancelled y
     pending. ~30% de las canceladas con soft delete (deleted_at), como hace DELETE en la API.
   - De 1 a 5 productos distintos por orden; unit_price = precio actual; total = Σ precio × cantidad.
   - Amplía el catálogo de 03-seed-products.sql (agrega solo los nombres que no existen).

   Requiere 06-users-city.sql. Ejecutarlo UNA vez y ANTES de la primera carga del ETL: las fechas
   quedan en el pasado, y una carga incremental que ya movió su watermark (updated_at) no las ve.
   - No descuenta stock: es historia; el stock actual queda igual.
   - Antedata created_at de los productos para que ninguna orden sea anterior a su producto.
   - Fechas en UTC, como las guarda la app.
   - Al azar: cada ejecución genera datos distintos. Para borrarlos, ver el final del archivo.
   ========================================================= */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @tenant      UNIQUEIDENTIFIER = 'DA7A0000-5EED-4000-8000-000000000000';  -- tenant ficticio
DECLARE @user_count  INT = 250;
DECLARE @order_count INT = 3000;
DECLARE @months      INT = 12;
DECLARE @lima_offset INT = 5;  -- Lima = UTC-5 todo el año

DECLARE @now       DATETIME2 = SYSUTCDATETIME();
DECLARE @today     DATE      = CAST(@now AS DATE);
DECLARE @first_day DATE      = DATEADD(MONTH, -@months, DATEFROMPARTS(YEAR(@today), MONTH(@today), 1));
DECLARE @last_day  DATE      = DATEADD(DAY, -1, @today);
DECLARE @start     DATETIME2 = CAST(@first_day AS DATETIME2);

IF EXISTS (SELECT 1 FROM dbo.Users WHERE entra_tenant_id = @tenant)
    THROW 50000, N'Ya hay datos sintéticos: bórralos primero (consulta al final del archivo).', 1;

DROP TABLE IF EXISTS #n, #products, #cities, #user_rand, #users, #user_ranges, #days, #hours,
                     #order_rand, #order_times, #orders, #candidates, #items;

/* Cómo se usa el azar:
   - Número al azar entre 0 y 1, uno por fila: CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648
   - Elegir con peso: cada opción ocupa un tramo [cum_lo, cum_hi) proporcional a su peso y gana la
     que contiene el número al azar.
   - Los números al azar se guardan en tablas temporales (#*_rand) para que no se recalculen. */

-- Números 1..N para generar filas sin bucles
SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #n
FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b;

BEGIN TRANSACTION;

/* ---------- 1. Catálogo ---------- */
INSERT INTO dbo.Products (name, price, stock, category)
SELECT v.name, v.price, v.stock, v.category
FROM (VALUES
    (N'Audífonos bluetooth',          159.90, 150, 'electronics'),
    (N'Cargador USB-C 65W',            89.90, 200, 'electronics'),
    (N'Webcam Full HD',               199.00,  80, 'electronics'),
    (N'Disco SSD 1 TB',               329.00,  60, 'electronics'),
    (N'Lámpara de escritorio LED',     69.90, 120, 'home'),
    (N'Botella térmica 1 L',           45.00, 250, 'home'),
    (N'Juego de sábanas 2 plazas',    129.00,  90, 'home'),
    (N'Lapiceros x12',                 18.90, 400, 'stationery'),
    (N'Colores x24',                   29.90, 300, 'stationery'),
    (N'Mochila escolar',               99.00, 110, 'stationery'),
    (N'Mat de yoga',                   79.00, 140, 'sports'),
    (N'Mancuernas 5 kg (par)',        119.00,  70, 'sports'),
    (N'Pelota de fútbol',              89.90, 130, 'sports'),
    (N'Libro: Clean Code',            145.00,  60, 'books'),
    (N'Libro: Designing Data-Intensive Applications', 189.00, 40, 'books')
) AS v (name, price, stock, category)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Products AS p WHERE p.name = v.name);

-- El catálogo ya existía antes de la primera orden (updated_at no se toca)
UPDATE dbo.Products
SET created_at = DATEADD(DAY, -30, @start)
WHERE created_at > DATEADD(DAY, -30, @start);

-- Peso de venta de cada producto: lo barato se vende más
SELECT id, price, category,
       CASE WHEN price < 50 THEN 5.0 WHEN price < 150 THEN 3.0
            WHEN price < 500 THEN 2.0 ELSE 1.0 END AS weight
INTO #products
FROM dbo.Products;

/* ---------- 2. Clientes ---------- */
SELECT city,
       CAST(SUM(weight) OVER (ORDER BY id ROWS UNBOUNDED PRECEDING) - weight AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_lo,
       CAST(SUM(weight) OVER (ORDER BY id ROWS UNBOUNDED PRECEDING) AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_hi
INTO #cities
FROM (VALUES
    (1, N'Lima', 42), (2, N'Arequipa', 10), (3, N'Trujillo', 8), (4, N'Chiclayo', 7),
    (5, N'Piura', 6), (6, N'Cusco', 6), (7, N'Huancayo', 5), (8, N'Ica', 4),
    (9, N'Iquitos', 4), (10, N'Tacna', 4),
    (11, NULL, 4)  -- token sin el claim city
) AS v (id, city, weight);

SELECT NEWID() AS id,
       CONCAT('cliente', RIGHT(CONCAT('000', n), 4), '@dp3-synthetic.test') AS email,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_city,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_signup,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_kind
INTO #user_rand
FROM #n
WHERE n <= @user_count;

SELECT r.id, r.email, c.city,
       CASE WHEN r.r_signup < 0.30  -- 30% ya eran clientes antes de la historia (hasta 6 meses antes)
            THEN DATEADD(MINUTE, -CAST(r.r_signup / 0.30 * 180 * 1440 AS INT), @start)
            ELSE DATEADD(MINUTE, CAST((r.r_signup - 0.30) / 0.70 * DATEDIFF(MINUTE, @start, @now) AS INT), @start)
       END AS created_at,
       CASE WHEN r.r_kind < 0.10 THEN 8      -- frecuentes
            WHEN r.r_kind < 0.40 THEN 3      -- ocasionales
            ELSE 1 END AS weight,            -- esporádicos
       CASE WHEN r.r_kind >= 0.98 THEN 0 ELSE 1 END AS is_active
INTO #users
FROM #user_rand AS r
JOIN #cities AS c ON r.r_city >= c.cum_lo AND r.r_city < c.cum_hi;

-- Tramos por fecha de registro: una orden solo puede ser de alguien que ya se había registrado
SELECT id, created_at,
       SUM(weight) OVER (ORDER BY created_at, id ROWS UNBOUNDED PRECEDING) - weight AS cum_lo,
       SUM(weight) OVER (ORDER BY created_at, id ROWS UNBOUNDED PRECEDING) AS cum_hi
INTO #user_ranges
FROM #users;

/* ---------- 3. Calendario: peso de cada día y de cada hora (hora de Lima) ---------- */
SELECT local_date,
       CAST(SUM(weight) OVER (ORDER BY local_date ROWS UNBOUNDED PRECEDING) - weight AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_lo,
       CAST(SUM(weight) OVER (ORDER BY local_date ROWS UNBOUNDED PRECEDING) AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_hi
INTO #days
FROM (
    SELECT d.local_date,
           CAST(
               -- crecimiento: el último día vende el doble que el primero
               (1 + 1.0 * DATEDIFF(DAY, @first_day, d.local_date) / DATEDIFF(DAY, @first_day, @last_day))
               -- temporada
             * CASE MONTH(d.local_date)
                   WHEN 1 THEN 0.85 WHEN 2 THEN 0.90 WHEN 3 THEN 1.10 WHEN 4 THEN 0.95
                   WHEN 5 THEN 1.05 WHEN 6 THEN 1.00 WHEN 7 THEN 1.10 WHEN 8 THEN 0.95
                   WHEN 9 THEN 0.95 WHEN 10 THEN 1.00 WHEN 11 THEN 1.15 ELSE 1.30 END
               -- campañas
             * CASE
                   WHEN MONTH(d.local_date) = 5  AND DAY(d.local_date) <= 11             THEN 1.4  -- Día de la Madre
                   WHEN MONTH(d.local_date) = 7  AND DAY(d.local_date) BETWEEN 15 AND 28 THEN 1.3  -- Fiestas Patrias
                   WHEN MONTH(d.local_date) = 11 AND DAY(d.local_date) >= 24             THEN 1.8  -- Black Friday / Cyber
                   WHEN MONTH(d.local_date) = 12 AND DAY(d.local_date) BETWEEN 15 AND 24 THEN 1.6  -- Navidad
                   ELSE 1.0 END
               -- día de la semana (1900-01-01 fue lunes: 0 = lunes ... 6 = domingo)
             * CASE DATEDIFF(DAY, '19000101', d.local_date) % 7
                   WHEN 0 THEN 0.9 WHEN 5 THEN 1.2 WHEN 6 THEN 1.2 ELSE 1.0 END
           AS DECIMAL(18, 6)) AS weight
    FROM (SELECT DATEADD(DAY, n - 1, @first_day) AS local_date
          FROM #n
          WHERE n <= DATEDIFF(DAY, @first_day, @last_day) + 1) AS d
) AS w;

SELECT hour,
       CAST(SUM(weight) OVER (ORDER BY hour ROWS UNBOUNDED PRECEDING) - weight AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_lo,
       CAST(SUM(weight) OVER (ORDER BY hour ROWS UNBOUNDED PRECEDING) AS DECIMAL(18, 6))
           / SUM(weight) OVER () AS cum_hi
INTO #hours
FROM (VALUES
    (0, 0.4), (1, 0.2), (2, 0.1), (3, 0.1), (4, 0.1), (5, 0.2), (6, 0.4), (7, 0.6),
    (8, 0.8), (9, 1.0), (10, 1.1), (11, 1.2), (12, 1.3), (13, 1.3), (14, 1.1), (15, 1.0),
    (16, 1.0), (17, 1.1), (18, 1.3), (19, 1.6), (20, 1.8), (21, 1.7), (22, 1.2), (23, 0.7)
) AS v (hour, weight);

/* ---------- 4. Órdenes ---------- */
SELECT NEWID() AS id,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_day,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_hour,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_second,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_user,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_status,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_payment,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_delay,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_delete,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_items
INTO #order_rand
FROM #n
WHERE n <= @order_count;

-- Día y hora de Lima -> UTC (sin pasar de "ahora")
SELECT r.*, d.local_date,
       LEAST(DATEADD(SECOND, CAST(r.r_second * 3600 AS INT),
                     DATEADD(HOUR, h.hour + @lima_offset, CAST(d.local_date AS DATETIME2))),
             @now) AS created_at
INTO #order_times
FROM #order_rand AS r
JOIN #days AS d ON r.r_day >= d.cum_lo AND r.r_day < d.cum_hi
JOIN #hours AS h ON r.r_hour >= h.cum_lo AND r.r_hour < h.cum_hi;

SELECT o.id, u.id AS user_id, o.local_date, o.created_at, s.status, p.payment_type,
       LEAST(c.changed_at, @now) AS changed_at,
       CASE WHEN s.status = 'cancelled' AND o.r_delete < 0.30  -- soft delete de la API
            THEN LEAST(DATEADD(MINUTE, CAST(o.r_delete / 0.30 * 7 * 1440 AS INT), c.changed_at), @now)
       END AS deleted_at,
       CASE WHEN o.r_items < 0.45 THEN 1 WHEN o.r_items < 0.75 THEN 2 WHEN o.r_items < 0.90 THEN 3
            WHEN o.r_items < 0.97 THEN 4 ELSE 5 END AS item_count
INTO #orders
FROM #order_times AS o
-- cliente: elegido con peso entre los ya registrados en created_at
CROSS APPLY (SELECT MAX(cum_hi) AS total FROM #user_ranges WHERE created_at <= o.created_at) AS eligible
JOIN #user_ranges AS u
  ON o.r_user * eligible.total >= u.cum_lo AND o.r_user * eligible.total < u.cum_hi
CROSS APPLY (VALUES (
    CASE WHEN o.created_at > DATEADD(DAY, -3, @now)  -- recientes: muchas siguen sin pagar
         THEN CASE WHEN o.r_status < 0.35 THEN 'pending' WHEN o.r_status < 0.95 THEN 'confirmed'
                   ELSE 'cancelled' END
         ELSE CASE WHEN o.r_status < 0.05 THEN 'pending' WHEN o.r_status < 0.87 THEN 'confirmed'
                   ELSE 'cancelled' END
    END)) AS s (status)
CROSS APPLY (VALUES (
    CASE WHEN s.status = 'pending' AND o.r_delay < 0.40 THEN NULL  -- aún no eligió cómo pagar
         WHEN o.r_payment < 0.45 THEN 'card' WHEN o.r_payment < 0.75 THEN 'yape'
         WHEN o.r_payment < 0.90 THEN 'cash' ELSE 'transfer' END)) AS p (payment_type)
CROSS APPLY (VALUES (
    CASE s.status
        WHEN 'pending'   THEN o.created_at
        WHEN 'confirmed' THEN DATEADD(SECOND, 60 + CAST(o.r_delay * 1740 AS INT), o.created_at)  -- paga en 1-30 min
        ELSE                  DATEADD(MINUTE, 10 + CAST(o.r_delay * 2870 AS INT), o.created_at)  -- cancela en 10 min-48 h
    END)) AS c (changed_at);

/* ---------- 5. Ítems: productos distintos por orden, elegidos con peso ---------- */
-- Cada producto recibe la clave -ln(azar) / peso y cada orden se queda con las item_count más
-- chicas: es una muestra con peso y sin repetidos. El peso cambia según la temporada.
SELECT o.id AS order_id, o.item_count, p.id AS product_id, p.price,
       -LOG((CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) + 1) / 2147483649)
           / (p.weight * CASE
                 WHEN p.category = 'stationery'  AND MONTH(o.local_date) IN (2, 3)   THEN 3.0  -- campaña escolar
                 WHEN p.category = 'electronics' AND MONTH(o.local_date) IN (11, 12) THEN 2.0  -- Cyber / Navidad
                 WHEN p.category = 'home'        AND MONTH(o.local_date) = 5         THEN 2.0  -- Día de la Madre
                 WHEN p.category = 'sports'      AND MONTH(o.local_date) = 1         THEN 1.8  -- año nuevo
                 ELSE 1.0 END) AS sort_key,
       CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 AS r_quantity
INTO #candidates
FROM #orders AS o
CROSS JOIN #products AS p;

SELECT order_id, product_id, price AS unit_price,
       CASE WHEN r_quantity < 0.75 THEN 1 WHEN r_quantity < 0.92 THEN 2
            WHEN r_quantity < 0.98 THEN 3 ELSE 4 END AS quantity
INTO #items
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY sort_key) AS rn
      FROM #candidates) AS c
WHERE rn <= item_count;

/* ---------- 6. Insertar ---------- */
INSERT INTO dbo.Users (id, entra_tenant_id, entra_object_id, email, city, is_active,
                       last_login_at, created_at, updated_at)
SELECT u.id, @tenant, NEWID(), u.email, u.city, u.is_active,
       COALESCE(l.last_order_at, u.created_at),
       u.created_at,
       COALESCE(l.last_order_at, u.created_at)  -- la app actualiza la fila al refrescar last_login_at
FROM #users AS u
OUTER APPLY (SELECT MAX(created_at) AS last_order_at FROM #orders WHERE user_id = u.id) AS l;

INSERT INTO dbo.Orders (id, user_id, total, payment_type, status, created_at, updated_at, deleted_at)
SELECT o.id, o.user_id, t.total, o.payment_type, o.status, o.created_at,
       COALESCE(o.deleted_at, o.changed_at), o.deleted_at
FROM #orders AS o
JOIN (SELECT order_id, SUM(unit_price * quantity) AS total FROM #items GROUP BY order_id) AS t
  ON t.order_id = o.id;

INSERT INTO dbo.OrderItem (product_id, order_id, unit_price, quantity, created_at, updated_at)
SELECT i.product_id, i.order_id, i.unit_price, i.quantity, o.created_at, o.created_at
FROM #items AS i
JOIN #orders AS o ON o.id = i.order_id;

COMMIT TRANSACTION;

-- Verificación: órdenes y ventas por mes (UTC)
SELECT FORMAT(o.created_at, 'yyyy-MM') AS mes,
       COUNT(*) AS ordenes,
       SUM(CASE WHEN o.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmadas,
       SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) AS canceladas,
       SUM(CASE WHEN o.status = 'pending' THEN 1 ELSE 0 END) AS pendientes,
       SUM(CASE WHEN o.status = 'confirmed' THEN o.total ELSE 0 END) AS ventas_confirmadas,
       COUNT(DISTINCT o.user_id) AS clientes
FROM dbo.Orders AS o
JOIN dbo.Users AS u ON u.id = o.user_id
WHERE u.entra_tenant_id = @tenant
GROUP BY FORMAT(o.created_at, 'yyyy-MM')
ORDER BY mes;

/* ---------- Borrar los datos sintéticos (ejecutar aparte) ----------
   Todo cuelga del tenant ficticio. Es un borrado FÍSICO: una carga incremental no lo ve, así que
   si el lake ya los cargó hay que recargar desde cero. Los productos agregados se quedan.

DECLARE @tenant UNIQUEIDENTIFIER = 'DA7A0000-5EED-4000-8000-000000000000';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE i FROM dbo.OrderItem AS i
JOIN dbo.Orders AS o ON o.id = i.order_id
JOIN dbo.Users AS u ON u.id = o.user_id
WHERE u.entra_tenant_id = @tenant;
DELETE o FROM dbo.Orders AS o
JOIN dbo.Users AS u ON u.id = o.user_id
WHERE u.entra_tenant_id = @tenant;
DELETE FROM dbo.Users WHERE entra_tenant_id = @tenant;
COMMIT TRANSACTION;
*/
