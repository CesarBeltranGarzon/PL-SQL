SELECT SalesOrderID, ProductID, OrderQty
    ,SUM(OrderQty) OVER(PARTITION BY SalesOrderID) AS 'Total'
    ,AVG(OrderQty) OVER(PARTITION BY SalesOrderID) AS 'Avg'
    ,COUNT(OrderQty) OVER(PARTITION BY SalesOrderID) AS 'Count'
    ,MIN(OrderQty) OVER(PARTITION BY SalesOrderID) AS 'Min'
    ,MAX(OrderQty) OVER(PARTITION BY SalesOrderID) AS 'Max'
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN(43659,43664);

--
SELECT COUNT(*) OVER(PARTITION BY id_pago)
FROM tbl_wrk_gesrec
where id_pago = 1183226943
