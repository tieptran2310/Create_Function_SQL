--Case 01: Truyền 1 tham số: Xác định mức lương, số nhân viên, nhóm tuổi theo vị trí

CREATE FUNCTION CalculateGrpAge(@DOB DATE)
RETURNS VARCHAR(15) --kiểu dữ liệu
AS
BEGIN
  DECLARE @AGE INT, @GRPAGE varchar(15)      -- khai báo biến
  SET @AGE = DATEDIFF(YEAR, @DOB, GETDATE()) -- gán giá trị
  SET @GRPAGE =                              -- gán giá trị
	CASE
		WHEN @AGE < 18 THEN '< 18'
		WHEN @AGE < 35 THEN '18 - 35'
		WHEN @AGE < 50 THEN '36 - 50'
		WHEN @AGE < 60 THEN '51 - 60'
		ELSE '61 +'
	END
  RETURN @GRPAGE
END

SELECT 
	N1.JobTitle,--Tên vị trí
	N2.Rate, -- Mức lương
	COUNT (N1.BusinessEntityID) Employees , ---Số nhân viên
	DBO.CalculateGrpAge(BirthDate) GroupAge -- Nhóm tuổi
FROM  
HumanResources.Employee N1 --Danh sách nhân viên
INNER JOIN
(SELECT
	BusinessEntityID, 
	Rate, 
	RatechangeDate = MAX (RateChangeDate)
FROM HumanResources.EmployeePayHistory
GROUP BY BusinessEntityID, Rate) N2 --Mức lương gần nhất theo mã vị trí
ON N1.BusinessEntityID = N2.BusinessEntityID
GROUP BY JobTitle ,Rate, DBO.CalculateGrpAge(BirthDate) 
Order by JobTitle

---Case02: Trả về bảng kết quả - truyền 2 tham số: Truyền tham số lấy theo top và tỷ lệ % hàng bị phế bỏ

-- Production.ScrapReason: bảng lý do bị hỏng
-- Production.Product: bảng sản phẩm
-- Production.WorkOrder: đơn hàng đặt

CREATE FUNCTION ITVScrappedRatio(@percent INT, @ratio FLOAT) --truyền 2 tham số
RETURNS TABLE --bảng
AS
RETURN (SELECT TOP (@percent) PERCENT
			N1.WorkOrderID,
		    DueDate = CAST (N1.DueDate AS DATE),
			ProdName = N3.Name,
			ScrapReason = N2.Name, -- Lý do bị hỏng
			N1.ScrappedQty,
			N1.OrderQty,
		    [PercScrapped] =ROUND (N1.ScrappedQty /CONVERT (FLOAT,N1.OrderQty)* 100, 2)
FROM Production.WorkOrder N1
INNER JOIN Production.ScrapReason N2 ON N1.ScrapReasonID = N2.ScrapReasonID
INNER JOIN Production.Product N3 ON N1.ProductID = N3.ProductID
WHERE N1.ScrappedQty / CONVERT (FLOAT,N1.OrderQty) > @ratio 
ORDER BY N1.DueDate DESC)

SELECT * FROM ITVScrappedRatio(10, 0.02) --Truyền tham số tại đây