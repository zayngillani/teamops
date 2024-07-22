import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query"]

  connect() {
    this.queryTarget.addEventListener("input", this.performSearch.bind(this))
  }

  disconnect() {
    this.queryTarget.removeEventListener("input", this.performSearch.bind(this))
  }

  performSearch() {
    clearTimeout(this.debounceTimeout)

    this.debounceTimeout = setTimeout(() => {
      const query = this.queryTarget.value
      fetch(`${this.element.action}?q=${encodeURIComponent(query)}`, {
        headers: { 'Accept': 'application/javascript' }
      })
      .then(response => response.text())
      .then(html => {
        document.querySelector('.reportTable').innerHTML = html
      })
      .catch(error => console.error('Error:', error))
    }, 300)
  }
}
