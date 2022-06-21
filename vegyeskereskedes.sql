-- phpMyAdmin SQL Dump
-- version 4.9.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 02, 2020 at 09:30 PM
-- Server version: 10.4.10-MariaDB
-- PHP Version: 7.3.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `vegyeskereskedes`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `aruhazraktar_info_where`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `aruhazraktar_info_where` (IN `aruhaz_id` INT(11), IN `tnev` VARCHAR(20), IN `tipus` VARCHAR(20))  BEGIN

    SELECT * FROM aruhaz_raktarinfo
    WHERE
        (aruhaz_id IS NULL OR id_aruhaz = aruhaz_id) AND
        (tnev IS NULL OR termek_nev LIKE CONCAT('%', tnev, '%')) AND
        (tipus IS NULL OR termek_tipus LIKE CONCAT('%', tipus, '%'));

END$$

DROP PROCEDURE IF EXISTS `aruhaz_info_where`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `aruhaz_info_where` (IN `aruhaz_id` INT(11))  BEGIN

    SELECT * FROM aruhaz_info
    WHERE aruhaz_info.id_aruhaz = aruhaz_id;

END$$

DROP PROCEDURE IF EXISTS `beszallitas`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `beszallitas` (IN `aruhaz_id` INT(11), IN `termek_id` INT(11), IN `mennyiseg` INT(3))  BEGIN
    
    DECLARE id_a, id_t, d BOOLEAN;
    
    SELECT EXISTS(SELECT id_aruhaz FROM aruhazak WHERE id_aruhaz = aruhaz_id)
    INTO id_a;
    
    SELECT EXISTS(SELECT id_termek FROM termekek WHERE id_termek = termek_id)
    INTO id_t;
    
    IF id_a AND id_t THEN
        SELECT EXISTS(SELECT id_termek FROM raktar
        WHERE id_aruhaz = aruhaz_id AND id_termek = termek_id)
        INTO id_t;
    
        IF id_t THEN    
            UPDATE raktar
            SET termek_mennyiseg = termek_mennyiseg + mennyiseg,
                utolso_szallitas = CURDATE()
            WHERE id_aruhaz = aruhaz_id AND id_termek = termek_id;
        ELSE
            INSERT INTO raktar (id_aruhaz, id_termek, termek_mennyiseg, utolso_szallitas)
            VALUES (aruhaz_id, termek_id, mennyiseg, CURDATE());
        END IF;

        SELECT EXISTS(SELECT datum FROM penz
        WHERE id_aruhaz = aruhaz_id AND datum = CURDATE())
        INTO d;

        IF d THEN
            UPDATE penz
            SET kiadas = kiadas + beszallitas_ara(termek_id, mennyiseg)
            WHERE id_aruhaz = aruhaz_id AND datum = CURDATE();
        ELSE
            INSERT INTO penz (id_aruhaz, bevetel, kiadas, datum)
            VALUES (aruhaz_id, 0, beszallitas_ara(termek_id, mennyiseg), CURDATE());
        END IF;
        SELECT raktar.id_aruhaz, raktar.termek_mennyiseg, termekek.termek_nev, termekek.termek_ar, penz.kiadas
        FROM raktar
        JOIN termekek ON termekek.id_termek = raktar.id_termek
        JOIN penz ON penz.id_aruhaz = raktar.id_aruhaz
        WHERE raktar.id_aruhaz = aruhaz_id AND raktar.id_termek = termek_id AND penz.datum = CURDATE();
    ELSE
        SELECT "NEM TORTENT SEMMI SEM" AS "HIBA";
    END IF;
    
END$$

DROP PROCEDURE IF EXISTS `munkas_info_where`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `munkas_info_where` (IN `aruhaz_id` INT(11), IN `vezeteknev` VARCHAR(20), IN `keresztnev` VARCHAR(20), IN `telepules` VARCHAR(20), IN `munka` VARCHAR(20))  BEGIN

    SELECT * FROM munkas_info
    WHERE
        (aruhaz_id IS NULL OR id_aruhaz = aruhaz_id) AND 
        (vezeteknev IS NULL OR munkas_vezeteknev LIKE CONCAT('%', vezeteknev , '%')) AND
        (keresztnev IS NULL OR munkas_keresztnev LIKE CONCAT('%', keresztnev , '%')) AND
        (telepules IS NULL OR munkas_telepules LIKE CONCAT('%', telepules, '%')) AND
        (munka IS NULL OR munka_nev LIKE CONCAT('%', munka , '%'));

