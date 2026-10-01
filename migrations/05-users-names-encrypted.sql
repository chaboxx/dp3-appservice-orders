/* =========================================================
   Always Encrypted: Users.first_name y Users.last_name
   ---------------------------------------------------------
   YA APLICADO en Azure (1 de octubre de 2026), con la Web App detenida, desde el Query Editor.
   Requiere las llaves de 04-always-encrypted-keys.sql.

   Las columnas se recrearon vacías en vez de cifrar los datos existentes (que exige SSMS):
   los nombres no son datos originales, se copian del token de Entra (given_name / family_name)
   y la app los vuelve a escribir, ya cifrados, en el siguiente request de cada usuario.
   Con datos que no se puedan recuperar de otro lado, usar el asistente "Encrypt Columns" de SSMS.

   - RANDOMIZED: el mismo nombre se cifra distinto cada vez (no se ven repetidos). Sin enclaves no
     permite WHERE, ORDER BY, LIKE, índices ni estadísticas sobre estas columnas.
   - Latin1_General_BIN2: Always Encrypted exige collation _BIN2 en texto cifrado. La base y el
     resto de columnas (incluido email) siguen con SQL_Latin1_General_CP1_CI_AS.
   - Las columnas quedan al final de la tabla; para la app no importa.
   ========================================================= */
SET XACT_ABORT ON;
BEGIN TRANSACTION;

ALTER TABLE dbo.Users DROP COLUMN first_name, last_name;

ALTER TABLE dbo.Users ADD
    first_name NVARCHAR(200) COLLATE Latin1_General_BIN2
        ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = CEK_UsersNames,
                        ENCRYPTION_TYPE = RANDOMIZED,
                        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
    last_name NVARCHAR(200) COLLATE Latin1_General_BIN2
        ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = CEK_UsersNames,
                        ENCRYPTION_TYPE = RANDOMIZED,
                        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL;

COMMIT TRANSACTION;

-- Verificación: 2 filas RANDOMIZED / Latin1_General_BIN2
SELECT name, encryption_type_desc, collation_name
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.Users') AND encryption_type IS NOT NULL;
