SET foreign_key_checks = 0;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS route;
DROP TABLE IF EXISTS year;
DROP TABLE IF EXISTS day;
DROP TABLE IF EXISTS weekly_schedule;
DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS contact;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS reserved;
DROP TABLE IF EXISTS payer;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS route_in_year;
DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP FUNCTION IF EXISTS checkRoute;
DROP FUNCTION IF EXISTS checkRouteInYear;
DROP FUNCTION IF EXISTS getRoute;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;
DROP VIEW IF EXISTS allFlights;


SET foreign_key_checks = 1;

-- Writing stuff
SELECT 'Creating tables' AS 'Message';

-- CREATING TABLES
CREATE TABLE airport (
	code VARCHAR(3),
	name VARCHAR(30),
	country VARCHAR(30),
	CONSTRAINT pk_airport PRIMARY KEY(code)) ENGINE=InnoDB;
	
CREATE TABLE route (
	id INT AUTO_INCREMENT,
	arrival_airport VARCHAR(3), -- FOREIGN KEY TO AIRPORT
	departure_airport VARCHAR(3), -- FOREIGN KEY TO AIRPORT
	CONSTRAINT pk_route PRIMARY KEY(id)) ENGINE=InnoDB;
	
CREATE TABLE year (
	year INT,
	profit_factor DOUBLE,
	CONSTRAINT pk_year PRIMARY KEY(year)) ENGINE=InnoDB;
	
CREATE TABLE day (
	year INT, -- FK TO YEAR
	day VARCHAR(10),
	weekday_factor DOUBLE,
	CONSTRAINT pk_day PRIMARY KEY(day, year)) ENGINE=InnoDB;
	
CREATE TABLE weekly_schedule (
	id INT AUTO_INCREMENT,
	departure_time TIME, 
	route INT, -- FOREIGN KEY TO ROUTE 
	day VARCHAR(10), -- FOREIGN KEY TO DAY  
	year INT, -- FOREIGN KEY TO DAY 
	CONSTRAINT pk_weekly_schedule PRIMARY KEY(id)) ENGINE=InnoDB;
	
CREATE TABLE flight (
	flightnumber INT AUTO_INCREMENT,
	week INT,
	weekly_schedule INT, -- FOREIGN KEY TO WEEKLY SCHEDULE
	CONSTRAINT pk_flight PRIMARY KEY(flightnumber)) ENGINE=InnoDB;
	
CREATE TABLE passenger (
	passport_number INT,
	name VARCHAR(30),
	CONSTRAINT pk_passenger PRIMARY KEY(passport_number)) ENGINE=InnoDB;
	
CREATE TABLE contact (
	passenger INT, -- FK TO PASSENGER
	email VARCHAR(30),
	phone_number BIGINT,
	CONSTRAINT pk_contact PRIMARY KEY(passenger)) ENGINE=InnoDB;
	
CREATE TABLE reservation (
	reservation_number INT AUTO_INCREMENT,
	num_passenger INT,
	flight INT, -- FK TO FLIGHT
	contact INT, -- foreign key to passenger 
	CONSTRAINT pk_reservation PRIMARY KEY(reservation_number)) ENGINE=InnoDB;
	 
CREATE TABLE reserved (
	passenger INT, -- FK to passener
	reservation INT, -- FK to reservation
	CONSTRAINT pk_reserved PRIMARY KEY(passenger, reservation)) ENGINE=InnoDB;
	
CREATE TABLE payer (
	card_number BIGINT,
	card_holder VARCHAR(30),
	CONSTRAINT pk_payer PRIMARY KEY(card_number)) ENGINE=InnoDB;

CREATE TABLE booking (
	reservation INT, -- FK TO RESERVATION
	price DOUBLE,
	payer BIGINT, -- FK TO PAYER
	CONSTRAINT pk_booking PRIMARY KEY(reservation)) ENGINE=InnoDB;

CREATE TABLE ticket (
	 ticket_id INT,
	 passenger INT, -- FK TO PASSENGER
	 booking INT, -- FK TO BOOKING
	 CONSTRAINT pk_ticket PRIMARY KEY(ticket_id)) ENGINE=InnoDB;
	 
