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

# Description

This project introduces an implementation of a simple plagiarism detection software. For quick demonstration purposes, you can find the app running under this link: https://clearscope-dupchecker.herokuapp.com/

# User flow 🚶🏻‍♀️

1. The user writes some text:
![image](https://user-images.githubusercontent.com/3678598/132024330-1ac89fcb-0f35-496c-a310-a4dd6a10812b.png)

2. The "Check" button is pressed
![image](https://user-images.githubusercontent.com/3678598/132024377-4ba5dc38-1eda-4b48-8ab9-8d22698c3438.png)

3. The results show up on the right side of the screen:
![image](https://user-images.githubusercontent.com/3678598/132024412-882b8ed2-7ab1-494b-9f94-582ba1966cec.png)

4. If no results are found,  we display it accordingly:
![image](https://user-images.githubusercontent.com/3678598/131694469-cfc59c40-c8d1-4d64-b71b-e4e16a379843.png)

# Rich text editing 🖊️

In order to be able to insert rich text, [Basecamp's trix editor](https://github.com/basecamp/trix) was used:
![image](https://user-images.githubusercontent.com/3678598/131677512-5c120c55-6c6a-4eea-91c7-9429ecb8360c.png)

Worthy to mention that the text the user inputs in this editor is not stored, nor used for any purpose other than looking for plagiarism within the data files.

# Data files 📄

The data files in which the algorithm will look for plagiarism are added within the repo in the `app/data` folder.

# Algorithm  ⚙️

In order to compare the input text and the file contents we first normalize both so that we can establish a common ground for a more accurate comparision. The normalizations done are:
 - down-casing
 - replacing the different quotation types, accented characters and punctuation for double quotes.

Then the algorithm enters in a 3 steps flow in which the output of one step is the input of the other:

**Step 1)** Find all possible duplications for the phrases matching the criteria. Used the [PragmaticSegmenter](https://github.com/diasks2/pragmatic_segmenter) to split the sentences. We only keep phrases with a **word count of 8**.
**Step 2)** Expand matches found in **Step 1** so that we extend matching results as much as we can.
**Step 3)** Merge the results of **Step 2** so that we show matches that are contained within other matches or are consecutive as 1 single match.

This algorithm will then return an array of struct objects called `FileMatch`. Each `FileMatch` contains an array of `IndexMatch` which indicates where the matches were found (in the input text and in the file).

The following is a similar example of what is returned
```rb
[
{ # FileMatch
  file_name: ..., # The name of the file in which the duplicate phrases were found
  file_content: ..., # The original content of the file
  phrase_matches: [
    { # IndexMatch
      text_start: ..., # Start index in the text input
      file_start: ..., # Start index in the file content
      text_end: ..., # End index in the text input
      file_end: ..., # End index in the file content
    },
    ...
  ]
},
...
]
```

# Displaying results in the UI

In order to display `IndexMatches` in the UI, a `PostsHelper` was added. This helper contains only one method that is in charge of displaying a single `IndexMatch` within an enclosed HTML structure.

It basically highlights the matching text and adds leading and trailing dots `...` showing that there's more file text.

# Performance Consideration 🚀

The best way to achieve optimal performance is to index every minimum word length phrase. That way we could avoid using regex to find the plagiarism matches, therefore avoiding an excessive regex backtracking due to a poorly picked word count or due to the usage of large files.  This wasn't implemented, but could be implemented in a future version.

However, in order to provide some IO performance. The data files are loaded in memory when the rails server starts. For that, data loader initializer was added that it calls the `init` method of the `DuplicateFinderService`. That `init` method simply calls the `files` method in order to memoize the contents of the files within the class. Given that rails caches the classes as soon as they are loaded, we're also caching the files in server memory.

Worthy to say that this is good for this particular task, but in a real world scenario one would cache the file contents in an in memory caching system such as Redis.

# Future work 🔮

1. Add a way (sidebar or modal) to show the full file contents highlighting the duplications
2. Add integration tests (e.g using selenium)