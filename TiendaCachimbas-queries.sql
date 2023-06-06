use TiendaOnlineCachimbas;

-- CONSULTAS --
	
-- 1. obtener todos los productos junto con sus respectivos comentarios y la información del cliente que realizó cada comentario
select P.ID as ProductoID, P.Nombre as ProductoNombre, 
       C.ID as ClienteID, C.Nombre as ClienteNombre, 
       CO.Contenido, CO.Valoracion, CO.Fecha
from Productos P
left join Comentarios CO on P.ID = CO.ProductosID
left join Clientes C on CO.ClientesID = C.ID;



-- 2. Cuenta los comentarios de un producto específico a través de su ID
select p.Nombre , count(c.ID) 
from productos p 
inner join comentarios c on p.ID = c.ProductosID 
where c.ProductosID = 9;

-- 3. Muestra los productos que tienen mas de 3 comentarios
SELECT p.ID, p.Nombre, COUNT(c.ID) AS 'Número de comentarios'
FROM Productos p
LEFT JOIN Comentarios c ON p.ID = c.ProductosID
GROUP BY p.ID, p.Nombre
ORDER BY COUNT(c.ID) desc
LIMIT 1;

		
	
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
SELECT *
FROM DetallesPedido dp
inner join Pedidos p on dp.PedidoID = p.ID  
WHERE PedidoID IN (
	SELECT ID
	FROM Pedidos p
	WHERE p.Estado = 'Pendiente'
);



	
-- VISTAS --
	
-- 1. Vista con la consulta que muestra los productos que tienen mas de 3 comentarios
create view VistaComentarios as
SELECT p.ID, p.Nombre, COUNT(c.ID) AS 'Número de comentarios'
FROM Productos p
LEFT JOIN Comentarios c ON p.ID = c.ProductosID
GROUP BY p.ID, p.Nombre
ORDER BY COUNT(c.ID) desc
LIMIT 1;
       
select * from VistaComentarios;
	

-- 2. Vista con la subconsulta que calcula el promedio de precios de todos los productos en la tabla Productos. Luego, la consulta 
-- principal selecciona los nombres, precios y cantidades de stock de los productos cuyo precio es mayor que el promedio 
-- calculado en la subconsulta.
create view VistaMediaPrecio as
select Nombre, Precio, Stock
from Productos
where Precio > (
	select AVG(Precio)
	from Productos
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
	from Productos p ;
	            
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
from Comentarios c 
where ProductosID = producto_id;
return cantidad_comentarios;
            
end &&
delimiter ;

select ObtenerCantidadComentarios(1);
	
	
	
	
-- PROCEDIMIENTOS --
	
-- 1. Este procedimiento toma como parámetro el ID de un cliente y devuelve una lista de pedidos realizados 
-- por ese cliente, incluyendo información sobre la fecha del pedido, el estado, la cantidad de productos y 
-- los detalles de cada producto (nombre y precio).

DROP PROCEDURE IF EXISTS ObtenerPedidosPorCliente;
delimiter &&
create procedure ObtenerPedidosPorCliente(in clienteID int)
begin
    select p.ID, p.Fecha, p.Estado, dp.Cantidad, pr.Nombre, pr.Precio
    from Pedidos p
    inner join DetallesPedido dp ON p.ID = dp.PedidoID
    inner join Productos pr ON dp.ProductoID = pr.ID
    where p.ClienteID = clienteID;
end&&
delimiter ;

call ObtenerPedidosPorCliente(2);

	
-- 2. Este procedimiento muestra los productos agotados:

DROP PROCEDURE IF EXISTS obtener_productos_agotados;
DELIMITER &&

CREATE PROCEDURE obtener_productos_agotados()
BEGIN
    -- Variables para almacenar los datos del producto
    DECLARE producto_id INT;
    DECLARE producto_nombre VARCHAR(100);
    DECLARE producto_stock INT;
    
    -- Variable para almacenar el resultado
    DECLARE resultado VARCHAR(5000) DEFAULT '';
    
    -- Definir el cursor
    DECLARE productos_cursor CURSOR FOR
        SELECT p.ID , p.Nombre , p.Stock 
        FROM Productos p
        WHERE p.Stock = 0;
    
    -- Declarar un handler para evitar el error cuando no hay datos
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @done = 1;
    
    -- Abrir el cursor
    OPEN productos_cursor;
    
    -- Inicializar variable para controlar el fin del cursor
    SET @done = 0;
    
    -- Recorrer y concatenar los productos agotados
    product_loop: LOOP
        FETCH productos_cursor INTO producto_id, producto_nombre, producto_stock;
        IF @done THEN
            LEAVE product_loop;
        END IF;
        
        -- Concatenar el resultado
        SET resultado = CONCAT(resultado, 'Producto ID: ', producto_id, ', Nombre: ', producto_nombre, ', Stock: ', producto_stock, '\n');
    END LOOP;
    
    -- Cerrar el cursor
    CLOSE productos_cursor;
    
    -- Mostrar el resultado como un listado
    SELECT GROUP_CONCAT(resultado SEPARATOR '\n') AS ProductosAgotados;
    
END &&
DELIMITER ;
call obtener_productos_agotados();

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

CALL MostrarInfoProducto(1);


  
        
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


        
-- 2. Trigger para actualizar el stock después de insertar un nuevo detalle de pedido:

USE TiendaOnlineCachimbas;
        
DROP TRIGGER IF EXISTS ActualizarStock;
DELIMITER &&
CREATE TRIGGER ActualizarStock AFTER INSERT ON DetallesPedido
FOR EACH ROW
BEGIN
    UPDATE Productos
    SET Stock = Stock - NEW.Cantidad
    WHERE ID = NEW.ProductoID;
END&&
DELIMITER ;

insert into DetallesPedido values ('1001','2','2','1');


select *
from Productos p;









