import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="contact-filter"
export default class extends Controller {
  connect() {
    document.addEventListener("turbo:load", this.initialize.bind(this));
    this.initialize();
  }
  disconnect() {
    document.removeEventListener("turbo:load", this.initialize.bind(this));
  }

  initialize() {
    if (this.dropdownTarget) {
      this.dropdownTarget.addEventListener("change", this.applyFilter.bind(this));
    } else {
      console.error("Filter dropdown element not found.");
    }
  }

  applyFilter(event) {
    event.preventDefault();

    clearTimeout(this.debounceTimeout);

    this.debounceTimeout = setTimeout(() => {
      const filterValue = event.target.value;

      this.updateContactDetails(filterValue);
    }, 200);
  }

  updateContactDetails(filterValue) {
    const url = new URL(window.location.href);
    url.searchParams.set('filter_by', filterValue);

    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/javascript',
      },
    })
    .then(response => response.text())
    .then(html => {
      document.querySelector('#contact-details-table').innerHTML = html;
    })
    .catch(error => {
      console.error('Error:', error);
    });
  }
}