END$$

DROP PROCEDURE IF EXISTS `uj_aruhaz`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `uj_aruhaz` (IN `telepules` VARCHAR(20), IN `cim` VARCHAR(27), IN `hazszam` INT(3))  BEGIN

    INSERT INTO aruhazak (aruhaz_telepules, aruhaz_cim)
    VALUES (telepules, CONCAT(cim, ', ', hazszam));
    
    SELECT * FROM aruhazak
    ORDER BY id_aruhaz DESC LIMIT 1;

END$$

DROP PROCEDURE IF EXISTS `uj_munkas`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `uj_munkas` (IN `vezeteknev` VARCHAR(20), IN `keresztnev` VARCHAR(20), IN `JMBG` BIGINT(13), IN `telepules` VARCHAR(20), IN `cim` VARCHAR(27), IN `hazszam` INT(3), IN `aruhazid` INT(11), IN `munkaid` INT(11))  BEGIN

    DECLARE id_a, id_m BOOLEAN;

    SELECT EXISTS(SELECT id_aruhaz FROM aruhazak WHERE id_aruhaz = aruhazid)
    INTO id_a;
    
    SELECT EXISTS(SELECT id_munka FROM munkak WHERE id_munka = munkaid)
    INTO id_m;
    
    IF id_a AND id_M AND LENGTH(JMBG) = 13 THEN
        INSERT INTO munkasok (id_aruhaz, id_munka, jmbg, munkas_vezeteknev, munkas_keresztnev, munkas_telepules, munkas_cim)
        VALUES (aruhazid, munkaid, JMBG, vezeteknev, keresztnev, telepules, CONCAT(cim, ', ', hazszam));
    
        SELECT * FROM munkasok
        ORDER BY id_munkas DESC LIMIT 1;
    ELSE
        SELECT "NEM TORTENT SEMMI SEM" AS "HIBA";
    END IF;

END$$

DROP PROCEDURE IF EXISTS `uj_termek`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `uj_termek` (IN `nev` VARCHAR(20), IN `tipus` VARCHAR(20), IN `leiras` VARCHAR(512), IN `ar` INT(5))  BEGIN

    INSERT INTO termekek (termek_nev, termek_tipus, termek_leiras, termek_ar)
    VALUES (nev, tipus, leiras, ar);
    
    SELECT * FROM termekek
    ORDER BY id_termek DESC LIMIT 1;

END$$

DROP PROCEDURE IF EXISTS `vasarlas`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `vasarlas` (IN `aruhaz_id` INT(11), IN `termek_id` INT(11), IN `mennyiseg` INT(3))  BEGIN

    DECLARE t_mennyiseg INT(5);
    DECLARE id_a, id_t, d BOOLEAN;
    
    SELECT termek_mennyiseg INTO t_mennyiseg
    FROM raktar
    WHERE id_aruhaz = aruhaz_id AND id_termek = termek_id;
    
    SELECT EXISTS(SELECT id_aruhaz FROM aruhazak WHERE id_aruhaz = aruhaz_id)
    INTO id_a;
    
    SELECT EXISTS(SELECT id_termek FROM termekek WHERE id_termek = termek_id)
    INTO id_t;

    IF t_mennyiseg >= mennyiseg AND id_a AND id_t THEN
        UPDATE raktar
        SET termek_mennyiseg = termek_mennyiseg - mennyiseg
        WHERE id_aruhaz = aruhaz_id AND id_termek = termek_id;
        
        SELECT EXISTS(SELECT datum FROM penz
        WHERE id_aruhaz = aruhaz_id AND datum = CURDATE())
        INTO d;
        
        IF d THEN
            UPDATE penz
            SET bevetel = bevetel + vasarlas_ara(termek_id, mennyiseg)
            WHERE id_aruhaz = aruhaz_id AND datum = CURDATE();
        ELSE
            INSERT INTO penz (id_aruhaz, bevetel, kiadas, datum)
            VALUES (aruhaz_id, vasarlas_ara(termek_id, mennyiseg), 0, CURDATE());
        END IF;
        SELECT raktar.id_aruhaz, raktar.termek_mennyiseg, termekek.termek_nev, termekek.termek_ar, penz.bevetel, raktar.utolso_szallitas
        FROM raktar
        JOIN termekek ON termekek.id_termek = raktar.id_termek
        JOIN penz ON penz.id_aruhaz = raktar.id_aruhaz
        WHERE raktar.id_aruhaz = aruhaz_id AND raktar.id_termek = termek_id AND penz.datum = CURDATE();
    ELSE
        SELECT "NEM TORTENT SEMMI SEM" AS "HIBA";
    END IF;
    
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `beszallitas_ara`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `beszallitas_ara` (`termek_id` INT(11), `mennyiseg` INT(3)) RETURNS INT(8) BEGIN
    DECLARE ar INT(6);
    SELECT termek_ar INTO ar
    FROM termekek
    WHERE id_termek = termek_id;
    SET ar = (ar*mennyiseg)/2;
    RETURN ar;
