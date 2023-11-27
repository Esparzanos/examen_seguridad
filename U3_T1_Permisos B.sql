/*Crear las siguientes Base de Datos:
Nombre: BD1
Tablas:
clientes: cte, nombre, domicilio
Empleados: emp, nombre, domicilio, teléfono
Ventas: folio, fecha, cte, emp*/

CREATE DATABASE BD1
GO
USE BD1
GO
CREATE TABLE CLIENTES(
CTE INT, 
NOMBRE VARCHAR(25),
DOMICILIO VARCHAR(50) )

CREATE TABLE EMPLEADOS(
EMP INT, 
NOMBRE VARCHAR(25),
DOMICILIO VARCHAR(50),
TELEFONO VARCHAR(10))

CREATE TABLE VENTAS(
FOLIO INT,
FECHA DATE,
CTE INT,
EMP INT)

/*Nombre: BD2
Tablas:
Productos: prod, nombre, cat, precio
Categorias: cat, nombre
Ventas: folio, fecha, prod, cantidad, precio */
CREATE DATABASE BD2
GO
USE BD2
GO
CREATE TABLE PRODUCTOS(
PROD INT, 
NOMBRE VARCHAR(25),
CAT INT, 
PRECIO MONEY)

CREATE TABLE CATEGORIA(
CAT INT, 
NOMBRE VARCHAR(25))

CREATE TABLE VENTAS(
FOLIO INT,
FECHA DATE,
PROD INT,
CANTIDAD INT,
PRECIO MONEY)

--1.- Dar de alta al IS ALMA pueda apagar el servidor con el comando SHUTDOWN.
CREATE LOGIN ALMA WITH PASSWORD='123'
GO 
sp_addSRVRoleMeMber ALMA, SERVERADMIN
GO

--2.- Dar de alta al IS JUAN para que pueda auxiliar en la administración de inicios de sesión, que pueda dar de alta inicios de sesión y cambiar password.
CREATE LOGIN JUAN WITH PASSWORD='234'
GO
sp_addSRVRoleMeMber JUAN, SECURITYADMIN
GO

--3.- Dar de alta al IS JOSE y configurarlo para que tenga las mismas características que el inicio de sesión SA.
CREATE LOGIN JOSE WITH PASSWORD='345'
GO
sp_addSRVRoleMember JOSE, sysadmin

--4.- Dar de alta al IS PEDRO para que pueda seleccionar y modificar (I/U/D) todas las tablas de las bases de datos BD1 y BD2.
CREATE LOGIN PEDRO WITH PASSWORD='456'
GO
USE BD1
CREATE USER PEDRO 
WITH DEFAULT_SCHEMA = DBO
GO
sp_AddRoleMember 'db_datawriter', PEDRO
GO
sp_AddRoleMember 'db_DataReader', PEDRO

USE BD2
CREATE USER PEDRO 
WITH DEFAULT_SCHEMA = DBO
GO
sp_AddRoleMember 'db_datawriter', PEDRO
GO
sp_AddRoleMember 'db_DataReader', PEDRO

--5.- Dar de alta al IS NORA Y PERLA para que puedan crear todos los objetos en BD1.
CREATE LOGIN NORA WITH PASSWORD='567'
CREATE LOGIN PERLA WITH PASSWORD='678'

USE BD1
CREATE USER NORA
WITH DEFAULT_SCHEMA = DBO
CREATE USER PERLA 
WITH DEFAULT_SCHEMA = DBO
GO
sp_AddRoleMember 'db_ddlAdmin', NORA
GO
/*6.- En la base de datos BD1 crear la función CONSULTA y darle permiso para que pueda seleccionar solo las 2 primeras columnas de cada tabla.
A los IS NORA Y PERLA creados en el punto 6, agregarlos en la función CONSULTA de la base de datos BD1.*/
USE BD1
GO
CREATE ROLE CONSULTA;
GRANT SELECT ON clientes(cte, nombre) TO CONSULTA;
GRANT SELECT ON Empleados(emp, nombre) TO CONSULTA;
GRANT SELECT ON Ventas(folio, fecha) TO CONSULTA;
GO
sp_AddRoleMember 'CONSULTA', NORA
GO
sp_AddRoleMember 'CONSULTA', PERLA

--7.- Dar de alta al IS CARLOS y que pueda insertar y eliminar datos en la BD2, además pueda crear vistas y tablas en la misma base de datos.
CREATE LOGIN CARLOS WITH PASSWORD='789'

USE BD2
CREATE USER CARLOS
WITH DEFAULT_SCHEMA = DBO

GRANT INSERT, DELETE TO CARLOS
GRANT CREATE VIEW, CREATE TABLE TO CARLOS
GO

/*8.- Es necesario crear los IS siguientes: asesor01, asesor02,… asesor80. Crear un procedimiento almacenado que los genere automáticamente con la 
característica que le cambien el password la primera vez que se conecten.*/
CREATE PROCEDURE CrearUsuarios
AS
BEGIN
    DECLARE @contador INT = 1
    DECLARE @Usuario NVARCHAR(50)
    DECLARE @SQL NVARCHAR(MAX)

    WHILE @contador <= 80
    BEGIN
        SET @Usuario = 'asesor' + RIGHT('00' + CAST(@contador AS NVARCHAR(2)), 2)
        SET @SQL = 'CREATE LOGIN [' + @Usuario + '] WITH PASSWORD = ''123'', CHECK_EXPIRATION = ON
                     CREATE USER [' + @Usuario + '] FOR LOGIN [' + @Usuario + ']'
        EXEC sp_executesql @SQL

        SET @contador = @contador + 1
    END
END
EXEC CrearUsuarios;
GOs

--9.- De los IS creados en el punto 8, crear un procedimiento almacenado que los de alta como usuario en la base de datos BD1.
USE BD1;
GO
CREATE PROCEDURE AgregarUsuarios
AS
BEGIN
    DECLARE @contador INT = 1
    DECLARE @Usuario NVARCHAR(50)
    DECLARE @SQL NVARCHAR(MAX)

    WHILE @contador <= 80
    BEGIN
        SET @Usuario = 'asesor' + RIGHT('00' + CAST(@contador AS NVARCHAR(2)), 2)
        SET @SQL = 'CREATE USER [' + @Usuario + '] WITH DEFAULT_SCHEMA = DBO'
        EXEC sp_executesql @SQL

        SET @contador = @contador + 1
    END
END
EXEC AgregarUsuarios;
GO
--10.- En la base de datos northwind cambiar el esquema DBO de todas tablas por el esquema RECURSOS utilizando un procedimiento almacenado.
USE Northwind
GO
CREATE SCHEMA RECURSOS;
GO
CREATE PROCEDURE CambiarEsquemaNorthwind
AS
BEGIN
    DECLARE @OldSchema NVARCHAR(128) = 'dbo';
    DECLARE @NewSchema NVARCHAR(128) = 'RECURSOS';
    
    DECLARE @TableName NVARCHAR(128);
    DECLARE @SchemaChangeQuery NVARCHAR(MAX);

    DECLARE TableCursor CURSOR FOR
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_CATALOG = 'Northwind' AND TABLE_SCHEMA = @OldSchema AND TABLE_TYPE = 'BASE TABLE';

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SchemaChangeQuery = 'ALTER SCHEMA ' + @NewSchema + ' TRANSFER ' + @OldSchema + '.' + @TableName;
        EXEC sp_executesql @SchemaChangeQuery;

        FETCH NEXT FROM TableCursor INTO @TableName;
    END
    CLOSE TableCursor;
    DEALLOCATE TableCursor;
END;


EXEC CambiarEsquemaNorthwind;

