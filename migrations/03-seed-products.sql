/* =========================================================
   Productos de prueba (opcional): sin productos no se puede crear ninguna orden.
   ========================================================= */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

INSERT INTO dbo.Products (name, price, stock, category)
VALUES
    (N'Teclado mecánico',     249.90,  50, 'electronics'),
    (N'Mouse inalámbrico',     79.90, 100, 'electronics'),
    (N'Monitor 27"',         1199.00,  20, 'electronics'),
    (N'Taza de café',          25.00, 200, 'home'),
    (N'Cuaderno A5',           12.50, 300, 'stationery');

COMMIT TRANSACTION;

SELECT id, name, price, stock, category FROM dbo.Products ORDER BY name;
