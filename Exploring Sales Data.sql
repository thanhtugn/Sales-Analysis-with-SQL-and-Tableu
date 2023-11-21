-- INSPECTING DATA

-- Xem tất cả dữ liệu trong bảng sales_data_sample
SELECT * FROM [dbo].[sales_data_sample];

-- CHECKING UNIQUE VALUES

-- Xem giá trị duy nhất trong cột 'status'
SELECT DISTINCT status FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất trong cột 'year_id'
SELECT DISTINCT year_id FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất trong cột 'PRODUCTLINE'
SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất trong cột 'COUNTRY'
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất trong cột 'DEALSIZE'
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất trong cột 'TERRITORY'
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample];

-- Xem giá trị duy nhất của 'MONTH_ID' và 'YEAR_ID' trong năm 2003
SELECT DISTINCT MONTH_ID, YEAR_ID FROM [dbo].[sales_data_sample] WHERE YEAR_ID = 2003;

-- ANALYSIS

-- Tổng hợp doanh số bán hàng theo dòng sản phẩm
SELECT PRODUCTLINE, SUM(sales) AS Revenue FROM [dbo].[sales_data_sample] GROUP BY PRODUCTLINE ORDER BY 2 DESC;

-- Tổng hợp doanh số bán hàng theo năm
SELECT YEAR_ID, SUM(sales) AS Revenue FROM [dbo].[sales_data_sample] GROUP BY YEAR_ID ORDER BY 2 DESC;

-- Tổng hợp doanh số bán hàng theo giá trị giao dịch
SELECT DEALSIZE, SUM(sales) AS Revenue FROM [PortfolioDB].[dbo].[sales_data_sample] GROUP BY DEALSIZE ORDER BY 2 DESC;

-- Tìm tháng có doanh số bán hàng cao nhất trong năm 2004 và doanh số bán được trong tháng đó
SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency FROM [PortfolioDB].[dbo].[sales_data_sample] WHERE YEAR_ID = 2004 GROUP BY MONTH_ID ORDER BY 2 DESC;

-- Xác định dòng sản phẩm bán chạy nhất trong tháng 11 năm 2004
SELECT MONTH_ID, PRODUCTLINE, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) FROM [PortfolioDB].[dbo].[sales_data_sample] WHERE YEAR_ID = 2004 AND MONTH_ID = 11 GROUP BY MONTH_ID, PRODUCTLINE ORDER BY 3 DESC;

-- Đánh giá tiềm năng khách hàng sử dụng mô hình RFM
DROP TABLE IF EXISTS #rfm;
WITH rfm AS 
(
    SELECT 
        CUSTOMERNAME, 
        SUM(sales) AS MonetaryValue,
        AVG(sales) AS AvgMonetaryValue,
        COUNT(ORDERNUMBER) AS Frequency,
        MAX(ORDERDATE) AS last_order_date,
        (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) AS max_order_date,
        DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) AS Recency
    FROM [PortfolioDB].[dbo].[sales_data_sample]
    GROUP BY CUSTOMERNAME
),
rfm_calc AS
(
    SELECT 
        r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
    FROM rfm r
)
SELECT 
    c.*, 
    rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
    CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) AS rfm_cell_string
INTO #rfm
FROM rfm_calc c;

SELECT 
    CUSTOMERNAME,
    rfm_recency,
    rfm_frequency,
    rfm_monetary,
    CASE 
        WHEN rfm_cell_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'
        WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose'
        WHEN rfm_cell_string IN (311, 411, 331) THEN 'new customers'
        WHEN rfm_cell_string IN (222, 223, 233, 322) THEN 'potential churners'
        WHEN rfm_cell_string IN (323, 333,321, 422, 332, 432) THEN 'active'
        WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
        ELSE 'Uncategorized'
    END AS rfm_segment
FROM #rfm;

-- What products are most often sold together?
SELECT DISTINCT OrderNumber, STUFF(
    (SELECT ',' + PRODUCTCODE
    FROM [dbo].[sales_data_sample] p
    WHERE ORDERNUMBER IN 
        (SELECT ORDERNUMBER
        FROM (
            SELECT ORDERNUMBER, COUNT(*) AS rn
            FROM [PortfolioDB].[dbo].[sales_data_sample]
            WHERE STATUS = 'Shipped'
            GROUP BY ORDERNUMBER
        ) m
        WHERE rn = 3
        )
        AND p.ORDERNUMBER = s.ORDERNUMBER
    FOR XML PATH (''))
    , 1, 1, '') AS ProductCodes
FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC;

-- EXTRAS

-- Thành phố nào có số lượng bán hàng cao nhất trong một quốc gia cụ thể 
SELECT city, SUM(sales) AS Revenue FROM [PortfolioDB].[dbo].[sales_data_sample] WHERE country = 'USA' GROUP BY city ORDER BY 2 DESC;

-- Sản phẩm nào là tốt nhất tại quốc gia cụ thể
SELECT country, YEAR_ID, PRODUCTLINE, SUM(sales) AS Revenue FROM [PortfolioDB].[dbo].[sales_data_sample] WHERE country = 'UK' GROUP BY country, YEAR_ID, PRODUCTLINE ORDER BY 4 DESC;
