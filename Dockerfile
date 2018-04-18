FROM phusion/passenger-ruby24

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

RUN gem update --system

# Cache webapp's Gems
WORKDIR /home/app/
COPY --chown=app:app ./omniauth-tls.gemspec ./VERSION ./
WORKDIR /home/app/webapp/
COPY --chown=app:app ./webapp/ ./
RUN bundle

WORKDIR /home/app/
COPY --chown=app:app ./ ./

USER app
WORKDIR /home/app/webapp/
ENV RAILS_ENV=development RACK_ENV=development
RUN bundle exec rake assets:precompile

COPY docker/tls/ca.crt docker/tls/server.* /etc/ssl/
COPY docker/localhost.conf /etc/nginx/sites-enabled/

USER root
