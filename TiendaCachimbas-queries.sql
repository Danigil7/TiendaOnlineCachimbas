use TiendaOnlineCachimbas;

-- CONSULTAS --
	
-- 1. Obtener todos los productos con más de 20 unidades en stock
select * from productos where Stock > 50;

-- 2. Cuenta los comentarios de un producto específico a través de su ID
select p.Nombre , count(c.ID) 
from productos p 
inner join comentarios c on p.ID = c.ProductosID 
where c.ProductosID = 9;

-- 3. Muestra los productos que tienen mas de 3 comentarios
select p.ID, p.Nombre, count(c.ID) as 'Número de comentarios'
from productos p
inner join comentarios c on p.ID = c.ProductosID
group by p.ID, p.Nombre
having count(c.ID) > 3;
		
	
-- 4. La subconsulta calcula el promedio de precios de todos los productos en la tabla Productos. Luego, la consulta 
-- principal selecciona los nombres, precios y cantidades de stock de los productos cuyo precio es mayor que el promedio 
-- calculado en la subconsulta.
select Nombre, Precio, Stock
from productos 
where Precio > (
	select avg(Precio)
	from productos 
);
		
	
-- 5. Nos muestra los datos de la tabla detallepedidos de los pedidos que estan pendientes
select *
from pedidos p 
inner join detallespedido d on p.ID = d.PedidoID
where p.Estado = 'Pendiente';
	
	
SELECT *
FROM detallespedido dp
inner join pedidos p on dp.PedidoID = p.ID  
WHERE PedidoID IN (
	SELECT ID
	FROM pedidos p
	WHERE p.Estado = 'Pendiente'
);
	
	
SELECT *
FROM detallespedido dp
INNER JOIN pedidos p ON dp.PedidoID = p.ID
WHERE p.Estado LIKE '%Pendiente%';



	
-- VISTAS --
	
-- 1. Vista con la consulta que muestra los productos que tienen mas de 3 comentarios
create view VistaComentarios as
select p.ID, p.Nombre, count(c.ID) as 'Número de comentarios'
from productos p
inner join comentarios c on p.ID = c.ProductosID
group by p.ID, p.Nombre
having count(c.ID) > 3;
       
select * from VistaComentarios;
	

-- 2. Vista con la subconsulta que calcula el promedio de precios de todos los productos en la tabla Productos. Luego, la consulta 
-- principal selecciona los nombres, precios y cantidades de stock de los productos cuyo precio es mayor que el promedio 
-- calculado en la subconsulta.
create view VistaMediaPrecio as
select Nombre, Precio, Stock
from productos
where Precio > (
	select AVG(Precio)
	from productos
);
	
select * from VistaMediaPrecio;

 
	
-- FUNCIONES --

-- 1. Esta función calcula el promedio de los precios de los productos de la tabla 'Productos' y lo devuelve como resultado.

use TiendaOnlineCachimbas;
DROP function IF EXISTS CalcularMediaPrecios;
delimiter &&
create function CalcularMediaPrecios() returns decimal(10, 2)
begin
        
	declare promedio decimal(10, 2);
	            
	select avg(Precio) into promedio
	from productos;
	            
	return promedio;
            
end &&
delimiter ;

select CalcularMediaPrecios();


-- 2. Función que devuelve el número de comentarios que tiene el producto que le indiquemos
    
use TiendaOnlineCachimbas;
DROP function IF EXISTS ObtenerCantidadComentarios;
delimiter &&
create function ObtenerCantidadComentarios(producto_id int) returns int
begin
        
declare cantidad_comentarios int;

select count(*) into cantidad_comentarios
from comentarios
where ProductosID = producto_id;
return cantidad_comentarios;
            
end &&
delimiter ;

select ObtenerCantidadComentarios(72);
	
	
	
	
-- PROCEDIMIENTOS --
	
-- 1. Procedimiento que hace mete datos random a los ProductosID de la tabla Comentarios. Es un bucle que va aumentando el indice hasta que este llegue a mil.
       
