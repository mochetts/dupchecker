# Clearscope Duplicate Checker

<h1 align="center">
  <p align="center">
    <a href="https://app.travis-ci.com/mochetts/dupchecker">
      <img alt="Build Status" src="https://app.travis-ci.com/mochetts/dupchecker.svg?branch=main"/>
    </a>
  </p>
</h1>

This project introduces an implementation of a simple plagiarism detection software.
# Demo

For quick demonstration purposes, you can find the app running under this link:

https://clearscope-dupchecker.herokuapp.com/
# Dependencies

* Ruby 2.6.3

* [Trix Editor](https://github.com/basecamp/trix), [Tailwind CSS](https://tailwindcss.com/)
# Configuration and setup

The project uses sqlite on local and test environments and posgres in production (heroku). So for local development there's no outstanding database config.

Simply run `rails db:migrate` to initialize the database.
# Continuous Integration

This project is integrated with Travis for CI purposes. Check [this link](https://app.travis-ci.com/github/mochetts/dupchecker) to access the travis builds.
# Running the test suite

Run `bundle exec rspec`
