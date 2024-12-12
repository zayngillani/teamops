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
    const query = this.queryTarget.value;

    // If the query is empty, redirect to page 1
    if (!query.trim()) {
      // Redirect to page 1 when query is empty
      window.location.href = `${this.element.action}?page=1`;
      return;
    }

    this.debounceTimeout = setTimeout(() => {
      const query = this.queryTarget.value;
      // Make the fetch request with the query
      fetch(`${this.element.action}?q=${encodeURIComponent(query)}`, {
        headers: { 'Accept': 'application/javascript' }
      })
      .then(response => response.text())
      .then(html => {
        const contactTable = document.querySelector('#contact-details-table');
        // If the response is empty, show the "No Contact Details found" message
        if (query && html.trim() === "") {
          // Clear the existing table contents
          contactTable.innerHTML = '';
  
          // Create the new row with the "No Contact Details found" message
          const noResultsRow = document.createElement('tr');
          const noResultsCell = document.createElement('td');
          noResultsCell.setAttribute('colspan', '5');  // Adjust colspan based on your table structure
          noResultsCell.style.textAlign = 'center';
          noResultsCell.innerHTML = '<p style="display: flex; justify-content: center; align-items: center; height: 100%;">No Contact Details found</p>';
  
          noResultsRow.appendChild(noResultsCell);
          contactTable.appendChild(noResultsRow);
        } else {
          // If there are results, update the table with the new HTML content
          contactTable.innerHTML = html;
        }
      })
      .catch(error => console.error('Error:', error));
    }, 200);  // Debounce to avoid excessive requests
  }
}
