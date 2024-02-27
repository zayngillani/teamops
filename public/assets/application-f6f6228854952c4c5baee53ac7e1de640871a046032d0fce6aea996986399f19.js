// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("DOMContentLoaded", function() {
     var intervalId; // Define intervalId outside the event listener
     var startTime; // Define startTime for both check-in and break
   
     // Check if timer was previously started and resume it if necessary
     var storedStartTime = localStorage.getItem("startTime");
     if (storedStartTime) {
       startTimer(parseInt(storedStartTime)); // Resume the timer with the stored start time
     }
   
     // Start timer when Check-In button is clicked
     document.getElementById("checkInButton").addEventListener("click", function() {
       startTime = Date.now(); // Get the current timestamp
       localStorage.setItem("startTime", startTime); // Store the start time in localStorage
       startTimer(startTime); // Start the timer
     });
   
     // Stop timer when Check-Out button is clicked
     document.getElementById("checkOutButton").addEventListener("click", function() {
       clearInterval(intervalId); // Stop the timer
       localStorage.removeItem("startTime"); // Remove the stored start time
       document.getElementById("timerDisplay").textContent = ""; // Clear the timer display
     });
   
     function startTimer(startTime) {
       var timerDisplay = document.getElementById("timerDisplay");
   
       // Update the timer display every second
       intervalId = setInterval(function() {
         var elapsedTime = Date.now() - startTime; // Calculate elapsed time
         var hours = Math.floor(elapsedTime / (1000 * 60 * 60));
         var minutes = Math.floor((elapsedTime % (1000 * 60 * 60)) / (1000 * 60));
         var seconds = Math.floor((elapsedTime % (1000 * 60)) / 1000);
   
         // Display the elapsed time in the timerDisplay element
         timerDisplay.textContent = hours + " hours " + minutes + " minutes " + seconds + " seconds";
       }, 1000);
     }
   });
   
