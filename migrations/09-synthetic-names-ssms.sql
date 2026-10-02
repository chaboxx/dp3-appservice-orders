/* =========================================================
   Nombres para los clientes sintéticos de 07 (opcional; NO es un cambio de esquema)
   ---------------------------------------------------------
   first_name / last_name están cifrados con Always Encrypted: el valor se cifra en el CLIENTE,
   así que este script NO funciona en el Query Editor del portal. Ejecutarlo en SSMS con:
     1. Conexión con "Enable Always Encrypted (column encryption)"
        (Connect > Options > pestaña Always Encrypted).
     2. Query > Query Options > Execution > Advanced > "Enable Parameterization for Always Encrypted".
     3. Acceso a la llave orders-pii-kek de dp3-kv-crypto (SSMS pide iniciar sesión en Azure).
   SSMS convierte cada DECLARE ... = N'literal' en un parámetro y lo cifra antes de enviarlo.
   Reglas de esa conversión: declarar e inicializar en la misma línea, con un literal (no una
   expresión ni un SELECT) y del mismo tipo que la columna (NVARCHAR(200)). Por eso hay un bloque
   por cliente: los valores no pueden salir de otra tabla, porque SQL Server no tiene la llave.

   - Clientes cliente0001..cliente0250 de 07; los que no existan simplemente no se actualizan.
   - Sin apellido no se toca last_name: queda NULL desde 07.
   - Nombres y apellidos peruanos comunes, a propósito con datos "sucios" para la lógica del ETL:
     ~10% en minúsculas, MAYÚSCULAS o con espacios de más, ~15% con un solo apellido y ~4% sin
     apellido.
   - Pone updated_at: así la carga incremental los ve aunque ya hayas cargado 07.
   - Archivo generado (semilla fija): mismo resultado cada vez que se ejecuta.
   ========================================================= */
