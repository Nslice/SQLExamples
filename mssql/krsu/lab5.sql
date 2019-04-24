USE krsu_3;

-- 1
-- Вывести список имеющегося на складе сырья.
SELECT DISTINCT p.КодСырья, p.НаимСырья
FROM Сырье AS p
  INNER JOIN Склад AS s ON p.КодСырья = s.КодСырья
ORDER BY p.КодСырья;


-- 2
-- Вывести список отсутствующего на складе сырья.
SELECT p.КодСырья, p.НаимСырья
FROM Сырье AS p
  LEFT JOIN Склад AS s ON p.КодСырья = s.КодСырья
WHERE s.КодСырья is NULL
ORDER BY p.КодСырья;


-- 3
-- Вывести данные обо всех наименованиях сырья с указанием максимальной
-- и средней цены сырья по типам и единицам измерения (сортировать данные
-- по типам, единицам измерения и наименованиям сырья).
SELECT p.НаимСырья, p.КодТипаСырья, p.КодЕдИзм,
  ROUND(AVG(s.Цена), 2) AS 'сред.', ROUND(MAX(s.Цена), 2) AS 'макс.'
FROM Склад AS s
  INNER JOIN Сырье AS p ON s.КодСырья = p.КодСырья
GROUP BY p.КодТипаСырья, p.КодЕдИзм, p.НаимСырья WITH ROLLUP
ORDER BY p.КодТипаСырья, p.КодЕдИзм, p.НаимСырья;


-- 4
-- Вывести данные обо всех кодах сырья с указанием общего объема сырья,
-- поступившего на основной склад за 2002 год.
SELECT s.КодСырья, ROUND(SUM(s.Количество * s.Цена), 2) 'объем'
FROM Склад AS s
WHERE s.КодСкладаДвиж = 1 AND s.ПризнакДвижения = 'Поступление'
  AND YEAR( s.Датадвижения) = 2002
GROUP BY s.КодСырья WITH ROLLUP
ORDER BY s.КодСырья;