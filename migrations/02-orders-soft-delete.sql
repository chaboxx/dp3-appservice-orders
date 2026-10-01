SET XACT_ABORT ON;
BEGIN TRANSACTION;

/* =========================================================
   Orders: soft delete
   NULL = orden activa; con fecha = borrada (no se muestra en la API)
   ========================================================= */
ALTER TABLE dbo.Orders
    ADD deleted_at DATETIME2 NULL;

COMMIT TRANSACTION;