CREATE TABLE route_in_year (
	year INT,
	route INT,
	route_price DOUBLE,
	CONSTRAINT pk_route_in_year PRIMARY KEY(year, route)) ENGINE=InnoDB;
	

-- Add foreign keys 
SELECT 'Creating foreign keys' AS 'Message';

-- FK FROM ROUTE TO AIRPORT
ALTER TABLE route ADD CONSTRAINT fk_arr_airport_code FOREIGN KEY (arrival_airport) REFERENCES airport(code);
ALTER TABLE route ADD CONSTRAINT fk_dep_airport_code FOREIGN KEY (departure_airport) REFERENCES airport(code);

-- FK FROM DAY TO YEAR
ALTER TABLE day ADD CONSTRAINT fk_year_year FOREIGN KEY (year) REFERENCES year(year);

-- FK FROM WEEKLY SCHEDULE TO ROUTE
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_route_id FOREIGN KEY (route) REFERENCES route(id);
-- COMBINED FK FROM WEEKLY SCHEDULE TO DAY (WITH DAY HAVING TWO PRIMARY KEYS)
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_day_day_year FOREIGN KEY (day, year) REFERENCES day(day, year);

-- FK FROM FLIGHT TO WEEKLY SCHEDULE
ALTER TABLE flight ADD CONSTRAINT fk_weekly_schedule_id FOREIGN KEY (weekly_schedule) REFERENCES weekly_schedule(id);

-- FK FROM CONTACT TO PASSENGER
ALTER TABLE contact ADD CONSTRAINT fk_passenger_passport_number FOREIGN KEY (passenger) REFERENCES passenger(passport_number);

-- FK FROM RESERVATION TO FLIGHT
ALTER TABLE reservation ADD CONSTRAINT fk_flight_flightnumber FOREIGN KEY (flight) REFERENCES flight(flightnumber);
-- FK FROM RESERVATION TO CONTACT
ALTER TABLE reservation ADD CONSTRAINT fk_contact_passenger FOREIGN KEY (contact) REFERENCES contact(passenger);

-- FK FROM RESERVED TO PASSENGER
ALTER TABLE reserved ADD CONSTRAINT fk_passenger FOREIGN KEY (passenger) REFERENCES passenger(passport_number);
-- FK FROM RESERVED TO RESERVATION
ALTER TABLE reserved ADD CONSTRAINT fk_reservation FOREIGN KEY (reservation) REFERENCES reservation(reservation_number);

-- FK FROM BOOKING TO PAYER
ALTER TABLE booking ADD CONSTRAINT fk_payer_card_number FOREIGN KEY (payer) REFERENCES payer(card_number);
-- FK FROM BOOKING TO RESERVATION
ALTER TABLE booking ADD CONSTRAINT fk_reservation_number FOREIGN KEY (reservation) REFERENCES reservation(reservation_number);


-- FK FROM TICKET TO PASSENGER
ALTER TABLE ticket ADD CONSTRAINT fk_passenger_passport FOREIGN KEY (passenger) REFERENCES passenger(passport_number);
-- FK FROM TICKET TO BOOKING
ALTER TABLE ticket ADD CONSTRAINT fk_booking FOREIGN KEY (booking) REFERENCES booking(reservation);

-- FK FROM ROUTE IN YEAR TO YEAR AND BOOKING
ALTER TABLE route_in_year ADD CONSTRAINT fk_year FOREIGN KEY (year) REFERENCES year(year);
ALTER TABLE route_in_year ADD CONSTRAINT fk_route FOREIGN KEY (route) REFERENCES route(id);





-- PROCEDURES --
SELECT 'Creating procedures' AS 'Message';

DELIMITER //

-- Procedure to add a year
CREATE PROCEDURE addYear(IN year_val INTEGER, IN factor_val DOUBLE)
BEGIN
	INSERT INTO year(year, profit_factor) 
	VALUES (year_val, factor_val);
END//


CREATE PROCEDURE addDay(
	IN year_val INT,
	IN day_val VARCHAR(10), 
	IN factor_val DOUBLE)
