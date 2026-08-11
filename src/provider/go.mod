module github.com/quanttide/qtcloud-delib-provider

go 1.26

require (
	github.com/golang-jwt/jwt/v5 v5.3.1
	github.com/google/uuid v1.6.0
	github.com/quanttide/quanttide-delib-toolkit/packages/go v0.0.0-00010101000000-000000000000
	gorm.io/driver/postgres v1.6.2
	gorm.io/driver/sqlite v1.6.0
	gorm.io/gorm v1.31.2
)

require (
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/pgx/v5 v5.10.0 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/jinzhu/inflection v1.0.0 // indirect
	github.com/jinzhu/now v1.1.5 // indirect
	github.com/mattn/go-sqlite3 v1.14.22 // indirect
	golang.org/x/sync v0.17.0 // indirect
	golang.org/x/text v0.29.0 // indirect
)

replace github.com/quanttide/quanttide-delib-toolkit/packages/go => ../../../../packages/quanttide-delib-toolkit/packages/go
