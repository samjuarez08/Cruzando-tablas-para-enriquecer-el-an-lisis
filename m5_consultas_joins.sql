/* ============================================================
   M5 - Pre-entrega: Consultas con JOINs
   Base: Ventas_Tech_DB (TechStore) - SQL Server
   Tablas: categorias, clientes, productos, ventas (+ regiones)
   ATENCION: ajustá los nombres de tablas/columnas a los de tu
   script del Checkpoint M3 (ventas_tech_db.sql).
   ============================================================ */

USE Ventas_Tech_DB;
GO

/* ------------------------------------------------------------
   PASO PREVIO (solo si tu esquema no tiene dimensión geográfica)
   Agregar al script del M3 una tabla regiones y la FK en clientes.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.regiones') IS NULL
BEGIN
    CREATE TABLE dbo.regiones (
        id_region     INT          NOT NULL PRIMARY KEY,
        nombre_region VARCHAR(50)  NOT NULL
    );

    INSERT INTO dbo.regiones (id_region, nombre_region) VALUES
        (1, 'NEA'),
        (2, 'Centro'),
        (3, 'Cuyo');

    ALTER TABLE dbo.clientes ADD id_region INT NULL;
    ALTER TABLE dbo.clientes
        ADD CONSTRAINT FK_clientes_regiones
        FOREIGN KEY (id_region) REFERENCES dbo.regiones (id_region);
END
GO

-- Asignar región a los clientes existentes (ejemplo: reparto simple)
UPDATE dbo.clientes
SET id_region = (id_cliente % 3) + 1
WHERE id_region IS NULL;
GO

/* ------------------------------------------------------------
   CONSULTA 1 - Vista base del proyecto (INNER JOIN)
   Ventas + cliente + producto + categoría + región en una fila.
   Fuente principal para Power BI.
   ------------------------------------------------------------ */
SELECT
    v.fecha_venta,
    c.id_cliente,
    c.nombre              AS cliente,
    r.nombre_region       AS region,
    p.nombre_producto     AS producto,
    cat.nombre_categoria  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario AS total_venta
FROM dbo.ventas      AS v
INNER JOIN dbo.clientes   AS c   ON c.id_cliente    = v.id_cliente
INNER JOIN dbo.productos  AS p   ON p.id_producto   = v.id_producto
INNER JOIN dbo.categorias AS cat ON cat.id_categoria = p.id_categoria
INNER JOIN dbo.regiones   AS r   ON r.id_region     = c.id_region
ORDER BY v.fecha_venta;
GO

/* ------------------------------------------------------------
   CONSULTA 2 - Clientes sin ventas (LEFT JOIN + IS NULL)
   ------------------------------------------------------------ */
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM dbo.clientes AS c
LEFT JOIN dbo.ventas AS v ON v.id_cliente = c.id_cliente
WHERE v.id_venta IS NULL;
GO

/* ------------------------------------------------------------
   CONSULTA 3 - Productos sin ventas (LEFT JOIN + IS NULL)
   ------------------------------------------------------------ */
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM dbo.productos AS p
INNER JOIN dbo.categorias AS cat ON cat.id_categoria = p.id_categoria
LEFT JOIN dbo.ventas AS v ON v.id_producto = p.id_producto
WHERE v.id_venta IS NULL;
GO

/* ------------------------------------------------------------
   CONSULTA 4 - Consolidado por canal (UNION ALL)
   'canal' NO existe en las tablas: se crea como literal en cada
   SELECT. Criterio de separación: dos períodos (ajustá las fechas
   a tus datos). Ambos SELECT: mismas columnas, mismo orden y tipos.
   ------------------------------------------------------------ */
SELECT
    canal,
    SUM(total) AS total_canal
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Online' AS canal
    FROM dbo.ventas
    WHERE fecha_venta <  '2025-07-01'

    UNION ALL

    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Presencial' AS canal
    FROM dbo.ventas
    WHERE fecha_venta >= '2025-07-01'
) AS consolidado
GROUP BY canal;
GO