BEGIN 
	INSERT INTO day(year, day, weekday_factor)
	VALUES (year_val, day_val, factor_val);
END//


CREATE PROCEDURE addDestination(
	IN code_val VARCHAR(3), 
	IN name_val VARCHAR(30), 
	IN country_val VARCHAR(30))
BEGIN
	INSERT INTO airport(code, name, country) 
	VALUES (code_val, name_val, country_val);
END//


CREATE FUNCTION checkRoute (
    departure_airport_code_val VARCHAR(3), 
    arrival_airport_code_val VARCHAR(3)
)
RETURNS INT
BEGIN
    DECLARE rowsCount INT; -- IS ONLY GONNA BE 1 OR 0
    
    SELECT COUNT(*) INTO rowsCount 
    FROM route 
    WHERE departure_airport = departure_airport_code_val 
    AND arrival_airport = arrival_airport_code_val;
    
    RETURN rowsCount;
END//

		
	
CREATE FUNCTION checkRouteInYear (
    route_id_val INT,
    year_val INT)
RETURNS INT
BEGIN
    DECLARE rowsCount INT; 
    
    SELECT COUNT(*) 
    INTO rowsCount 
    FROM route_in_year
    WHERE route = route_id_val
    AND year = year_val;
    
    RETURN rowsCount;
END//


CREATE FUNCTION getRoute (
	departure_airport_code_val VARCHAR(3), 
	arrival_airport_code_val VARCHAR(3)
)
RETURNS INT
BEGIN 
	DECLARE route_id INT;
	SELECT id 
	INTO route_id 
	FROM route 
	WHERE departure_airport = departure_airport_code_val 
	AND arrival_airport = arrival_airport_code_val;
	RETURN route_id;

END//
		
	

CREATE PROCEDURE addRoute(
	IN departure_airport_code_val VARCHAR(3), 
	IN arrival_airport_code_val VARCHAR(3), 
	IN year_val INT, 
	IN price_val DOUBLE)
BEGIN
	DECLARE route_id INT;
	
	IF checkRoute(departure_airport_code_val, arrival_airport_code_val) = 0 THEN
		INSERT INTO route(departure_airport, arrival_airport) 
		VALUES (departure_airport_code_val, arrival_airport_code_val);
--	ELSE
--    		SELECT 'Route already exists in route table!' AS 'Message';
    	END IF;
    	
	SET route_id = getRoute(departure_airport_code_val, arrival_airport_code_val);
	
	IF checkRouteInYear(route_id, year_val) = 0 THEN 
		INSERT INTO route_in_year(year, route, route_price) 
    		VALUES (year_val, route_id, price_val);
    	ELSE
    		SELECT 'Route already exists for this year!' AS 'Message';
    	END IF;
END//


CREATE PROCEDURE addFlight(
	IN departure_airport_code_val VARCHAR(3), 
	IN arrival_airport_code_val VARCHAR(3), 
	IN year_val INT, 
	IN day_val VARCHAR(10), 
	IN departure_time_val TIME)
BEGIN
	DECLARE route_id INT;
	DECLARE rowsCount INT; -- IS ONLY GONNA BE 1 OR 0
	DECLARE weekly_schedule_id INT;
	DECLARE loop_week INT;
	
	SET route_id = getRoute(departure_airport_code_val, arrival_airport_code_val);
	
	SELECT COUNT(*) 
	INTO rowsCount 
	FROM weekly_schedule
	WHERE departure_time = departure_time_val
	AND route = route_id
	AND day = day_val
	AND year = year_val;
	
	IF checkRouteInYear(route_id, year_val) = 1 THEN 	
		IF rowsCount = 0 THEN 
			INSERT INTO weekly_schedule(departure_time, route, day, year)
			VALUES (departure_time_val, route_id, day_val, year_val);
		END IF;
	END IF;
	
	SELECT id 
	INTO weekly_schedule_id 
	FROM weekly_schedule 
	WHERE departure_time = departure_time_val
	AND route = route_id
	AND day = day_val
	AND year = year_val;
	
	SET loop_week = 1;
	WHILE loop_week < 53 DO
		INSERT INTO flight (week, weekly_schedule) 
		VALUES (loop_week, weekly_schedule_id);
		SET loop_week = loop_week + 1;
	END WHILE;
