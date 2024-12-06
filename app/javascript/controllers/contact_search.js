import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query"]

  connect() {
    this.queryTarget.addEventListener("input", this.performSearch)
  }

  disconnect() {
    this.queryTarget.removeEventListener("input", this.performSearch)
  }

  performSearch = () => {
    clearTimeout(this.debounceTimeout)

    this.debounceTimeout = setTimeout(() => {
      const query = this.queryTarget.value

      if (query.trim() === "") {
        this.fetchAllContactDetails()
      } else {
        this.searchContactDetails(query)
      }
    }, 300)
  }

  fetchAllContactDetails() {
    fetch(this.element.action, {
      headers: { 'Accept': 'application/javascript' }
    })
    .then(response => response.text())
    .then(html => {
      document.querySelector('#contact-details-table').innerHTML = html
    })
    .catch(error => console.error('Error fetching contact details:', error))
  }

  searchContactDetails(query) {
    fetch(`${this.element.action}?q=${encodeURIComponent(query)}`, {
      headers: { 'Accept': 'application/javascript' }
    })
    .then(response => response.text())
    .then(html => {
      document.querySelector('#contact-details-table').innerHTML = html
    })
    .catch(error => console.error('Error performing search:', error))
  }
}
