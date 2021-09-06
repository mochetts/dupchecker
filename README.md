<h1 align="center">
  Clearscope Duplicate Checker
  <p align="center">
    <a href="https://app.travis-ci.com/mochetts/dupchecker">
      <img alt="Build Status" src="https://app.travis-ci.com/mochetts/dupchecker.svg?branch=main"/>
    </a>
  </p>
</h1>

<p align="center">
A simple plagiarism detection software.
</p>

## Demo

For quick demonstration purposes, you can find the app running under this link:

https://clearscope-dupchecker.herokuapp.com/
## Dependencies

* Ruby 2.6.3
* [Trix Editor](https://github.com/basecamp/trix)
* [Stimulus](https://stimulus.hotwired.dev/)
* [Tailwind CSS](https://tailwindcss.com/)
* [PragmaticSegmenter](https://github.com/diasks2/pragmatic_segmenter)
## Configuration and setup

The project uses sqlite on local and test environments and posgres in production (heroku). So for local development there's no outstanding database config.

Simply run `rails db:migrate` to initialize the database.
## Continuous Integration

This project is integrated with Travis for CI purposes. Check [this link](https://app.travis-ci.com/github/mochetts/dupchecker) to access the travis builds.
## Running the test suite

Run `bundle exec rspec`
## User flow 🚶🏻‍♀️

1. The user writes some text:
![image](https://user-images.githubusercontent.com/3678598/132024330-1ac89fcb-0f35-496c-a310-a4dd6a10812b.png)

2. The "Detect" button is pressed
![image](https://user-images.githubusercontent.com/3678598/132024377-4ba5dc38-1eda-4b48-8ab9-8d22698c3438.png)

3. The results show up on the right side of the screen:
![image](https://user-images.githubusercontent.com/3678598/132043707-33008a8e-fa60-46b2-99f4-12f4cffadf9f.png)

4. If no results are found,  we display it accordingly:
![image](https://user-images.githubusercontent.com/3678598/131694469-cfc59c40-c8d1-4d64-b71b-e4e16a379843.png)

## Rich text editing 🖊️

In order to be able to insert rich text, [Basecamp's trix editor](https://github.com/basecamp/trix) was used:
![image](https://user-images.githubusercontent.com/3678598/131677512-5c120c55-6c6a-4eea-91c7-9429ecb8360c.png)

Worthy to mention that the text the user inputs in this editor is not stored, nor used for any purpose other than looking for plagiarism within the data files.

## Data files 📄

The data files in which the algorithm will look for plagiarism are added within the repo in the `app/data` folder.

## Algorithm  ⚙️

In order to compare the input text and the file contents we first normalize both so that we can establish a common ground for a more accurate comparision. The normalizations done are:
 - down-casing
 - replacing the different quotation types, accented characters and punctuation for double quotes.

Then the algorithm enters in a 4 steps flow in which the output of one step is the input of the other:

### Step 1
Find all possible duplications for the phrases matching the criteria. Used the [PragmaticSegmenter](https://github.com/diasks2/pragmatic_segmenter) to split the sentences. We only keep phrases with a **word count of 8**.

E.g If all this text were plagiarized, this is what the first step would gather:

![image](https://user-images.githubusercontent.com/3678598/132214501-b3ec58dc-df39-4b4b-8b76-58cbedfb3803.png)
_Note: matching phrases are colored for illustration purposes_

### Step 2
Expand matches found in **Step 1** so that we extend matching results as much as we can.

In the previous example, the algorithm would expand each of the found phrases, transforming them into this:

**_Yellow phrase expanded_**

![image](https://user-images.githubusercontent.com/3678598/132214987-b005c394-d9a8-469e-b378-e9085992ad62.png)

**_Red phrase expanded_**

![image](https://user-images.githubusercontent.com/3678598/132215024-2f353f42-ebb1-4d9c-89cc-4502d6a2b90d.png)

**_Blue phrase expanded_**

![image](https://user-images.githubusercontent.com/3678598/132215076-7900133f-c7cf-4de7-adac-cd64a29c9bfe.png)

### Step 3
Merge the results of **Step 2** so that we show matches that are contained within other matches or are consecutive, as one single match.

In the previous example, all three matches (yellow, red and blue) would become one. They would turn into the first one containing all of the three matches, which is the yellow one:

![image](https://user-images.githubusercontent.com/3678598/132215330-5921530c-ce55-4b43-b91d-30efb596d0ee.png)

### Step 4
This algorithm will then return an array of struct objects called `FileMatch`. Each `FileMatch` contains an array of `IndexMatch` which indicates where the matches were found in the input text and in the file.

The following is an illustrative example of what is returned
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

## Displaying results

In order to display `IndexMatches` in the UI, a `PostsHelper` was added. This helper contains only one method that is in charge of displaying a single `IndexMatch` within an enclosed HTML structure.

It basically highlights the matching text and adds leading and trailing dots `...` showing that there's more file text to see if one wanted to.

On a different note, in order to highlight (set text color as red) the plagiarism phrases in the Trix editor, I added a hidden editing button with the functionality of setting the text color as red and call that functionality programmatically with the Trix api functions `setSelectedRange(dupeRange)` and `activateAttribute("highlight")`.

This code is executed within a stimulus controller that wraps the whole form including the trix editor.

## Performance Consideration 🚀

The best way to achieve optimal performance is to index every minimum word length phrase. That way we could avoid using regex to find the plagiarism matches, therefore avoiding an excessive regex backtracking due to a poorly picked word count or due to the usage of large files.  This wasn't implemented, but could be in a future version.

However, in order to provide some IO performance, the data file contents are loaded into server memory when the server starts. For that, a data loader initializer was added that calls the `init` method of the `DuplicateFinderService`. This method simply calls the `files` method in order to memoize the contents of the files within the class. Given that rails caches the classes as soon as they are loaded, we're therefore caching the file contents in server memory.

Worthy to say that this is good for this particular task, but in a real world scenario one would cache the file contents in an in memory caching system such as Redis.

## Future work 🔮

1. Improve UI: Add a way (sidebar or modal) to show the full file contents highlighting the duplications.
2. Add integration tests (e.g using selenium)