END//


SELECT 'Creating Help Functions!' AS 'Message';

CREATE FUNCTION calculateFreeSeats(flight_number_val INT)
RETURNS INT
BEGIN
	DECLARE booked_seats INT;
	DECLARE free_seats INT;
	
	SELECT COUNT(*)
	INTO booked_seats
	FROM reserved 
	WHERE reserved.reservation IN (SELECT reservation_number FROM reservation WHERE flight_number_val = reservation.flight AND reservation_number IN (SELECT reservation FROM booking));
	
	-- En annan variant av att räkna ut booked_seats
/*	SELECT COUNT(*)
    	INTO booked_seats
   	FROM reserved r
    	INNER JOIN reservation res ON r.reservation = res.reservation_number
    	INNER JOIN booking b ON res.reservation_number = b.reservation
    	WHERE res.flight = flight_number_val;
*/	

	SET free_seats = 40 - booked_seats;
	RETURN free_seats; -- An integer of no of free seats on that specific flight
	
END //
	


CREATE FUNCTION calculatePrice(flight_number_val INT)
RETURNS DOUBLE
BEGIN

	
	DECLARE route_price_val DOUBLE DEFAULT 1;
	DECLARE weekday_factor_val DOUBLE DEFAULT 1;
	DECLARE profit_factor_val DOUBLE DEFAULT 1;
	DECLARE booked_passengers INT;
	DECLARE total_price DOUBLE;

/*	
	DECLARE weekly_schedule_val INT;
	DECLARE route_val INT;
	DECLARE day_val VARCHAR(10);
	DECLARE year_val INT;

	SELECT weekly_schedule 
	INTO weekly_schedule_val
	FROM flight
	WHERE flight_number_val = flightnumber;
	
	SELECT route, day, year
	INTO route_val, day_val, year_val
	FROM weekly_schedule
	WHERE id = weekly_schedule_val;

	SELECT route_price 
	INTO route_price_val 
	FROM route_in_year
	WHERE route = route_val
	AND year = year
	LIMIT 1;
	
	SELECT weekday_factor
	INTO weekday_factor_val
	FROM day
	WHERE day = day_val
	AND year = year_val
	LIMIT 1;
	
	SELECT profit_factor 
	INTO profit_factor_val
	FROM year
	WHERE year = year_val
	LIMIT 1;
*/
	
	-- Calculate Route Price
	SELECT route_in_year.route_price 
	INTO route_price_val
	FROM route_in_year
	JOIN weekly_schedule ON route_in_year.route = weekly_schedule.route AND route_in_year.year = weekly_schedule.year
	JOIN flight ON weekly_schedule.id = flight.weekly_schedule
	WHERE flight.flightnumber = flight_number_val
	LIMIT 1;
	
	-- Calculate Weekday Factor
	SELECT day.weekday_factor 
	INTO weekday_factor_val
	FROM day
	JOIN weekly_schedule ON day.year = weekly_schedule.year AND day.day = weekly_schedule.day
	JOIN flight ON weekly_schedule.id = flight.weekly_schedule
	WHERE flight.flightnumber = flight_number_val
	LIMIT 1;
	
	-- Calculate Yearly Profit Factor
	SELECT year.profit_factor 
	INTO profit_factor_val
	FROM year
	JOIN route_in_year ON year.year = route_in_year.year
	JOIN weekly_schedule ON route_in_year.route = weekly_schedule.route AND route_in_year.year = weekly_schedule.year
	JOIN flight ON weekly_schedule.id = flight.weekly_schedule
	WHERE flight.flightnumber = flight_number_val
	LIMIT 1;
	
	
	SET booked_passengers = 40 - calculateFreeSeats(flight_number_val);
	
	SET total_price = ROUND(route_price_val * weekday_factor_val * ((booked_passengers + 1) / 40) * profit_factor_val, 3);
	
	RETURN total_price;
END //


