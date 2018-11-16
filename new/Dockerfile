FROM ruby:2.5.1

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir /cloudware
WORKDIR /cloudware
ADD . /cloudware
RUN bin/setup
