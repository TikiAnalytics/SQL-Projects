--Primero modifico la columna "ID_Director" de la tabla Directores para que no permita valores nulos,
--para luego transformarla en primary key:
ALTER TABLE Directores
ALTER COLUMN ID_Director INT NOT NULL;

-- Ahora transformo la columna "ID_Director" en primary key:
ALTER TABLE Directores
ADD CONSTRAINT PK_Director PRIMARY KEY (ID_Director);

--Ahora realizo lo mismo en la tabla "Películas" con la columna "ID_Peliculas" para transformarla en primary key, 
--y también modifico "ID_Director" como clave foránea, para terminar de normalizar la base de datos.
ALTER TABLE Peliculas
ALTER COLUMN ID_Pelicula INT NOT NULL;

ALTER TABLE Peliculas
ADD CONSTRAINT PK_Pelicula PRIMARY KEY (ID_Pelicula);

ALTER TABLE Peliculas
ALTER COLUMN ID_Director INT;

-- Creo la Foreign Key:
ALTER TABLE Peliculas
ADD CONSTRAINT FK_Peliculas_Directores
FOREIGN KEY (ID_Director)
REFERENCES Directores(ID_Director);

--Utilicé esta sentencia para corroborar una inconsistencia que no permitia contar todos los registros de cada género
SELECT Género, COUNT(*)
FROM peliculas
GROUP BY Género
HAVING Género LIKE '%Ciencia%';

--Determiné la inconsistencia: había espacios en blanco delante de algunas cadenas de caracteres, por lo que los eliminé con la siguiente sentencia:
UPDATE peliculas
SET Género = LTRIM(RTRIM(Género));

--Selecciono los cinco géneros con más películas de la lista.
SELECT TOP 5 COUNT(ID_Pelicula) AS Cantidad_Peliculas, Género
FROM Peliculas
GROUP BY Género
ORDER BY COUNT(ID_Pelicula) DESC;

--Ahora selecciono los géneros y la calificación promedio,
--para ver si hay una correlación entre la cantidad y la calidad de los géneros:
SELECT ROUND(AVG(Calificacion_Promedio),2) AS Calificacion_promedio, Género
FROM Peliculas
GROUP BY Género
ORDER BY AVG(Calificacion_Promedio) DESC;

--Por último y para terminar con los géneros, selecciono los géneros, y realizo calculos para el promedio de sus presupuestos,
--ganancias y finalmente un cálculo para analizar al beneficio.
SELECT TOP 5 Género, ROUND(AVG(Presupuesto),2) AS Presupuesto_promedio, 
ROUND(AVG(Ingresos),2) AS Ingresos_promedio,
ROUND((AVG(Ingresos)-AVG(Presupuesto)),2) AS Beneficio_Promedio
FROM Peliculas
GROUP BY Género
ORDER BY (AVG(Ingresos)-AVG(Presupuesto)) DESC;

--cree una expresión de tabla común en la que utilicé la función “ROW_NUMBER” para asignar un numero de fila a cada género,
--ordenando las películas por la calificación promedio de mayor a menor, lo que le da a cada película dentro de los géneros un ranking basado en su calificación.
--Luego basé la consulta principal en esta tabla, seleccionando solo las películas con el ranking 1, es decir, la película con la calificación más alta de cada género
WITH RankingPeliculas AS (
SELECT Titulo, Género, Calificacion_Promedio,
ROW_NUMBER() OVER (PARTITION BY Género ORDER BY Calificacion_Promedio DESC) AS Ranking
FROM Peliculas)
SELECT Titulo, Género, Calificacion_Promedio
FROM RankingPeliculas
WHERE Ranking = 1
ORDER BY Calificacion_Promedio DESC;

--Consulta simple que me permite visualizar las diez películas que más beneficios tuvieron.
SELECT TOP 10 Titulo, Género, ROUND(Ingresos-Presupuesto,2) AS Beneficios
FROM Peliculas
ORDER BY Beneficios DESC;

--siguiendo con los directores:

--ésta consulta me permite visualizar cuáles son los directores con más películas realizadas por género.
WITH RankingDirectores AS(
SELECT 
COUNT(Peliculas.ID_Pelicula) AS Cantidad_peliculas,
Peliculas.Género,
Directores.Nombre,
ROW_NUMBER() OVER (PARTITION BY Peliculas.Género ORDER BY COUNT(Peliculas.ID_Pelicula) DESC) AS Ranking
FROM Peliculas
INNER JOIN Directores
ON Peliculas.ID_Director = Directores.ID_Director
GROUP BY Peliculas.Género, Directores.Nombre
)
SELECT Nombre, Género, Cantidad_peliculas
FROM RankingDirectores
WHERE Ranking = 1
ORDER BY Cantidad_peliculas DESC;

--la siguiente consulta me permite visualizar a los directores con una calificación promedio en sus películas por encima de la media:
SELECT Directores.Nombre, ROUND(AVG(Peliculas.Calificacion_Promedio),2) AS Calificacion_Promedio
FROM Directores
INNER JOIN Peliculas
ON Directores.ID_Director = Peliculas.ID_Director
GROUP BY Directores.Nombre
HAVING AVG(Peliculas.Calificacion_promedio) > (SELECT AVG(Calificacion_Promedio)
FROM Peliculas)
ORDER BY Calificacion_Promedio DESC;

--para finalizar con el análisis cree esta consulta que devuelve a los 10 directores que más beneficios totales económicos generaron con sus películas:
SELECT TOP 10 Directores.Nombre, ROUND(SUM(Peliculas.Ingresos) - SUM(Peliculas.Presupuesto),2) AS Beneficios_totales
FROM Directores
INNER JOIN Peliculas
ON Directores.ID_Director = Peliculas.ID_Director
GROUP BY Directores.Nombre
ORDER BY Beneficios_totales DESC;