DROP PROCEDURE IF EXISTS cargarrandom;
delimiter &&
create procedure cargarrandom()
begin
	declare i int default 0;
	declare r int;	
	while (i<1000) do
		select floor( RAND()*1000) into r;
		update comentarios c set c.ProductosID = r where c.ID = i;
		set i = i+1;
	end while;	
end &&
delimiter ;
		
call cargarrandom();

	
-- 2. Este procedimiento crea un cursor llamado "productos_cursor" para recorrer los 
-- registros de la tabla "Productos". Dentro del bucle, se recorre el cursor y se muestra el nombre de cada producto.

DROP PROCEDURE IF EXISTS obtener_productos_agotados;
DELIMITER &&
CREATE PROCEDURE obtener_productos_agotados()
BEGIN
    -- Variables para almacenar los datos del producto
    DECLARE producto_id INT;
    DECLARE producto_nombre VARCHAR(100);
    DECLARE producto_stock INT;
    
    -- Definir el cursor
    DECLARE productos_cursor CURSOR FOR
        SELECT p.ID , p.Nombre , p.Stock 
        FROM productos p
        WHERE p.Stock = '0';
    
    -- Abrir el cursor
    OPEN productos_cursor;
    
    -- Recorrer y mostrar los productos agotados
    FETCH productos_cursor INTO producto_id, producto_nombre, producto_stock;
    WHILE producto_id IS NOT NULL do
        -- Realizar acciones con el producto agotado
        SELECT CONCAT('Producto ID: ', producto_id, ', Nombre: ', producto_nombre, ', Stock: ', producto_stock) AS ProductoAgotado;
        
        -- Leer el siguiente valor del cursor
        FETCH productos_cursor INTO producto_id, producto_nombre, producto_stock;
    END WHILE;
    
    -- Cerrar el cursor
    CLOSE productos_cursor;
    
END &&
DELIMITER ;

CALL obtener_productos_agotados();


-- 3. Procedimiento que hace uso de una función (Función que devuelve el número de comentarios que tiene el producto que le indiquemos):
	
USE TiendaOnlineCachimbas;
DROP PROCEDURE IF EXISTS MostrarInfoProducto;
DELIMITER &&
CREATE PROCEDURE MostrarInfoProducto(IN producto_id INT)
BEGIN
    DECLARE cantidad_comentarios INT;
    DECLARE nombre_producto VARCHAR(100);
    
    SET cantidad_comentarios = ObtenerCantidadComentarios(producto_id);
    
    SET nombre_producto = (SELECT Nombre FROM productos WHERE ID = producto_id);
    
    SELECT nombre_producto AS 'Nombre del producto', cantidad_comentarios AS 'Cantidad de comentarios';
END &&
DELIMITER ;

CALL MostrarInfoProducto(72);


  
        
-- TRIGGERS --

-- 1. Se ejecuta antes de cada operación de inserción en la tabla "Pedidos". Actualiza la columna "Fecha" de la nueva fila que se está insertando con la fecha actual, obtenida utilizando la función CURDATE().

use TiendaOnlineCachimbas;
        
DROP trigger IF EXISTS actualizar_fecha_pedido;
DELIMITER &&
CREATE TRIGGER actualizar_fecha_pedido
BEFORE INSERT ON pedidos
FOR EACH ROW
BEGIN
    SET NEW.Fecha = CURDATE();
END &&
DELIMITER ;


        
-- 2. Este trigger se ejecutará antes de cada inserción en la tabla "Clientes" y verificará si el campo "Email" está en blanco o es nulo. Si el campo "Email" está vacío o nulo, el valor de la columna "Invitado" se establecerá en 'Cliente invitado'. De lo contrario, el valor de la columna "Invitado" se establecerá en 'Cliente no invitado'.

use TiendaOnlineCachimbas;
        
drop trigger if exists ActualizarInvitado;
delimiter &&
create trigger ActualizarInvitado
before insert on clientes
for each row
begin
	if new.Email = '' OR new.Email is null then
		set new.Invitado = 'Cliente invitado';
	else
		set new.Invitado = 'Cliente no invitado';
	end if;
end &&
delimiter ;