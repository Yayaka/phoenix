# Yayaka Reference

## Environment Variables

- *HOST*  
  The hostname
- *DATABASE_URL*
- *POOL_SIZE*
- *GUARDIAN_SECRET_KEY*  
  A secret key to sign the api tokens.
- *SECRET_KEY_BASE*  
  A secret key to sign cookies, tokens, etc.

## Deploying on Heroku

```bash
heroku create
export APP=YOUR_APP_NAME
heroku buildpacks:add -a $APP https://github.com/HashNuke/heroku-buildpack-elixir.git
heroku buildpacks:add -a $APP https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
heroku addons:create -a $APP heroku-postgresql:hobby-dev
heroku config:set -a $APP POOL_SIZE=18
heroku config:set -a $APP HOST=${APP}.herokuapp.com
heroku config:set -a $APP GUARDIAN_SECRET_KEY=`mix phx.gen.secret`
heroku config:set -a $APP SECRET_KEY_BASE=`mix phx.gen.secret`
heroku git:remote -a $APP --remote heroku-deployment
git push heroku-deployment heroku:master
heroku run -a $APP "POOL_SIZE=1 mix ecto.migrate"
```
