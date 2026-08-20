# shorten-url-deployment

### How to check the database

- Run `docker exec -it postgres psql -U admin -d bookmark`
- If we see the following prompt, it means that we have successfully connected to the database:

```
bookmark=#
```

- Then we can exit by typing `\q`.
- It will be the same for `user` database.

### How to access swagger

- `http://localhost/api/bookmark-service/swagger/index.html#/`