/* =========================================================
   Users.city: ciudad del cliente, copiada del claim "city" del token de Entra
   ---------------------------------------------------------
   La guarda el alta automática (_sync_profile) en cada request, igual que el email: si el
   usuario cambia su ciudad en Entra, la fila se actualiza (y updated_at también). Es el
   atributo que versiona la dimensión de clientes (SCD2) del ETL y permite ventas por ciudad.

   - Legible (sin Always Encrypted): el ETL agrupa por ella. NULL si el token no trae el claim.
   - NVARCHAR(128): el largo máximo de "city" en Entra.
   - Aplicar ANTES de desplegar la versión de la app que la usa: el ORM la incluye en cada
     SELECT de Users y sin la columna falla con "Invalid column name 'city'". La versión
     anterior de la app funciona igual con la columna ya creada.
   ========================================================= */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

ALTER TABLE dbo.Users
    ADD city NVARCHAR(128) NULL;

COMMIT TRANSACTION;
