// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import moment from "moment"

document.addEventListener("turbo:load", function() {
    var intervalId; // Define intervalId for the timer
    var startTime; // Define startTime based on the provided created_at timestamp
    // Get the created_at timestamp from the data attribute of the timerDisplay element
    var createdAt = document.getElementById("timerDisplay").dataset.createdAt;

    if (createdAt) {
        // Parse the createdAt timestamp using Moment.js
        startTime = moment(createdAt).utc();
        startTimer(startTime); // Start the timer
    }
   

    function startTimer(startTime) {
        var timerDisplay = document.getElementById("timerDisplay");

        // Update the timer display every second
        intervalId = setInterval(function() {
        var systemTime = document.getElementById("timerDisplay").dataset.systemTime;
         if (systemTime) {
        // Parse the createdAt timestamp using Moment.js
            systemTime = moment(systemTime).utc();
        }
            var elapsedTime = moment.duration(systemTime.diff(startTime)); // Calculate elapsed time

            // Extract hours, minutes, and seconds from the elapsed time
            var hours = Math.floor(elapsedTime.asHours());
            var minutes = Math.floor(elapsedTime.asMinutes()) % 60;
            var seconds = Math.floor(elapsedTime.asSeconds()) % 60;

            // Format the elapsed time for display
            var formattedTime = hours + " hours " + minutes + " minutes " + seconds + " seconds";

            // Display the formatted elapsed time in the timerDisplay element
            timerDisplay.textContent = formattedTime;
        }, 1000);
    }
});