CREATE TRIGGER generate_ticket_number
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
    DECLARE ticket_number INT;
    SET ticket_number = FLOOR(RAND() * 1000000); -- Change 1000000 to any desired range
    
    -- Check if the generated ticket number already exists
    WHILE EXISTS (SELECT 1 FROM reservation_passenger WHERE ticket_number = ticket_number) DO
        SET ticket_number = FLOOR(RAND() * 1000000); -- Change 1000000 to any desired range
    END WHILE;
    
    SET NEW.ticket_id = ticket_number;
END //
	

SELECT 'Creating Reservation Procedures!' AS 'Message';

CREATE PROCEDURE addReservation(
	IN departure_airport_code_val VARCHAR(3),
	IN arrival_airport_code_val VARCHAR(3),
	IN year_val INT,
	IN week_val INT,
	IN day_val VARCHAR(10),
	IN time_val TIME,
	IN number_of_passengers_val INT,
	OUT output_reservation_number_val INT
)
BEGIN
	DECLARE route INT;
	DECLARE weekly_schedule_val INT;
	DECLARE flightnumber_val INT;
	
	SELECT id
	INTO route
	FROM route
	WHERE departure_airport = departure_airport_code_val
	AND arrival_airport = arrival_airport_code_val;
	
	SELECT id
	INTO weekly_schedule_val
	FROM weekly_schedule
	WHERE route = route
	AND departure_time = time_val
	AND day = day_val
	AND year = year_val;
	
	SELECT flightnumber
	INTO flightnumber_val
	FROM flight
	WHERE weekly_schedule = weekly_schedule_val
	AND week = week_val;
	
	IF weekly_schedule_val IS NOT NULL THEN
		IF calculateFreeSeats(flightnumber_val) >= number_of_passengers_val THEN
			INSERT INTO reservation(num_passenger, flight)
    			VALUES (number_of_passengers_val, flightnumber_val);
    		
    			SELECT reservation_number
			INTO output_reservation_number_val
			FROM reservation
			WHERE reservation_number = LAST_INSERT_ID();
		ELSE
			SELECT 'There are not enough seats available on the chosen flight!' AS 'Message';
		END IF;
	ELSE 
		SELECT 'There exist no flight for the given route, date and time!' AS 'Message';
	END IF;

	
    	

END //
	

CREATE PROCEDURE addPassenger(
	IN reservation_nr_val INT,
	IN passport_number_val INT,
	IN name_val VARCHAR(30)
)
BEGIN
	DECLARE rowsCount INT;
	DECLARE rowsCount2 INT;
	DECLARE rowsCount3 INT;
	
	SELECT COUNT(*)
	INTO rowsCount
	FROM passenger
	WHERE passport_number = passport_number_val
	AND name = name_val;

	IF rowsCount = 0 THEN 
		INSERT INTO passenger(passport_number, name)
		VALUES (passport_number_val, name_val);
	END IF;
	
	SELECT COUNT(*)
	INTO rowsCount2
	FROM reservation
	WHERE reservation_number = reservation_nr_val;
	
	SELECT COUNT(*)
	INTO rowsCount3
	FROM booking
	WHERE reservation = reservation_nr_val;
	
	IF rowsCount2 = 1 THEN
		IF rowsCount3 = 0 THEN
			INSERT INTO reserved(passenger, reservation)
			VALUES (passport_number_val, reservation_nr_val);
		ELSE
			SELECT 'The booking has already been payed and no futher passengers can be added!' AS 'Message';
		END IF;
	ELSE
		SELECT 'The given reservation number does not exist!' AS 'Message';
	END IF;
END //
	

