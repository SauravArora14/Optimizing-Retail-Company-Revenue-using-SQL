Create Database Rev;
Use Rev;
DROP TABLE info;

CREATE TABLE info
(
    product_name VARCHAR(100),
    product_id VARCHAR(11) PRIMARY KEY,
    description VARCHAR(700)
);

CREATE TABLE finance
(
    product_id VARCHAR(11) PRIMARY KEY,
    listing_price FLOAT,
    sale_price FLOAT,
    discount FLOAT,
    revenue FLOAT
);
CREATE TABLE reviews
(
    product_id VARCHAR(11) PRIMARY KEY,
    rating FLOAT,
    reviews FLOAT
);

CREATE TABLE traffic
(
    product_id VARCHAR(11) PRIMARY KEY,
    last_visited TIMESTAMP
);

CREATE TABLE brands
(
    product_id VARCHAR(11) PRIMARY KEY,
    brand VARCHAR(7)
);
 -- Explore all objects in database
SHOW tables;
Show COLUMNS FROM brands;
Show COLUMNS FROM finance;
Show COLUMNS FROM info;
Show COLUMNS FROM reviews;
Show COLUMNS FROM traffic;

-- Find Total Sales
Select SUM(revenue) AS Total_Sales from finance f;
-- Find avg selling price
Select avg(listing_price) AS avg_sellling_price from finance;
-- Find total number of products
Select COUNT(distinct product_id) AS total_products from finance;

-- Analysis 
-- 1. Counting missing values
SELECT count(*) as total_rows,
    count(i.description) as count_description,
    count(f.listing_price) as count_listing_price,
    count(t.last_visited) as count_last_visited
FROM info i 
JOIN finance f
ON i.product_id = f.product_id 
JOIN traffic t
ON i.product_id = t.product_id;


-- 2. Nike vs Adidas pricing
SELECT 
    b.brand, 
    CAST(f.listing_price AS UNSIGNED) AS listing_price, 
    COUNT(*) AS product_count
FROM brands b
JOIN finance f ON b.product_id = f.product_id
WHERE 
    f.listing_price > 0
    AND b.brand IN ('Nike', 'Adidas')
GROUP BY 
    b.brand, 
    CAST(f.listing_price AS UNSIGNED)
ORDER BY 
    listing_price DESC;
    
    -- 3. Labeling price ranges
SELECT b.brand,
        COUNT(*) AS Product_count,
        SUM(f.revenue) as total_revenue,
        CASE WHEN f.listing_price < 42 THEN 'Budget'
             WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
             WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
            ELSE 'Elite' 
        END AS price_category
FROM brands b
JOIN finance f
ON b.product_id = f.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, price_category
ORDER BY total_revenue DESC;

-- 4. Average discount by brand
SELECT b.brand,
       AVG(discount)*100 as average_discount
FROM brands b
JOIN finance f
ON b.product_id = f.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand;

-- 5. Correlation between revenue and reviews
SELECT 
    (COUNT(*) * SUM(f.revenue * r.reviews) - SUM(f.revenue) * SUM(r.reviews)) /
    SQRT(
        (COUNT(*) * SUM(f.revenue * f.revenue) - POW(SUM(f.revenue), 2)) *
        (COUNT(*) * SUM(r.reviews * r.reviews) - POW(SUM(r.reviews), 2))
    ) AS review_revenue_corr
FROM finance f
JOIN reviews r ON f.product_id = r.product_id
WHERE f.revenue IS NOT NULL AND r.reviews IS NOT NULL;

-- 6. Ratings and reviews by product description length
SELECT 
    TRUNCATE(CHAR_LENGTH(description) / 100, 0) * 100 AS description_length,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM info i
JOIN reviews r ON i.product_id = r.product_id
WHERE description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

-- 7.Reviews by month and brand
SELECT 
    b.brand, 
    MONTH(t.last_visited) AS month,
    COUNT(*) AS num_reviews
FROM brands b
JOIN traffic t ON b.product_id = t.product_id
JOIN reviews r ON r.product_id = t.product_id
WHERE b.brand IS NOT NULL
  AND t.last_visited IS NOT NULL
GROUP BY b.brand, month
ORDER BY b.brand, month;


-- 8. Top Revenue Generated Products with Brands
WITH highest_revenue_product AS
(  
   SELECT i.product_name,
          b.brand,
          revenue
   FROM finance f
   JOIN info i
   ON f.product_id = i.product_id
   JOIN brands b
   ON b.product_id = i.product_id
   WHERE product_name IS NOT NULL 
     AND revenue IS NOT NULL 
     AND brand IS NOT NULL
)
SELECT product_name,
       brand,
       revenue,
        RANK() OVER (ORDER BY revenue DESC) AS product_rank
FROM highest_revenue_product
LIMIT 10;

-- 9.  Footwear product performance
WITH footwear AS (
  SELECT 
    i.description, 
    f.revenue
  FROM info i
  INNER JOIN finance f ON i.product_id = f.product_id
  WHERE i.description IS NOT NULL
    AND (
      i.description LIKE '%shoe%' 
      OR i.description LIKE '%trainer%' 
      OR i.description LIKE '%foot%'
    )
),
ranked_footwear AS (
  SELECT 
    description,
    revenue,
    ROW_NUMBER() OVER (ORDER BY revenue) AS rn,
    COUNT(*) OVER () AS total_count
  FROM footwear
)
SELECT 
  COUNT(*) AS num_footwear_products,
  AVG(revenue) AS median_footwear_revenue
FROM ranked_footwear
WHERE rn IN (FLOOR((total_count + 1)/2), CEIL((total_count + 1)/2));


WITH footwear AS (
  SELECT 	
    i.description, 
    f.revenue
  FROM info i
  INNER JOIN finance f ON i.product_id = f.product_id
  WHERE i.description IS NOT NULL
    AND (
      i.description LIKE '%shoe%' 
      OR i.description LIKE '%trainer%' 
      OR i.description LIKE '%foot%'
    )
),
ranked_footwear AS (
  SELECT 
    description,
    revenue,
    ROW_NUMBER() OVER (ORDER BY revenue) AS rn,
    COUNT(*) OVER () AS total_count
  FROM footwear
)
SELECT 
  COUNT(*) AS num_clothing_products,
  AVG(revenue) AS median_clothing_revenue
FROM ranked_footwear
WHERE rn IN (FLOOR((total_count + 1)/2), CEIL((total_count + 1)/2));