END$$

DROP FUNCTION IF EXISTS `vasarlas_ara`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `vasarlas_ara` (`termek_id` INT(11), `mennyiseg` INT(3)) RETURNS INT(8) BEGIN
    DECLARE ar INT(6);
    SELECT termek_ar INTO ar
    FROM termekek
    WHERE id_termek = termek_id;
    SET ar = ar*mennyiseg;
    RETURN ar;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `aruhazak`
--

DROP TABLE IF EXISTS `aruhazak`;
CREATE TABLE IF NOT EXISTS `aruhazak` (
  `id_aruhaz` int(11) NOT NULL AUTO_INCREMENT,
  `aruhaz_telepules` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `aruhaz_cim` varchar(30) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id_aruhaz`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `aruhazak`
--

INSERT INTO `aruhazak` (`id_aruhaz`, `aruhaz_telepules`, `aruhaz_cim`) VALUES
(1, 'SUBOTICA', 'MATIJE KORVINA, 3'),
(2, 'SUBOTICA', 'VUKA KARADŽIĆA, 13'),
(3, 'KANJIŽA', 'SVETOG STEFANA, 6'),
(4, 'SUBOTICA', 'KARAĐORĐEV PUT, 74');

--
-- Triggers `aruhazak`
--
DROP TRIGGER IF EXISTS `insert_aruhaz_upper`;
DELIMITER $$
CREATE TRIGGER `insert_aruhaz_upper` BEFORE INSERT ON `aruhazak` FOR EACH ROW SET NEW.aruhaz_telepules = UPPER(NEW.aruhaz_telepules),
    NEW.aruhaz_cim = UPPER(NEW.aruhaz_cim)
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_aruhaz_upper`;
DELIMITER $$
CREATE TRIGGER `update_aruhaz_upper` BEFORE UPDATE ON `aruhazak` FOR EACH ROW SET NEW.aruhaz_telepules = UPPER(NEW.aruhaz_telepules),
    NEW.aruhaz_cim = UPPER(NEW.aruhaz_cim)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `aruhaz_info`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `aruhaz_info`;
CREATE TABLE IF NOT EXISTS `aruhaz_info` (
`id_aruhaz` int(11)
,`aruhaz_telepules` varchar(20)
,`aruhaz_cim` varchar(30)
,`termek_mennyiseg` decimal(32,0)
,`bevetel` decimal(32,0)
,`kiadas` decimal(32,0)
,`jovedelem` decimal(33,0)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `aruhaz_raktarinfo`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `aruhaz_raktarinfo`;
CREATE TABLE IF NOT EXISTS `aruhaz_raktarinfo` (
`id_aruhaz` int(11)
,`id_termek` int(11)
,`termek_nev` varchar(20)
,`termek_tipus` varchar(20)
,`termek_ar` int(5)
,`termek_mennyiseg` int(5)
,`utolso_szallitas` date
);

-- --------------------------------------------------------

--
-- Table structure for table `munkak`
--

DROP TABLE IF EXISTS `munkak`;
CREATE TABLE IF NOT EXISTS `munkak` (
  `id_munka` int(11) NOT NULL AUTO_INCREMENT,
  `munka_nev` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `munka_leiras` varchar(200) COLLATE utf8_unicode_ci DEFAULT NULL,
  `munka_fizetes` int(6) NOT NULL,
  `munka_ora` int(2) NOT NULL,
  PRIMARY KEY (`id_munka`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `munkak`
--

INSERT INTO `munkak` (`id_munka`, `munka_nev`, `munka_leiras`, `munka_fizetes`, `munka_ora`) VALUES
(1, 'PÉNZTÁROS', NULL, 28000, 8),
(2, 'TAKARÍTÓ', NULL, 24000, 6);

--
-- Triggers `munkak`
--
DROP TRIGGER IF EXISTS `insert_munkanev_upper`;
DELIMITER $$
CREATE TRIGGER `insert_munkanev_upper` BEFORE INSERT ON `munkak` FOR EACH ROW SET NEW.munka_nev = UPPER(NEW.munka_nev)
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_munkanev_upper`;
DELIMITER $$
CREATE TRIGGER `update_munkanev_upper` BEFORE UPDATE ON `munkak` FOR EACH ROW SET NEW.munka_nev = UPPER(NEW.munka_nev)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `munkasok`
--

DROP TABLE IF EXISTS `munkasok`;
CREATE TABLE IF NOT EXISTS `munkasok` (
  `id_munkas` int(11) NOT NULL AUTO_INCREMENT,
  `id_aruhaz` int(11) NOT NULL,
  `id_munka` int(11) NOT NULL,
  `jmbg` bigint(13) NOT NULL,
  `munkas_vezeteknev` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `munkas_keresztnev` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `munkas_telepules` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `munkas_cim` varchar(30) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id_munkas`),
  UNIQUE KEY `jmbg` (`jmbg`),
  KEY `id_aruhaz` (`id_aruhaz`) USING BTREE,
  KEY `id_munka` (`id_munka`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `munkasok`
--

INSERT INTO `munkasok` (`id_munkas`, `id_aruhaz`, `id_munka`, `jmbg`, `munkas_vezeteknev`, `munkas_keresztnev`, `munkas_telepules`, `munkas_cim`) VALUES
(1, 3, 1, 7025141172364, 'SZŰCS', 'ENDRE', 'SUBOTICA', 'ČARNOJEVIĆA, 16'),
(2, 2, 1, 2207234496317, 'KISS', 'FERENC', 'SUBOTICA', 'VERUŠIĆKA, 17'),
(3, 1, 1, 5749428967030, 'NAGY', 'ISTVÁN', 'KANJIŽA', 'GENERALA KUTUZOVA, 2'),
(4, 1, 2, 6846506836910, 'MÉSZÁROS', 'JULIANNA', 'KANJIŽA', 'VOJISLAVA ILIĆA, 9'),
(5, 4, 1, 4549772680092, 'LAKATOS', 'ÁKOS', 'SUBOTICA', 'STEVANA FILIPOVIĆA, 42');

--
-- Triggers `munkasok`
--
DROP TRIGGER IF EXISTS `insert_name_upper`;
DELIMITER $$
CREATE TRIGGER `insert_name_upper` BEFORE INSERT ON `munkasok` FOR EACH ROW SET NEW.munkas_vezeteknev = UPPER(NEW.munkas_vezeteknev),
    NEW.munkas_keresztnev = UPPER(NEW.munkas_keresztnev),
    NEW.munkas_cim = UPPER(NEW.munkas_cim),
    NEW.munkas_telepules = UPPER(NEW.munkas_telepules)
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_name_upper`;
DELIMITER $$
CREATE TRIGGER `update_name_upper` BEFORE UPDATE ON `munkasok` FOR EACH ROW SET NEW.munkas_vezeteknev = UPPER(NEW.munkas_vezeteknev),
    NEW.munkas_keresztnev = UPPER(NEW.munkas_keresztnev),
    NEW.munkas_cim = UPPER(NEW.munkas_cim),
    NEW.munkas_telepules = UPPER(NEW.munkas_telepules)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `munkas_info`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `munkas_info`;
CREATE TABLE IF NOT EXISTS `munkas_info` (
`id_aruhaz` int(11)
,`munkas_vezeteknev` varchar(20)
,`munkas_keresztnev` varchar(20)
,`munkas_telepules` varchar(20)
,`munka_nev` varchar(20)
,`munka_fizetes` int(6)
);

-- --------------------------------------------------------

--
-- Table structure for table `penz`
--

DROP TABLE IF EXISTS `penz`;
CREATE TABLE IF NOT EXISTS `penz` (
  `id_penz` int(11) NOT NULL AUTO_INCREMENT,
  `id_aruhaz` int(11) NOT NULL,
  `bevetel` int(8) NOT NULL,
  `kiadas` int(8) NOT NULL,
  `datum` date NOT NULL,
  PRIMARY KEY (`id_penz`),
  KEY `id_aruhaz` (`id_aruhaz`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `penz`
--

INSERT INTO `penz` (`id_penz`, `id_aruhaz`, `bevetel`, `kiadas`, `datum`) VALUES
(1, 1, 0, 1500, '2020-05-31'),
(2, 1, 3100, 3750, '2020-06-01'),
(3, 2, 3800, 6050, '2020-06-01'),
(4, 3, 4000, 3500, '2020-06-01'),
(5, 1, 3575, 1375, '2020-06-02'),
(6, 2, 4000, 0, '2020-06-02');

-- --------------------------------------------------------

--
-- Table structure for table `raktar`
--

DROP TABLE IF EXISTS `raktar`;
CREATE TABLE IF NOT EXISTS `raktar` (
  `id_raktar` int(11) NOT NULL AUTO_INCREMENT,
  `id_aruhaz` int(11) NOT NULL,
  `id_termek` int(11) NOT NULL,
  `termek_mennyiseg` int(5) NOT NULL,
  `utolso_szallitas` date NOT NULL,
  PRIMARY KEY (`id_raktar`),
  KEY `id_termek` (`id_termek`) USING BTREE,
  KEY `id_aruhaz` (`id_aruhaz`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `raktar`
--

INSERT INTO `raktar` (`id_raktar`, `id_aruhaz`, `id_termek`, `termek_mennyiseg`, `utolso_szallitas`) VALUES
(1, 1, 2, 10, '2020-06-01'),
(2, 2, 1, 50, '2020-06-01'),
(3, 1, 3, 10, '2020-06-01'),
(4, 3, 3, 50, '2020-06-01'),
(5, 2, 2, 30, '2020-06-01'),
(6, 1, 1, 10, '2020-06-01'),
(7, 2, 3, 0, '2020-06-01'),
(8, 3, 1, 0, '2020-06-01'),
(9, 1, 5, 25, '2020-06-02');

-- --------------------------------------------------------

--
-- Table structure for table `termekek`
--

DROP TABLE IF EXISTS `termekek`;
CREATE TABLE IF NOT EXISTS `termekek` (
  `id_termek` int(11) NOT NULL AUTO_INCREMENT,
  `termek_nev` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `termek_tipus` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `termek_leiras` varchar(512) COLLATE utf8_unicode_ci DEFAULT NULL,
  `termek_ar` int(5) NOT NULL,
  PRIMARY KEY (`id_termek`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `termekek`
--

INSERT INTO `termekek` (`id_termek`, `termek_nev`, `termek_tipus`, `termek_leiras`, `termek_ar`) VALUES
(1, 'COCA COLA 2L', 'ÜDÍTŐ', NULL, 100),
(2, 'COCA COLA 1L', 'ÜDÍTŐ', NULL, 60),
(3, 'CHIPSY CLASSIC 150G', 'CSEMEGE', NULL, 60),
(4, 'FANTA ORANGE 330ML', 'ÜDÍTŐ', NULL, 55),
(5, 'STARK SMOKI', 'CSEMEGE', NULL, 55);

--
-- Triggers `termekek`
--
DROP TRIGGER IF EXISTS `insert_termekeknev_upper`;
DELIMITER $$
CREATE TRIGGER `insert_termekeknev_upper` BEFORE INSERT ON `termekek` FOR EACH ROW SET NEW.termek_nev = UPPER(NEW.termek_nev),
    NEW.termek_tipus = UPPER(NEW.termek_tipus)
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_termekeknev_upper`;
DELIMITER $$
CREATE TRIGGER `update_termekeknev_upper` BEFORE UPDATE ON `termekek` FOR EACH ROW SET NEW.termek_nev = UPPER(NEW.termek_nev),
    NEW.termek_tipus = UPPER(NEW.termek_tipus)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure for view `aruhaz_info`
--
DROP TABLE IF EXISTS `aruhaz_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `aruhaz_info`  AS  select `aruhazak`.`id_aruhaz` AS `id_aruhaz`,`aruhazak`.`aruhaz_telepules` AS `aruhaz_telepules`,`aruhazak`.`aruhaz_cim` AS `aruhaz_cim`,sum(distinct `raktar`.`termek_mennyiseg`) AS `termek_mennyiseg`,sum(distinct `penz`.`bevetel`) AS `bevetel`,sum(distinct `penz`.`kiadas`) AS `kiadas`,sum(distinct `penz`.`bevetel`) - sum(distinct `penz`.`kiadas`) AS `jovedelem` from ((`aruhazak` join `raktar` on(`raktar`.`id_aruhaz` = `aruhazak`.`id_aruhaz`)) join `penz` on(`penz`.`id_aruhaz` = `aruhazak`.`id_aruhaz`)) group by `aruhazak`.`id_aruhaz` ;

-- --------------------------------------------------------

--
-- Structure for view `aruhaz_raktarinfo`
--
DROP TABLE IF EXISTS `aruhaz_raktarinfo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `aruhaz_raktarinfo`  AS  select `raktar`.`id_aruhaz` AS `id_aruhaz`,`termekek`.`id_termek` AS `id_termek`,`termekek`.`termek_nev` AS `termek_nev`,`termekek`.`termek_tipus` AS `termek_tipus`,`termekek`.`termek_ar` AS `termek_ar`,`raktar`.`termek_mennyiseg` AS `termek_mennyiseg`,`raktar`.`utolso_szallitas` AS `utolso_szallitas` from (`raktar` join `termekek` on(`termekek`.`id_termek` = `raktar`.`id_termek`)) ;

-- --------------------------------------------------------

--
-- Structure for view `munkas_info`
--
DROP TABLE IF EXISTS `munkas_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `munkas_info`  AS  select `munkasok`.`id_aruhaz` AS `id_aruhaz`,`munkasok`.`munkas_vezeteknev` AS `munkas_vezeteknev`,`munkasok`.`munkas_keresztnev` AS `munkas_keresztnev`,`munkasok`.`munkas_telepules` AS `munkas_telepules`,`munkak`.`munka_nev` AS `munka_nev`,`munkak`.`munka_fizetes` AS `munka_fizetes` from (`munkasok` join `munkak` on(`munkak`.`id_munka` = `munkasok`.`id_munka`)) order by `munkasok`.`id_aruhaz` ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `munkasok`
--
ALTER TABLE `munkasok`
  ADD CONSTRAINT `munkas_aruhaz` FOREIGN KEY (`id_aruhaz`) REFERENCES `aruhazak` (`id_aruhaz`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `munkas_munka` FOREIGN KEY (`id_munka`) REFERENCES `munkak` (`id_munka`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `penz`
--
ALTER TABLE `penz`
  ADD CONSTRAINT `penz_aruhaz` FOREIGN KEY (`id_aruhaz`) REFERENCES `aruhazak` (`id_aruhaz`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `raktar`
--
ALTER TABLE `raktar`
  ADD CONSTRAINT `raktar_aruhaz` FOREIGN KEY (`id_aruhaz`) REFERENCES `aruhazak` (`id_aruhaz`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `raktar_termek` FOREIGN KEY (`id_termek`) REFERENCES `termekek` (`id_termek`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
