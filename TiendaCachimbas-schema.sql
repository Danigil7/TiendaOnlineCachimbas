drop database if exists TiendaOnlineCachimbas;
create database TiendaOnlineCachimbas character set utf8mb4;
use TiendaOnlineCachimbas;

CREATE TABLE Productos (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(100),
    Tipo VARCHAR(30),
    Descripcion TEXT,
    Precio DECIMAL(10, 2),
    Stock INT
);

CREATE TABLE Clientes (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(100),
    Direccion VARCHAR(100),
    Telefono VARCHAR(15),
    Email VARCHAR(100),
    Invitado INT,
    FOREIGN KEY (Invitado) REFERENCES Clientes(ID)
);

CREATE TABLE Pedidos (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    ClienteID INT,
    Fecha DATE,
    Estado ENUM('Pendiente', 'En proceso', 'Enviado', 'Entregado') DEFAULT 'Pendiente',
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ID)
);

CREATE TABLE DetallesPedido (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PedidoID INT,
    ProductoID INT,
    Cantidad INT,
    Precio DECIMAL(10, 2),
    FOREIGN KEY (PedidoID) REFERENCES Pedidos(ID),
    FOREIGN KEY (ProductoID) REFERENCES Productos(ID)
);

CREATE table Comentarios (
	ID INT PRIMARY KEY AUTO_INCREMENT,
	Contenido Varchar (200),
	Valoracion ENUM('1', '2', '3', '4', '5'),
	Fecha DATE,
	ClientesID INT,
	ProductosID INT,
	foreign key (ClientesID) references Clientes(ID),
	foreign key (ProductosID) references Productos(ID)
);








