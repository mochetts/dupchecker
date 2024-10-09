// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

require("@rails/activestorage").start()
require("channels")
const Trix = require("trix")
require("@rails/actiontext")

import "controllers"

// Tailwind CSS
import "stylesheets/application" // ADD THIS LINE

Trix.config.textAttributes.highlight = {
  style: { color: "red" },
  parser: function(element) {
    return element.style.color === "red"
  },
  inheritable: true
}

addEventListener("trix-initialize", function(event) {
  var buttonHTML = '<button type="button" class="hidden" data-trix-attribute="highlight">H</button>'
  event.target.toolbarElement.querySelector(".trix-button-group--text-tools").insertAdjacentHTML("beforeend", buttonHTML)
})