CREATE PROCEDURE addContact(
	IN reservation_nr_val INT,
	IN passport_number_val INT,
	IN email_val VARCHAR(30),
	IN phone_val BIGINT
)
BEGIN
	DECLARE rowsCount INT;
	DECLARE rowsCount2 INT;
	DECLARE rowsCount3 INT;
	
	SELECT COUNT(*) 
	INTO rowsCount
	FROM reservation
	WHERE reservation_number = reservation_nr_val;
	
	SELECT COUNT(*)
    	INTO rowsCount2
    	FROM passenger
    	WHERE passport_number = passport_number_val;
    		
    	SELECT COUNT(*)
    	INTO rowsCount3
    	FROM contact
    	WHERE passenger = passport_number_val;

	IF rowsCount = 1 THEN
    		IF rowsCount2 = 1 THEN
    			IF rowsCount3 = 0 THEN 
        			INSERT INTO contact(passenger, email, phone_number)
        			VALUES (passport_number_val, email_val, phone_val);
        		END IF;

        		UPDATE reservation
        		SET contact = passport_number_val
        		WHERE reservation_number = reservation_nr_val;
    		ELSE
        		SELECT 'The person is not a passenger of the reservation!' AS Message;
    		END IF;
	ELSE
    		SELECT 'The given reservation number does not exist!' AS Message;
	END IF;

END //



CREATE PROCEDURE addPayment(
	IN reservation_number_val INT,
	IN card_holder_val VARCHAR(30),
	IN card_number_val BIGINT)
BEGIN
	DECLARE rowsCount INT;
	DECLARE rowsCount2 INT;
	DECLARE rowsCount3 INT;
	DECLARE freeSeats INT DEFAULT 0;
	DECLARE number_of_passengers INT DEFAULT 0;
	DECLARE flightnumber INT DEFAULT 0;
	DECLARE total_price DOUBLE;
	
	
	SELECT COUNT(*)
	INTO number_of_passengers
	FROM reserved
	WHERE reservation = reservation_number_val;
	
	SELECT flight
	INTO flightnumber
	FROM reservation
	WHERE reservation_number = reservation_number_val;

	SELECT COUNT(*)
	INTO rowsCount
	FROM reservation
	WHERE contact IS NOT NULL
	AND reservation_number = reservation_number_val;
	
	SELECT COUNT(*)
	INTO rowsCount2
	FROM reservation
	WHERE reservation_number = reservation_number_val;
	
	SELECT COUNT(*) 
	INTO rowsCount3
	FROM payer
	WHERE card_number = card_number_val
	AND card_holder = card_holder_val;
	
	SET freeSeats = calculateFreeSeats(flightnumber); -- Jo nu fungerar det där nedanför... XD	
	SELECT SLEEP(5);
	
	IF rowsCount2 = 1 THEN 	-- Checking if reservation exists
		IF rowsCount = 1 THEN 		-- Checking if contact exists in reservation
			IF number_of_passengers <= freeSeats THEN 	-- Checking if enough seats available 
				
				SET total_price = calculatePrice(flightnumber) * number_of_passengers;
				
				
				IF rowsCount3 = 0 THEN 
					INSERT INTO payer(card_number, card_holder)
					VALUES (card_number_val, card_holder_val); 
				END IF;
	
				INSERT INTO booking(reservation, price, payer)
				VALUES (reservation_number_val, total_price, card_number_val);
			ELSE			
				SELECT 'There are not enough seats available on the flight anymore, deleting reservation!' AS Message;
			END IF;
		ELSE
			SELECT 'The reservation has no contact yet!' AS Message;
		END IF;
	ELSE
		SELECT 'The given reservation number does not exist!' AS Message;
	END IF;
	
	
END //


DELIMITER ;



SELECT 'Creating a View for all Flights' AS 'Message';

CREATE VIEW allFlights(departure_city_name, destination_city_name, departure_time, departure_day,departure_week, departure_year, nr_of_free_seats, current_price_per_seat) 
AS SELECT 
	(SELECT airport.name FROM airport WHERE airport.code = route.departure_airport LIMIT 1), 
	(SELECT airport.name FROM airport WHERE airport.code = route.arrival_airport LIMIT 1),
	weekly_schedule.departure_time, 
	weekly_schedule.day, 
	flight.week, 
	day.year, 
	(calculateFreeSeats(flight.flightnumber)), 
	(calculatePrice(flight.flightnumber))
FROM flight 
LEFT JOIN weekly_schedule ON flight.weekly_schedule = weekly_schedule.id 
LEFT JOIN route ON weekly_schedule.route = route.id
LEFT JOIN day ON weekly_schedule.day = day.day;



