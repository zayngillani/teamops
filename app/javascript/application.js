import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", function() {
    var startTime; // Define startTime based on the provided created_at timestamp

    // Get the created_at timestamp from the data attribute of the timerDisplay element
    var createdAt = document.getElementById("timerDisplay").dataset.createdAt;
    if (createdAt) {
        // Parse the createdAt timestamp to get the start time in milliseconds
        startTime = new Date(createdAt).getTime();
        startTimer(startTime); // Start the timer
    }

    function pad(number) {
        return (number < 10 ? '0' : '') + number;
    }
    function startTimer(startTime) {
        var timerDisplay = document.getElementById("timerDisplay");
        var systemTime = document.getElementById("timerDisplay").dataset.systemTime;
        if (systemTime) {
            // Parse the createdAt timestamp to get the start time in milliseconds
            systemTime = new Date(systemTime).getTime();
        }
        // Update the timer display every second
        var elapsedTime = systemTime - startTime; // Calculate elapsed time
        var hours = Math.floor(elapsedTime / (1000 * 60 * 60));
        var minutes = Math.floor((elapsedTime % (1000 * 60 * 60)) / (1000 * 60));
        var seconds = Math.floor((elapsedTime % (1000 * 60)) / 1000);

        // Display the elapsed time in the timerDisplay element
        timerDisplay.textContent = pad(hours) + " : " + pad(minutes) + " : " + pad(seconds);
    }
});

  document.addEventListener('turbo:load', function() {
    const flashMessage = document.getElementById('banner');
    flashMessage.classList.add('fading-out');
    setTimeout(function() {
      flashMessage.parentNode.removeChild(flashMessage);
    }, 3000);
  });

  document.addEventListener('turbo:load', function() {
    const flashMessage = document.getElementById('banner-devise');
    flashMessage.classList.add('fading-out');
    setTimeout(function() {
      flashMessage.parentNode.removeChild(flashMessage);
    }, 3000);
  });

  document.addEventListener('DOMContentLoaded', function() {
    // Function to open a modal
    function openModal(modalId) {
        var modal = document.getElementById(modalId);
        modal.style.display = "block";
    }

    // Function to close a modal
    function closeModal(modalId) {
        var modal = document.getElementById(modalId);
        modal.style.display = "none";
    }

    // Event delegation for modal buttons
    document.addEventListener('click', function(event) {
        if (event.target.classList.contains('modal-btn')) {
            var targetId = event.target.getAttribute("data-target");
            openModal(targetId);
        }
    });

    // Event delegation for closing modal
    document.addEventListener('click', function(event) {
        if (event.target.classList.contains('closeModalBtn')) {
            var modal = event.target.closest(".modal");
            closeModal(modal.id);
        }
    });

    // Event delegation for closing modal when clicking outside the modal
    window.addEventListener('click', function(event) {
        if (event.target.classList.contains('modal')) {
            closeModal(event.target.id);
        }
    });

    // Event delegation for action buttons
    document.addEventListener('click', function(event) {
        if (event.target.classList.contains('sign-out-button') && event.target.classList.contains('delete-btn')) {
            var modal = event.target.closest(".modal");
            closeModal(modal.id);
            performActionAndReload();
        }
    });

    // Function to perform action and reload the page
    function performActionAndReload() {
        setTimeout(function() {
            location.reload();
        }, 1000);
    }
    
});

document.addEventListener("turbo:load", function() {
    const togglePasswordButtons = document.querySelectorAll(".toggle-password");
  
    togglePasswordButtons.forEach(button => {
      button.addEventListener("click", function() {
        const passwordInput = this.parentNode.querySelector(".password-input");
        if (passwordInput.type === "password") {
          passwordInput.type = "text";
          this.innerHTML = '<i class="fas fa-eye-slash"></i>'; // Change button content to "Hide" icon
        } else {
          passwordInput.type = "password";
          this.innerHTML = '<i class="fas fa-eye"></i>'; // Change button content to "Show" icon
        }
      });
    });
  });


  document.addEventListener('turbo:load', function() {
    const monthSelect = document.getElementById('month');
    const yearSelect = document.getElementById('year');
  
    if (monthSelect && yearSelect) {
      monthSelect.addEventListener('change', function() {
        document.getElementById('filterForm').submit();
      });
  
      yearSelect.addEventListener('change', function() {
        document.getElementById('filterForm').submit();
      });
    }
  });
  
  document.addEventListener('turbo:load', function() {
    const cells = document.querySelectorAll('.clickable-cell');

    cells.forEach(cell => {
      cell.addEventListener('click', function() {
        const userPath = cell.getAttribute('data-user-path');
        if (userPath) {
          window.location.href = userPath;
        }
      });
    });
  });

  document.addEventListener('turbo:load', function() {
    const searchInput = document.getElementById('searchInput');
    const userRows = document.querySelectorAll('#usersTableBody .user-row');
    const separatorRows = document.querySelectorAll('#usersTableBody .separator-row');

    searchInput.addEventListener('keyup', function() {
      const filter = searchInput.value.toLowerCase();
      let hasResults = false;

      userRows.forEach((userRow, index) => {
        const td = userRow.getElementsByTagName('td')[0];
        if (td) {
          const textValue = td.textContent || td.innerText;
          if (textValue.toLowerCase().indexOf(filter) > -1) {
            userRow.style.display = '';
            if (separatorRows[index]) separatorRows[index].style.display = '';
            hasResults = true;
          } else {
            userRow.style.display = 'none';
            if (separatorRows[index]) separatorRows[index].style.display = 'none';
          }
        }
      });

      const noResultsRow = document.getElementById('noResultsRow');
      if (hasResults) {
        if (noResultsRow) noResultsRow.style.display = 'none';
      } else {
        if (!noResultsRow) {
          const tbody = document.getElementById('usersTableBody');
          const newRow = document.createElement('tr');
          newRow.id = 'noResultsRow';
          const newCell = document.createElement('td');
          newCell.colSpan = 2;
          newCell.style.textAlign = 'center';
          newCell.textContent = 'No Users found';
          newRow.appendChild(newCell);
          tbody.appendChild(newRow);
        } else {
          noResultsRow.style.display = '';
        }
      }
    });
  });