CREATE DATABASE music_store;
USE music_store;

-- 1.Genre and MediaType
CREATE TABLE Genre (
	genre_id INT PRIMARY KEY,
	name VARCHAR(120)
);
CREATE TABLE MediaType (
	media_type_id INT PRIMARY KEY,
	name VARCHAR(120)
);

-- 2.Employee
CREATE TABLE Employee (
	employee_id INT PRIMARY KEY,
	last_name VARCHAR(120),
	first_name VARCHAR(120),
	title VARCHAR(120),
	reports_to INT NULL,
    levels VARCHAR(255),
	birthdate DATE,
	hire_date DATE,
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100)
);

-- 3.Customer
CREATE TABLE Customer (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(120),
	last_name VARCHAR(120),
	company VARCHAR(120),
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100),
	support_rep_id INT,
	FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);

-- 4.Artist
CREATE TABLE Artist (
	artist_id INT PRIMARY KEY,
	name VARCHAR(120)
);

-- 5.Album
CREATE TABLE Album (
	album_id INT PRIMARY KEY,
	title VARCHAR(160),
	artist_id INT,
	FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);

-- 6.Track
CREATE TABLE Track (
	track_id INT PRIMARY KEY,
	name VARCHAR(200),
	album_id INT,
	media_type_id INT,
	genre_id INT,
	composer text(255),
	milliseconds INT,
	bytes INT,
	unit_price DECIMAL(10,2),
	FOREIGN KEY (album_id) REFERENCES Album(album_id),
	FOREIGN KEY (media_type_id) REFERENCES MediaType(media_type_id),
	FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/track.csv'
INTO TABLE track
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price);

select count(*) from Track;

-- 7. Invoice
CREATE TABLE Invoice (
	invoice_id INT PRIMARY KEY,
	customer_id INT,
	invoice_date DATE,
	billing_address VARCHAR(255),
	billing_city VARCHAR(100),
	billing_state VARCHAR(100),
	billing_country VARCHAR(100),
	billing_postal_code VARCHAR(20),
	total DECIMAL(10,2),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

select count(*) from Invoice; 

-- 8.InvoiceLine
CREATE TABLE InvoiceLine (
	invoice_line_id INT PRIMARY KEY,
	invoice_id INT,
	track_id INT,
	unit_price DECIMAL(10,2),
	quantity INT,
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

-- 9.Playlist
CREATE TABLE Playlist (
 	playlist_id INT PRIMARY KEY,
	name VARCHAR(255)
);

-- 10.Playlist Track
CREATE TABLE PlaylistTrack (
	playlist_id INT,
	track_id INT,
	PRIMARY KEY (playlist_id, track_id),
	FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

-- 1. Who is the senior most employee based on job title? 
SELECT employee_id, first_name, last_name, title, levels, hire_date
FROM Employee
ORDER BY levels DESC, hire_date ASC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT billing_country AS country, COUNT(*) AS invoice_count
FROM Invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;


-- 3. What are the top 3 values of total invoice?
SELECT DISTINCT total FROM Invoice ORDER BY total DESC LIMIT 3;

-- 4. Which city has the best customers? - We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
SELECT billing_city, SUM(total) AS total_revenue
FROM Invoice
GROUP BY billing_city
ORDER BY total_revenue DESC
LIMIT 1;

-- 5. Who is the best customer? - The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id 
ORDER BY total_spent DESC
LIMIT 1;

-- 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM Customer c
JOIN Invoice i  ON i.customer_id = c.customer_id
JOIN InvoiceLine il ON il.invoice_id = i.invoice_id
JOIN Track t  ON t.track_id = il.track_id
JOIN Genre g  ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email ASC;

-- 7. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands 
SELECT a.artist_id, a.name AS artist_name, COUNT(*) AS rock_track_count
FROM Artist a
JOIN Album al ON al.artist_id = a.artist_id
JOIN Track t ON t.album_id = al.album_id
JOIN Genre g ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY rock_track_count DESC, a.name ASC
LIMIT 10;

-- 8. Return all the track names that have a song length longer than the average song length.- Return the Name and Milliseconds for each track. Order by the song length, with the longest songs listed first
SELECT t.name, t.milliseconds
FROM Track t
WHERE t.milliseconds > (SELECT AVG(milliseconds) FROM Track)
ORDER BY t.milliseconds DESC;

-- 9. Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent
SELECT c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
a.name AS artist_name,
ROUND(SUM(il.unit_price * il.quantity), 2) AS total_spent
FROM Customer c
JOIN Invoice i  ON i.customer_id = c.customer_id
JOIN InvoiceLine il ON il.invoice_id = i.invoice_id
JOIN Track t  ON t.track_id = il.track_id
JOIN Album al ON al.album_id = t.album_id
JOIN Artist a  ON a.artist_id = al.artist_id
GROUP BY c.customer_id, a.artist_id, a.name
ORDER BY total_spent DESC;

-- 10. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared, return all Genres
WITH genre_counts AS (
  SELECT c.country,
         g.name AS genre_name,
         COUNT(*) AS purchases
  FROM Customer c
  JOIN Invoice i ON i.customer_id = c.customer_id
  JOIN InvoiceLine il ON il.invoice_id = i.invoice_id
  JOIN Track t ON t.track_id = il.track_id
  JOIN Genre g ON g.genre_id = t.genre_id
  GROUP BY c.country, g.name
),
ranked AS (
  SELECT country, genre_name, purchases,
         DENSE_RANK() OVER (PARTITION BY country ORDER BY purchases DESC) AS rnk
  FROM genre_counts
)
SELECT country, genre_name AS top_genre, purchases
FROM ranked
WHERE rnk = 1
ORDER BY country ASC, top_genre ASC;

-- 11. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount
WITH spends AS (
  SELECT c.country,
         CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
         ROUND(SUM(i.total), 2) AS total_spent
  FROM Customer c
  JOIN Invoice i ON i.customer_id = c.customer_id
  GROUP BY c.country, c.customer_id, customer_name
),
ranked AS (
  SELECT country, customer_name, total_spent,
         DENSE_RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS rnk
  FROM spends
)
SELECT country, customer_name, total_spent
FROM ranked
WHERE rnk = 1
ORDER BY country ASC, customer_name ASC;





