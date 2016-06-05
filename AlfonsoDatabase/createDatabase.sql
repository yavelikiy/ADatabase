CREATE DATABASE [<!dbName!>]
ON(
	NAME = <!dbName!>_data,
	FILENAME = '<!dbPath!><!dbName!>.mdf',
	SIZE = 200MB,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 200MB
)LOG ON(
	NAME = <!dbName!>_log,
	FILENAME = '<!dbPath!><!dbName!>.ldf',
	SIZE = 200MB,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 200MB
)
GO
ALTER DATABASE [<!dbName!>] SET AUTO_CLOSE OFF
GO