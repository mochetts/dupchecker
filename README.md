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

# User flow

1. The user writes some text:
![image](https://user-images.githubusercontent.com/3678598/131676159-85431acb-4bc4-4028-8b1b-d9f3d5c38c26.png)

2. The "Check" button is pressed
![image](https://user-images.githubusercontent.com/3678598/131676261-b925cfe8-2c15-4f5f-8b91-a5fced37a323.png)

3. The results show up on the right side of the screen:
![image](https://user-images.githubusercontent.com/3678598/131676402-87885fd3-ab7c-40a6-a89b-2541e05893e2.png)

# Rich text editing

In order to be able to insert rich text, [Basecamp's trix editor](https://github.com/basecamp/trix) was used:
![image](https://user-images.githubusercontent.com/3678598/131677512-5c120c55-6c6a-4eea-91c7-9429ecb8360c.png)

Worthy to mention that the text the user inputs in this editor is not store, nor used for any purpose other than looking for plagiarism within the data files.

# Data files

The data files in which the algorithm will look for plagiarism are added within the repo in the `app/data` folder.

# Algorithm

The duplicate find algorithm consist in 2 main procedures:

1. Normalize both the input text and the data files contents. The reason behind this is that we can establish a common ground for more accurate comparisons. The normalizations done are:
 - down-casing
 - replacing the different quotation types for double quotes.

2. Split the input text by **punctuations and line breaks**.

3. Iterate every file looking for duplicate phrases that are longer than a pre stablished **word count of 10**.

This algorithm will return an array containing a hash with the following structure:
```rb
[
{
  file: ..., # The name of the file in which the duplicate phrases were found
  content: ..., # The original content of the file
  matches: [ # Array of duplicate phrases found within the file
    {
      phrase: ..., # The duplicate phrase,
      indices: ..., # Array of indices in which the phrase was found within the file
    },
    ...
  ]
},
...
]
```

For this algorithm a scan using an exact match regex was used to find the normalized version of a phrase within the normalized version of the file.

# Second stage processing

In order to provide a better feedback and extend the algorithm we post process the duplications when rendering them trying to find not only the duplications that are split by punctuations and line breaks, but we extend the lookup forward and backwards for each phrase until we there's no coincidence with the file's original text.

That way we can include phrases that don't meet the minimum word count requirement of the backend algorithm.

For example, this phrase:
```
© 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.
```

Has only 1 phrase that is 10 words long or more:
```
Our website services, content, and products are for informational purposes only
```

So if one of the data files contains this exact whole text, the duplicate finder service will only find that phrase due to the splitting.

Due to this and in order to be more accurate with the displayed results we post-process the algorithm results in a `PostHelper` trying to match as much as we can backwards and forwards of the initial duplicated phrase.

# Performance Consideration

The best way to achieve optimal performance is to index every minimum word length phrase. That way we could avoid using regex to find the plagiarism matches, therefore avoiding an excessive regex backtracking due to a poorly picked word count or due to the usage of large files.  This wasn't implemented, but could be implemented in a future version.

However, in order to provide some IO performance. The data files are loaded in memory when the rails server starts. For that, data loader initializer was added that it calls the `init` method of the `DuplicateFinderService`. That `init` method simply calls the `files` method in order to memoize the contents of the files within the class. Given that rails caches the classes as soon as they are loaded, we're also caching the files in server memory.

Worthy to say that this is good for this particular task, but in a real world scenario one would cache the file contents in an in memory caching system such as Redis.