/*
QUESTION 8:
	a) To protect the credit card information in the database from potential hackers, one good way is to use hash functions. This means that the entered credit card information gets encrypted through a hash function, and the encoded version is stored in the database. An unauthorized user who accesses encoded data will have a hard time deciphering it.
	
	b) Three advantages of using stored procedures in the database rather then in the front-end application:
		1) Reduced code duplication: The same function might be required for several different programs and algoritms. By using stored procedures in the database, many instances can call on the same procedure in the database rather then writing the same function in the front-end multiple times, hence reducing code duplication.
		2) Improved performance: Because stored procedures execute on the database server, it minimizes the data transfer between the back-end (i.e. the database) and the front-end. This will result in reduced network latency, minimize transaction costs in the application, and improve performance.
		3) Enhanced database management and security: Stored procedures provide granular access control by allowing administrators of the database management system to set permissions at the procedure level. This will ensure that only the right autorized users can call on and execute specific procedures, leading to both easily management of the database, as well as enhanced security through data validation and integrity checks.
		

QUESTION 9:
	a) CALL addReservation("MIT","HOB",2010,1,"Monday","09:00:00",2,@q);
	b) No. Changes made in session A are not visible yet in session B. This is because transactions are isolated from eachother until they are committed. After the transaction is committed, the changes will be visible in session B. Isolation is an essentiel part when handling concurrency problems in when quering from the database.
	C) Since transaction A has not been commited yet, its changes - adding a new tuple to the reservation table, only exist within the local transaction in session A. These changes take effect and become visible in the database only after commiting. Until then, transaction B - which started before A made changes to the database and committed these - can not see or modify the tuple. Also, trying to add the same information in both sessions results in an error for session B. So A and B are really operating in separate sessions when they are in transaction mode. So regarding changes made and commited in session A, B wont be able to se and modify these while in a transaction mode that started before the changes were made.
	

QUESTION 10:
	a) First time we tried executing this procedure, we started transaction A and B before the first setup script was completed in session A. This (of course) led to error since session B had no idea about the database that was setup in session A. Therefore, in the second test, we ran the setup-script for the database in session A, and then after that was done, we entered transaction mode in both sessions and ran the second script (MakeBooking). For session A (where we first ran the second script), everything worked fine and nr of free seats on the flight were 19. However, in session B, the terminal wont work with us and gives us the following response error: ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction. This is probably because of how our implementation of the database is made, but we do not really know how to solve it. In the third test, we did not enter transaction mode in any of the sessions. In this case, no overbooking occured. Nr of free seats were equal to 19 in both sessions.
	b) WITHOUT TRANSACTION MODE: Overbookings should theoretically be possible, all depending on the executing time of the terminals. If the script is executed simutanously in both sessions, "checks" to prevent overbooking could be executed simultaneaously, for e.g. calculate FreeSeats, and thereby lead to overbooking because it is giving OK to the script to fill the plane with more passengers to two executing scripts at the same time. To achieve this, we can use SLEEP function. This line of code should be after the calculateFreeSeats function is called, and before its inserted into the booking function. What happens now is that when session A calls for calculateFreeSeats, it will leave a time slot of x seconds before it inserts the reservation to a booking. If session B calls for calculateFreeSeats during this time slot, it should get the same number as session A since it has not been a booking made yet. Therefore, this should lead to an overbooking. 
	c) After 4+ hours of mixing with our code and trying different procedures in the terminals to make this theoretical case work in reality, we have yet not succeed. Our result is that both sessions return nr of free seats to be 19. We think that the reason for our theoretical case to NOT work is because we have some kind of problem in our addPayment procedure. The reason for this is that we get an response error ERROR 1062 (23000): Duplicate entry '7878787878' for key 'PRIMARY' when the addPayment is called. We have added the SLEEP(5) code and the result was the same as without it.
	d) Since we can not make overbookings, question d) is very hard to solve. However, theoretically, we should use the lock tables statement. If this is used, session B can not write to the tables simultaneously as session A, preventing overbookings.
	
SECONDARY INDEX
Using secondary index on flights would make it faster to find the right flight, by searching for a specific route in a specific table, instead of looking for all flights in a table. 
	
	
*/












