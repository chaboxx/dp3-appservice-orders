/* =========================================================
   Simular cambios para el SCD2 (opcional; NO es un cambio de esquema; se puede repetir)
   ---------------------------------------------------------
   El SCD2 solo crea una versión nueva si la fila cambió ENTRE dos cargas del ETL, así que esto
   se ejecuta DESPUÉS de una carga (y la siguiente carga lo recoge). Cada ejecución:
   - Muda de ciudad a ~5% de los clientes sintéticos de 07 (dim de clientes).
   - Sube entre 5% y 15% el precio de 3 productos al azar (dim de productos). Las órdenes nuevas
     de la API ya usan el precio nuevo; las viejas conservan su unit_price.
   - Cambia de categoría "Botella térmica 1 L" (home <-> sports) (dim de productos).

   updated_at se pone a mano: un UPDATE desde aquí no pasa por el ORM, y sin eso la carga
   incremental (watermark por updated_at) no ve el cambio.
   Los clientes reales no se tocan: su ciudad la reescribe la app con el claim city del token.
   ========================================================= */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @tenant UNIQUEIDENTIFIER = 'DA7A0000-5EED-4000-8000-000000000000';  -- el de 07
DECLARE @now    DATETIME2 = SYSUTCDATETIME();

DROP TABLE IF EXISTS #moves, #price_changes;

-- El número al azar se guarda primero: CHOOSE/CASE con NEWID() adentro lo recalcula en cada rama
SELECT TOP (5) PERCENT id, 1 + (CHECKSUM(NEWID()) & 2147483647) % 10 AS city_index
INTO #moves
FROM dbo.Users
WHERE entra_tenant_id = @tenant AND is_active = 1
ORDER BY NEWID();

SELECT TOP (3) id,
       1.05 + CAST(CHECKSUM(NEWID()) & 2147483647 AS FLOAT) / 2147483648 * 0.10 AS factor
INTO #price_changes
FROM dbo.Products
ORDER BY NEWID();

BEGIN TRANSACTION;

UPDATE u
SET city = c.city, updated_at = @now
FROM dbo.Users AS u
JOIN #moves AS m ON m.id = u.id
JOIN (VALUES
    (1, N'Lima'), (2, N'Arequipa'), (3, N'Trujillo'), (4, N'Chiclayo'), (5, N'Piura'),
    (6, N'Cusco'), (7, N'Huancayo'), (8, N'Ica'), (9, N'Iquitos'), (10, N'Tacna')
) AS c (city_index, city) ON c.city_index = m.city_index
WHERE c.city <> ISNULL(u.city, N'');  -- si le tocó la misma ciudad, no hay nada que versionar

-- Precio nuevo terminado en .90 (p. ej. 249.90 -> 274.90)
UPDATE p
SET price = CEILING(p.price * c.factor) - 0.10, updated_at = @now
FROM dbo.Products AS p
JOIN #price_changes AS c ON c.id = p.id;

UPDATE dbo.Products
SET category = CASE category WHEN 'home' THEN 'sports' ELSE 'home' END, updated_at = @now
WHERE name = N'Botella térmica 1 L';

COMMIT TRANSACTION;

-- Verificación: lo que cambió en esta ejecución
SELECT 'Users' AS tabla, CAST(id AS NVARCHAR(36)) AS id, city AS valor_nuevo
FROM dbo.Users WHERE updated_at = @now
UNION ALL
SELECT 'Products', name, CONCAT(category, ' / ', price)
FROM dbo.Products WHERE updated_at = @now;
