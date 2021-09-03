import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["element", "dupes"]

  connect() {
    const dupes = JSON.parse(this.dupesTarget.value)
    dupes.map(dupeRange => {
      this.elementTarget.editor.setSelectedRange([dupeRange[0], dupeRange[1] + 1])
      this.elementTarget.editor.activateAttribute("highlight")
    })
    this.elementTarget.editor.setSelectedRange([0, 0])
  }
}