SET NOCOUNT ON;
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Flores Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0001@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José Luis';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0002@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0003@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José Luis';
DECLARE @last_name  NVARCHAR(200) = N'Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0004@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0005@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María Fernanda';
DECLARE @last_name  NVARCHAR(200) = N'García Vásquez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0006@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Gabriela';
DECLARE @last_name  NVARCHAR(200) = N'Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0007@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Pedro';
DECLARE @last_name  NVARCHAR(200) = N'Ramos Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0008@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jesús';
DECLARE @last_name  NVARCHAR(200) = N'Chávez Vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0009@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Salazar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0010@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Medina Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0011@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carmen';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0012@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0013@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0014@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carmen';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0015@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0016@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Elena';
DECLARE @last_name  NVARCHAR(200) = N'Medina Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0017@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan';
DECLARE @last_name  NVARCHAR(200) = N'Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0018@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Elena';
DECLARE @last_name  NVARCHAR(200) = N'Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0019@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0020@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Daniela';
DECLARE @last_name  NVARCHAR(200) = N'Silva Vásquez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0021@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0022@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Patricia';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0023@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Elena';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0024@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Víctor';
DECLARE @last_name  NVARCHAR(200) = N'García Salazar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0025@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Silva Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0026@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Pedro';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0027@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0028@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Kevin';
DECLARE @last_name  NVARCHAR(200) = N'Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0029@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0030@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0031@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0032@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María José';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0033@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0034@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0035@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Valeria';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0036@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Patricia';
DECLARE @last_name  NVARCHAR(200) = N'Paredes Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0037@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0038@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0039@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sebastián';
DECLARE @last_name  NVARCHAR(200) = N'Salazar Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0040@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0041@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Castillo Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0042@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0043@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0044@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sebastián';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0045@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Herrera';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0046@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Milagros';
DECLARE @last_name  NVARCHAR(200) = N'Quispe García';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0047@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0048@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Pedro';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0049@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'García Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0050@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Claudia';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0051@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Christian';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0052@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0053@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diego';
DECLARE @last_name  NVARCHAR(200) = N'Medina Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0054@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rodrigo';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0055@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María';
DECLARE @last_name  NVARCHAR(200) = N'García Rojas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0056@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sofía';
DECLARE @last_name  NVARCHAR(200) = N'Chávez Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0057@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Camila';
DECLARE @last_name  NVARCHAR(200) = N'Flores Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0058@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María José';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0059@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0060@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'Córdova Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0061@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0062@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'García Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0063@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carmen';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0064@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sofía';
DECLARE @last_name  NVARCHAR(200) = N'García Salazar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0065@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0066@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0067@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0068@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Valeria';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0069@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0070@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sofía';
DECLARE @last_name  NVARCHAR(200) = N'Córdova Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0071@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Medina Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0072@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0073@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jesús';
DECLARE @last_name  NVARCHAR(200) = N'Ramos Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0074@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María José';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0075@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  Lucía ';
DECLARE @last_name  NVARCHAR(200) = N'  Córdova  Gonzales ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0076@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'carmen';
DECLARE @last_name  NVARCHAR(200) = N'rodríguez vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0077@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diego';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0078@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'JIMENA';
DECLARE @last_name  NVARCHAR(200) = N'ROJAS GONZALES';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0079@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0080@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Gabriela';
DECLARE @last_name  NVARCHAR(200) = N'Córdova Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0081@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María José';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0082@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0083@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jesús';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0084@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Patricia';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Medina';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0085@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Flores Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0086@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'LUIS MIGUEL';
DECLARE @last_name  NVARCHAR(200) = N'MENDOZA ROJAS';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0087@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jorge';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Torres';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0088@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0089@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0090@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0091@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Mamani Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0092@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'García Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0093@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Huamán Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0094@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Salazar Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0095@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Castillo García';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0096@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0097@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Córdova Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0098@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'rodrigo';
DECLARE @last_name  NVARCHAR(200) = N'ríos córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0099@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Patricia';
DECLARE @last_name  NVARCHAR(200) = N'Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0100@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'CAMILA';
DECLARE @last_name  NVARCHAR(200) = N'VARGAS VÁSQUEZ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0101@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'josé luis';
DECLARE @last_name  NVARCHAR(200) = N'castillo gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0102@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rodrigo';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0103@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sebastián';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0104@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Claudia';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0105@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'SEBASTIÁN';
DECLARE @last_name  NVARCHAR(200) = N'TORRES PAREDES';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0106@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'García';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0107@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'García Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0108@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Camila';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0109@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Bruno';
DECLARE @last_name  NVARCHAR(200) = N'Paredes Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0110@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'diana';
DECLARE @last_name  NVARCHAR(200) = N'aguilar castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0111@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rodrigo';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0112@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Claudia';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0113@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0114@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sofía';
DECLARE @last_name  NVARCHAR(200) = N'Huamán Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0115@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0116@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0117@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0118@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María';
DECLARE @last_name  NVARCHAR(200) = N'Torres Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0119@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Christian';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0120@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Flores Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0121@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0122@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'carlos';
DECLARE @last_name  NVARCHAR(200) = N'mendoza medina';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0123@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0124@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0125@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0126@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diego';
DECLARE @last_name  NVARCHAR(200) = N'Torres Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0127@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Huamán Torres';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0128@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  Sofía ';
DECLARE @last_name  NVARCHAR(200) = N'  Rojas ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0129@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0130@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0131@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Pedro';
DECLARE @last_name  NVARCHAR(200) = N'Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0132@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0133@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0134@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Víctor';
DECLARE @last_name  NVARCHAR(200) = N'García Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0135@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Claudia';
DECLARE @last_name  NVARCHAR(200) = N'Medina';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0136@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'Torres Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0137@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Daniela';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0138@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  Sebastián ';
DECLARE @last_name  NVARCHAR(200) = N'  Castillo  Quispe ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0139@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0140@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fiorella';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0141@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'bruno';
DECLARE @last_name  NVARCHAR(200) = N'paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0142@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Patricia';
DECLARE @last_name  NVARCHAR(200) = N'Flores Pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0143@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza Salazar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0144@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Ramos Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0145@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Kevin';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0146@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luz';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0147@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jimena';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0148@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Medina Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0149@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María Fernanda';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0150@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0151@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0152@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Mamani Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0153@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Elena';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0154@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'PATRICIA';
DECLARE @last_name  NVARCHAR(200) = N'AGUILAR CRUZ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0155@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0156@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0157@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0158@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Flores Torres';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0159@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Rojas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0160@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María José';
DECLARE @last_name  NVARCHAR(200) = N'Medina Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0161@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jorge';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Torres';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0162@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Mamani Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0163@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'josé';
DECLARE @last_name  NVARCHAR(200) = N'medina castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0164@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0165@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0166@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luz';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0167@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Torres Quispe';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0168@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carmen';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0169@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Bruno';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0170@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0171@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Paredes García';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0172@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  José ';
DECLARE @last_name  NVARCHAR(200) = N'  Córdova  Gutiérrez ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0173@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'milagros';
DECLARE @last_name  NVARCHAR(200) = N'sánchez pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0174@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0175@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Mamani Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0176@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'García';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0177@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jimena';
DECLARE @last_name  NVARCHAR(200) = N'Silva Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0178@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Elena';
DECLARE @last_name  NVARCHAR(200) = N'Ramos Gonzales';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0179@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0180@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Christian';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0181@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rodrigo';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0182@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana';
DECLARE @last_name  NVARCHAR(200) = N'Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0183@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Piero';
DECLARE @last_name  NVARCHAR(200) = N'Flores Medina';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0184@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0185@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José Luis';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0186@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0187@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana';
DECLARE @last_name  NVARCHAR(200) = N'García Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0188@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Kevin';
DECLARE @last_name  NVARCHAR(200) = N'Aguilar Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0189@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diego';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0190@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0191@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  Pedro ';
DECLARE @last_name  NVARCHAR(200) = N'  Vásquez ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0192@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luz';
DECLARE @last_name  NVARCHAR(200) = N'Torres Cruz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0193@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Medina Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0194@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana Lucía';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Herrera';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0195@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Mendoza Rodríguez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0196@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'carlos';
DECLARE @last_name  NVARCHAR(200) = N'rojas garcía';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0197@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Miguel';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0198@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Milagros';
DECLARE @last_name  NVARCHAR(200) = N'Torres';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0199@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carmen';
DECLARE @last_name  NVARCHAR(200) = N'Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0200@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0201@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'  Rosa ';
DECLARE @last_name  NVARCHAR(200) = N'  Pérez  Díaz ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0202@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Milagros';
DECLARE @last_name  NVARCHAR(200) = N'Silva Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0203@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0204@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0205@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0206@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0207@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Diana';
DECLARE @last_name  NVARCHAR(200) = N'Torres Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0208@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'carlos';
DECLARE @last_name  NVARCHAR(200) = N'vargas rojas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0209@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Alonso';
DECLARE @last_name  NVARCHAR(200) = N'Vargas Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0210@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'GABRIELA';
DECLARE @last_name  NVARCHAR(200) = N'DÍAZ RODRÍGUEZ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0211@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0212@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ana';
DECLARE @last_name  NVARCHAR(200) = N'Sánchez Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0213@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rodrigo';
DECLARE @last_name  NVARCHAR(200) = N'Paredes';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0214@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'DANIELA';
UPDATE dbo.Users
SET first_name = @first_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0215@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sofía';
DECLARE @last_name  NVARCHAR(200) = N'Medina Castillo';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0216@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Milagros';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0217@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Fernando';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Chávez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0218@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Bruno';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0219@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Christian';
DECLARE @last_name  NVARCHAR(200) = N'Espinoza Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0220@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María Fernanda';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0221@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jorge';
DECLARE @last_name  NVARCHAR(200) = N'Córdova';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0222@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Rosa';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0223@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Camila';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0224@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Carlos';
DECLARE @last_name  NVARCHAR(200) = N'Ramírez Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0225@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Valeria';
DECLARE @last_name  NVARCHAR(200) = N'Rojas Gutiérrez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0226@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José Luis';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Silva';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0227@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'José';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0228@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'RENZO';
DECLARE @last_name  NVARCHAR(200) = N'RAMÍREZ MEDINA';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0229@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'fernando';
DECLARE @last_name  NVARCHAR(200) = N'quispe flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0230@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Camila';
DECLARE @last_name  NVARCHAR(200) = N'Vásquez Huamán';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0231@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Daniela';
DECLARE @last_name  NVARCHAR(200) = N'Gutiérrez Ríos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0232@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'JIMENA';
DECLARE @last_name  NVARCHAR(200) = N'VARGAS RODRÍGUEZ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0233@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'LUZ';
DECLARE @last_name  NVARCHAR(200) = N'GONZALES QUISPE';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0234@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Juan';
DECLARE @last_name  NVARCHAR(200) = N'Ramos Vargas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0235@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'ALONSO';
DECLARE @last_name  NVARCHAR(200) = N'MEDINA QUISPE';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0236@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'MIGUEL';
DECLARE @last_name  NVARCHAR(200) = N'ROJAS';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0237@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'María';
DECLARE @last_name  NVARCHAR(200) = N'Cruz Mamani';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0238@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Kevin';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Mendoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0239@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'DIANA';
DECLARE @last_name  NVARCHAR(200) = N'PÉREZ';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0240@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Sebastián';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Díaz';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0241@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Bruno';
DECLARE @last_name  NVARCHAR(200) = N'Pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0242@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Camila';
DECLARE @last_name  NVARCHAR(200) = N'Pérez Flores';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0243@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Ximena';
DECLARE @last_name  NVARCHAR(200) = N'Gonzales Pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0244@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Martín';
DECLARE @last_name  NVARCHAR(200) = N'Torres Pérez';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0245@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Valeria';
DECLARE @last_name  NVARCHAR(200) = N'Quispe Rojas';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0246@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Andrea';
DECLARE @last_name  NVARCHAR(200) = N'Herrera Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0247@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Luis';
DECLARE @last_name  NVARCHAR(200) = N'Díaz Aguilar';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0248@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Jesús';
DECLARE @last_name  NVARCHAR(200) = N'Ríos Espinoza';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0249@dp3-synthetic.test';
GO

DECLARE @first_name NVARCHAR(200) = N'Renzo';
DECLARE @last_name  NVARCHAR(200) = N'Huamán Ramos';
UPDATE dbo.Users
SET first_name = @first_name, last_name = @last_name, updated_at = SYSUTCDATETIME()
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000' AND email = N'cliente0250@dp3-synthetic.test';
GO

-- Verificación (con Always Encrypted habilitado en la conexión: se ven los nombres; sin él, binario)
SELECT TOP (20) email, first_name, last_name, city
FROM dbo.Users
WHERE entra_tenant_id = 'DA7A0000-5EED-4000-8000-000000000000'
ORDER BY email;
