-- Database: Project

-- DROP DATABASE IF EXISTS "Project";

CREATE TABLE customers (
customer_id INT PRIMARY KEY,
customer_name VARCHAR(100),
city VARCHAR(50)
);

CREATE TABLE transactions (
transaction_id INT PRIMARY KEY,
customer_id INT,
transaction_date TIMESTAMP,
amount DECIMAL(10,2),
payment_method VARCHAR(20),
merchant VARCHAR(50),
city VARCHAR(50),
status VARCHAR(20),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


INSERT INTO customers VALUES
(1,'Ananya','Delhi'),
(2,'Rohit','Mumbai'),
(3,'Priya','Bangalore'),
(4,'Aman','Pune'),
(5,'Neha','Hyderabad');

INSERT INTO transactions VALUES
(101,1,'2024-01-01 10:10:00',500,'UPI','Amazon','Delhi','SUCCESS'),
(102,1,'2024-01-01 10:12:00',5200,'CARD','Flipkart','Delhi','SUCCESS'),
(103,1,'2024-01-01 10:13:00',5400,'CARD','Flipkart','Mumbai','SUCCESS'),
(104,1,'2024-01-01 23:50:00',6000,'CARD','Myntra','Delhi','SUCCESS'),

(105,2,'2024-01-02 12:30:00',200,'UPI','Swiggy','Mumbai','FAILED'),
(106,2,'2024-01-02 12:32:00',220,'UPI','Swiggy','Mumbai','FAILED'),
(107,2,'2024-01-02 12:35:00',250,'UPI','Swiggy','Mumbai','SUCCESS'),
(108,2,'2024-01-03 01:10:00',4500,'CARD','Amazon','Mumbai','SUCCESS'),

(109,3,'2024-01-05 18:00:00',12000,'CARD','Apple','Bangalore','SUCCESS'),
(110,3,'2024-01-06 18:10:00',13000,'CARD','Apple','Bangalore','SUCCESS'),
(111,3,'2024-01-06 18:15:00',14000,'CARD','Apple','Delhi','SUCCESS'),

(112,4,'2024-01-07 09:00:00',300,'UPI','Zomato','Pune','SUCCESS'),
(113,4,'2024-01-07 09:05:00',320,'UPI','Zomato','Pune','SUCCESS'),
(114,4,'2024-01-07 09:07:00',350,'UPI','Zomato','Pune','SUCCESS'),

(115,5,'2024-01-07 23:55:00',8000,'CARD','Myntra','Hyderabad','SUCCESS');

SELECT * FROM customers;
SELECT * FROM transactions;

/* Finds transactions whose amount is higher than the overall average.
These transactions are risky because fraudsters often try large purchases
once access to an account is gained. */

/*1.  High-value transactions (above overall average) */
SELECT * FROM transactions WHERE amount > (SELECT AVG(amount) FROM transactions);

/* Identifies transactions where a customer spends more than their usual average.
Sudden increase in spending behavior can indicate possible fraud. */

/*2.  Transactions above customer’s average */
SELECT * FROM transactions t WHERE amount > (SELECT AVG(amount) FROM transactions WHERE customer_id=t.customer_id);

/* Uses LAG() to fetch the previous transaction amount of each customer.
This helps compare current and previous transactions to detect spending spikes. */

/*3.  Spending spike using LAG() */
SELECT customer_id,transaction_date, amount, LAG(amount) OVER (PARTITION BY customer_id ORDER BY transaction_date ) AS spike FROM transactions

/* Detects customers making many transactions on the same day.
High frequency in short time can indicate automated or fraudulent activity. */

/*4.  Multiple transactions in same day */
SELECT customer_id, DATE(transaction_date), COUNT(*) txn_count FROM transactions GROUP BY customer_id, DATE(transaction_date) HAVING COUNT(*) > 2;

/* Identifies customers transacting from more than one city.
Rapid location changes are not practically possible and can indicate fraud. */

/*5.  Same customer, different cities */
SELECT customer_id, COUNT(DISTINCT city) city_count FROM transactions GROUP BY customer_id HAVING COUNT(DISTINCT city)>1;

/* Identifies customers transacting from more than one city.
Rapid location changes are not practically possible and can indicate fraud. */

/*6.  Frequent failed transactions */
SELECT customer_id,COUNT(*) failed_txns FROM transactions WHERE status='FAILED' GROUP BY customer_id HAVING count(*)>1;

/* Ranks transactions based on amount in descending order.
Higher-ranked transactions are considered higher risk and need review first. */

/*7.  Rank risky transactions */
SELECT *, RANK() OVER (ORDER BY amount DESC) AS risk_rank FROM transactions;

/* Calculates cumulative spending of each customer over time.
Sudden sharp increases in running total may indicate abnormal behavior. */

/*8.  Running total of spend */
SELECT customer_id, transaction_date, SUM(amount) OVER (PARTITION BY customer_id ORDER BY transaction_date) FROM transactions;

/* Extracts hour from timestamp to identify late-night transactions.
Transactions between 11 PM and 5 AM are considered riskier. */

/*9.  Transactions late at night */
SELECT * FROM transactions WHERE EXTRACT(HOUR FROM transaction_date)>=23 OR EXTRACT(HOUR FROM transaction_date)<=5 ;

/* Compares current and previous transaction amounts using LAG().
A large difference indicates a sudden spending spike, which is suspicious. */

/*10. Customers with sudden high jump */
SELECT * FROM (SELECT customer_id,amount,amount-LAG(amount) OVER (PARTITION BY customer_id ORDER BY transaction_date ) diff FROM transactions ) x WHERE diff > 4000;

/* Identifies merchants with high transaction volume.
High activity merchants are often monitored closely in fraud systems. */

/*11. Top risky merchants */
SELECT merchant, COUNT(*) txn_count FROM transactions GROUP BY merchant ORDER BY txn_count DESC;

/* Calculates total spending per customer.
High total spenders are prioritized for fraud monitoring. */

/*12. Customers with highest total spend */
SELECT customer_id, SUM(amount) total_spend FROM transactions GROUP BY customer_id ORDER BY total_spend DESC; 

/* Analyzes transaction count by payment method.
Card transactions usually carry higher fraud risk than UPI. */

/*13. Card vs UPI fraud pattern */
SELECT payment_method, COUNT(*) txn_count FROM transactions GROUP BY payment_method ;

/* Detects multiple small-value transactions by the same customer.
Fraudsters often test cards with small repeated payments. */

/*14. Repeated small transactions */
SELECT customer_id, COUNT(*) small_txns FROM transactions WHERE amount <300 GROUP BY customer_id HAVING COUNT(*)>2;

/* Shows transaction volume by city.
Helps identify locations with unusually high transaction activity. */

/*15. City-wise suspicious volume */
SELECT city, COUNT(*) txn_count FROM transactions GROUP BY city;
