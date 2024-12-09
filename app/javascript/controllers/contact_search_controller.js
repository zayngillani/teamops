import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="contact-search"
export default class extends Controller {
  static targets = ["query"];

  connect() {
    document.addEventListener("turbo:load", this.initialize.bind(this));
    this.initialize();
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.initialize.bind(this));
  }

  initialize() {
    if (this.queryTarget) {
      this.queryTarget.addEventListener("input", this.performSearch.bind(this));
    } else {
      console.error("Search input element not found.");
    }
  }


  performSearch(event) {
    event.preventDefault();

    clearTimeout(this.debounceTimeout);

    this.debounceTimeout = setTimeout(() => {
      const query = this.queryTarget.value;
      
      fetch(`${this.element.action}?q=${encodeURIComponent(query)}`, {
        headers: { 'Accept': 'application/javascript' }
      })
      .then(response => response.text())
      .then(html => {
        document.querySelector('#contact-details-table').innerHTML = html;
      })
      .catch(error => console.error('Error:', error));
    }, 300); 
  }
}
