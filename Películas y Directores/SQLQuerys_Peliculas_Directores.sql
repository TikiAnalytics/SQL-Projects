--Primero modifico la columna "ID_Director" de la tabla Directores para que no permita valores nulos,
--para luego transformarla en primary key:
ALTER TABLE Directores
ALTER COLUMN ID_Director INT NOT NULL;

-- Ahora transformo la columna "ID_Director" en primary key:
ALTER TABLE Directores
ADD CONSTRAINT PK_Director PRIMARY KEY (ID_Director);

--Ahora realizo lo mismo en la tabla "Pel�culas" con la columna "ID_Peliculas" para transformarla en primary key, 
--y tambi�n modifico "ID_Director" como clave for�nea, para terminar de normalizar la base de datos.
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

--Utilic� esta sentencia para corroborar una inconsistencia que no permitia contar todos los registros de cada g�nero
SELECT G�nero, COUNT(*)
FROM peliculas
GROUP BY G�nero
HAVING G�nero LIKE '%Ciencia%';

--Determin� la inconsistencia: hab�a espacios en blanco delante de algunas cadenas de caracteres, por lo que los elimin� con la siguiente sentencia:
UPDATE peliculas
SET G�nero = LTRIM(RTRIM(G�nero));

--Selecciono los cinco g�neros con m�s pel�culas de la lista.
SELECT TOP 5 COUNT(ID_Pelicula) AS Cantidad_Peliculas, G�nero
FROM Peliculas
GROUP BY G�nero
ORDER BY COUNT(ID_Pelicula) DESC;

--Ahora selecciono los g�neros y la calificaci�n promedio,
--para ver si hay una correlaci�n entre la cantidad y la calidad de los g�neros:
SELECT ROUND(AVG(Calificacion_Promedio),2) AS Calificacion_promedio, G�nero
FROM Peliculas
GROUP BY G�nero
ORDER BY AVG(Calificacion_Promedio) DESC;

--Por �ltimo y para terminar con los g�neros, selecciono los g�neros, y realizo calculos para el promedio de sus presupuestos,
--ganancias y finalmente un c�lculo para analizar al beneficio.
SELECT TOP 5 G�nero, ROUND(AVG(Presupuesto),2) AS Presupuesto_promedio, 
ROUND(AVG(Ingresos),2) AS Ingresos_promedio,
ROUND((AVG(Ingresos)-AVG(Presupuesto)),2) AS Beneficio_Promedio
FROM Peliculas
GROUP BY G�nero
ORDER BY (AVG(Ingresos)-AVG(Presupuesto)) DESC;

--cree una expresi�n de tabla com�n en la que utilic� la funci�n �ROW_NUMBER� para asignar un numero de fila a cada g�nero,
--ordenando las pel�culas por la calificaci�n promedio de mayor a menor, lo que le da a cada pel�cula dentro de los g�neros un ranking basado en su calificaci�n.
--Luego bas� la consulta principal en esta tabla, seleccionando solo las pel�culas con el ranking 1, es decir, la pel�cula con la calificaci�n m�s alta de cada g�nero
WITH RankingPeliculas AS (
SELECT Titulo, G�nero, Calificacion_Promedio,
ROW_NUMBER() OVER (PARTITION BY G�nero ORDER BY Calificacion_Promedio DESC) AS Ranking
FROM Peliculas)
SELECT Titulo, G�nero, Calificacion_Promedio
FROM RankingPeliculas
WHERE Ranking = 1
ORDER BY Calificacion_Promedio DESC;

--Consulta simple que me permite visualizar las diez pel�culas que m�s beneficios tuvieron.
SELECT TOP 10 Titulo, G�nero, ROUND(Ingresos-Presupuesto,2) AS Beneficios
FROM Peliculas
ORDER BY Beneficios DESC;

--siguiendo con los directores:

--�sta consulta me permite visualizar cu�les son los directores con m�s pel�culas realizadas por g�nero.
WITH RankingDirectores AS(
SELECT 
COUNT(Peliculas.ID_Pelicula) AS Cantidad_peliculas,
Peliculas.G�nero,
Directores.Nombre,
ROW_NUMBER() OVER (PARTITION BY Peliculas.G�nero ORDER BY COUNT(Peliculas.ID_Pelicula) DESC) AS Ranking
FROM Peliculas
INNER JOIN Directores
ON Peliculas.ID_Director = Directores.ID_Director
GROUP BY Peliculas.G�nero, Directores.Nombre
)
SELECT Nombre, G�nero, Cantidad_peliculas
FROM RankingDirectores
WHERE Ranking = 1
ORDER BY Cantidad_peliculas DESC;

--la siguiente consulta me permite visualizar a los directores con una calificaci�n promedio en sus pel�culas por encima de la media:
SELECT Directores.Nombre, ROUND(AVG(Peliculas.Calificacion_Promedio),2) AS Calificacion_Promedio
FROM Directores
INNER JOIN Peliculas
ON Directores.ID_Director = Peliculas.ID_Director
GROUP BY Directores.Nombre
HAVING AVG(Peliculas.Calificacion_promedio) > (SELECT AVG(Calificacion_Promedio)
FROM Peliculas)
ORDER BY Calificacion_Promedio DESC;

--para finalizar con el an�lisis cree esta consulta que devuelve a los 10 directores que m�s beneficios totales econ�micos generaron con sus pel�culas:
SELECT TOP 10 Directores.Nombre, ROUND(SUM(Peliculas.Ingresos) - SUM(Peliculas.Presupuesto),2) AS Beneficios_totales
FROM Directores
INNER JOIN Peliculas
ON Directores.ID_Director = Peliculas.ID_Director
GROUP BY Directores.Nombre
ORDER BY Beneficios_totales DESC;