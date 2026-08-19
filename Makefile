generate-rsa-key:
	openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048
	openssl rsa -pubout -in private.pem -out public.pem

deploy:
	docker-compose up -d

remove-database:
	docker compose down -v
	sudo rm -rf ./postgres_data

full-deploy: generate-rsa-key deploy