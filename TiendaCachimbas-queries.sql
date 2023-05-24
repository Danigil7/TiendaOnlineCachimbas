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
		
	
	-- Nos muestra los datos de la tabla detallepedidos de los pedidos que estan pendientes
    	select d
    	from pedidos p 
    	inner join detallespedido d on p.ID = d.PedidoID
    	where p.Estado = 'Pendiente';
	
	
		SELECT *
		FROM detallespedido dp
		inner join pedidos p on dp.PedidoID = p.ID  
		WHERE PedidoID IN (
    		SELECT ID
   			FROM pedidos
    		WHERE Estado = 'Pendiente'
		);

	
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

       
-- PROCEDIMIENTOS --
	
	-- 1. Procedimiento que hace mete datos random a los ProductosID de la tabla Comentarios. Es un bucle que va aumentando el indice          hasta que este llegue a mil.
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

	
    -- 2. Procedimiento que muestra los datos de los productos de tipo "Moderna" usando cursores:
        create procedure ObtenerProductosPorTipo(in tipo_producto varchar(30))
        begin
            declare done INT DEFAULT FALSE;
            declare producto_id INT;
            declare producto_nombre VARCHAR(100);
            declare producto_precio DECIMAL(10, 2);
            declare producto_stock INT;
            
            declare productos_cursor cursor for
            
            select ID, Nombre, Precio, Stock
            from Productos
            where Tipo = tipo_producto;
            
            declare continue HANDLER for not found set done = true;
            
            create temporary table TempProductos (
                ID INT,
                Nombre VARCHAR(100),
                Precio DECIMAL(10, 2),
                Stock INT
            );
            
            open productos_cursor;
            
            fetch productos_cursor into producto_id, producto_nombre, producto_precio, producto_stock;
            
            cursor_loop: loop
                insert into TempProductos (ID, Nombre, Precio, Stock)
                values (producto_id, producto_nombre, producto_precio, producto_stock);
                
                fetch productos_cursor into producto_id, producto_nombre, producto_precio, producto_stock;
                
                if done THEN
                    LEAVE cursor_loop;
                end if;
            end loop cursor_loop;
            
            close productos_cursor;
        
            select * from TempProductos;
            
            drop temporary table if exists TempProductos;
        end $$
        
        delimiter ;
        
        call ObtenerProductosPorTipo('Moderna');



	-- 3. Procedimiento que hace uso de una función (la función calcula el promedio de los precios de los productos de la tabla            'Productos' y lo devuelve como resultado.):
	
        use TiendaOnlineCachimbas;
        DROP PROCEDURE IF EXISTS MostrarMediaPrecios;
        delimiter &&
        create procedure MostrarMediaPrecios()
        begin
        
            declare media decimal(10, 2);
            
            set media = CalcularMediaPrecios();
            
            select media AS 'Media de precios';
            
        end &&
        delimiter ;

	    call MostrarMediaPrecios();
	
	
	
	
-- FUNCIONES --

    -- 1. Esta función calcula el promedio de los precios de los productos de la tabla 'Productos' y lo devuelve como resultado.

        use TiendaOnlineCachimbas;
        DROP function IF EXISTS CalcularMediaPrecios;
        delimiter &&
        create function CalcularMediaPrecios() returns decimal(10, 2)
        begin
        
            declare promedio decimal(10, 2);
            
            select AVG(Precio) into promedio
            from Productos;
            
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

        select ObtenerCantidadComentarios(1);
        
        
-- TRIGGERS --

    -- 1. Se activa después de insertar una fila en la tabla DetallesPedido. El trigger actualiza el stock del producto correspondiente     restando la cantidad insertada.

        use TiendaOnlineCachimbas;
        
        DROP trigger IF EXISTS ActualizarStock;
        delimiter &&
        create trigger ActualizarStock
        after insert on DetallesPedido
        for each row
        begin
        
            declare cantidad int;
            
            select Cantidad into cantidad
            from DetallesPedido
            where ID = NEW.ID;
            
            update Productos
            set Stock = Stock - cantidad
            where ID = new.ProductoID;
            
        end &&
        delimiter ;

        
    -- 2. Este trigger se ejecutará antes de cada inserción en la tabla "Clientes" y verificará si el campo "Email" está en blanco o es nulo. Si el campo "Email" está vacío o nulo, el valor de la columna "Invitado" se establecerá en 'Cliente invitado'. De lo contrario, el valor de la columna "Invitado" se establecerá en 'Cliente no invitado'.


        use TiendaOnlineCachimbas;
        
        drop trigger if exists ActualizarInvitado;
        delimiter &&
        create trigger ActualizarInvitado
        before insert on Clientes
        for each row
        begin
            if new.Email = '' OR new.Email is null then
                set new.Invitado = 'Cliente invitado';
            else
                set new.Invitado = 'Cliente no invitado';
            end if;
        end &&
        delimiter ;