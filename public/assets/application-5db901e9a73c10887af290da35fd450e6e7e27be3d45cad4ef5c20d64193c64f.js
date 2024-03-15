// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
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
        timerDisplay.textContent = hours + " hours " + minutes + " minutes " + seconds + " seconds";
    }
});

document.addEventListener('turbo:load', function() {
    const flashMessage = document.getElementById('banner');
    flashMessage.classList.add('fading-out');
    setTimeout(function() {
      flashMessage.parentNode.removeChild(flashMessage);
    }, 3000);
  });


  // app/assets/javascripts/application.js

document.addEventListener('DOMContentLoaded', function() {
    // Get all modal buttons
    var modalButtons = document.querySelectorAll(".modal-btn");
  
    // Loop through each modal button
    modalButtons.forEach(function(button) {
      // Add click event listener to open the corresponding modal
      button.addEventListener("click", function() {
        var targetId = button.getAttribute("data-target");
        var modal = document.getElementById(targetId);
        modal.style.display = "block";
      });
    });
  
    // Close modal when close button is clicked
    var closeModalBtn = document.getElementById("closeModalBtn");

    // Add event listener to close the modal when the button is clicked
    closeModalBtn.addEventListener("click", function() {
      modal.style.display = "none";
    });

    
    // Close modal when clicking outside the modal
    window.onclick = function(event) {
        var modals = document.querySelectorAll(".modal");
        modals.forEach(function(modal) {
            if (event.target == modal) {
                modal.style.display = "none";
            }
        });
    };
});
  
