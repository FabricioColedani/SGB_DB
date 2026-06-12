-- CREAR BASE DE DATOS
CREATE DATABASE liga_basquet;
\c liga_basquet

-- CREAR TABLAS
CREATE TABLE Equipo (
    id_equipo SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    tecnico VARCHAR(100),
    anio_fundacion INT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Jugador (
    id_jugador SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    posicion VARCHAR(50),
    altura NUMERIC(4,2),
    peso NUMERIC(5,2),
    id_equipo INT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_equipo)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Estadio (
    id_estadio SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    capacidad INT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Arbitro (
    id_arbitro SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Partido (
    id_partido SERIAL PRIMARY KEY,
    fecha DATE,
    hora TIME,
    puntos_local INT,
    puntos_visitante INT,
    id_equipo_local INT,
    id_equipo_visitante INT,
    id_estadio INT,
    id_arbitro INT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_equipo_local)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_equipo_visitante)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_estadio)
        REFERENCES Estadio (id_estadio)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_arbitro)
        REFERENCES Arbitro (id_arbitro)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Estadistica (
    id_estadistica SERIAL PRIMARY KEY,
    id_jugador INT NOT NULL,
    id_partido INT NOT NULL,
    puntos INT DEFAULT 0,
    rebotes INT DEFAULT 0,
    asistencias INT DEFAULT 0,
    robos INT DEFAULT 0,
    tapas INT DEFAULT 0,
    minutos_jugados INT DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_jugador)
        REFERENCES Jugador (id_jugador)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (id_partido)
        REFERENCES Partido (id_partido)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
