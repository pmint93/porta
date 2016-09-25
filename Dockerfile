FROM ruby:2.3

MAINTAINER Thanh Pham Minh (Eric Phan) <phamminhthanh69@gmail.com>

ENV INSTALL_PATH /usr/src/app

RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

RUN chmod u+x ./application.rb

CMD ./application.rb
