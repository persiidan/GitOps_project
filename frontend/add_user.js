const API_URL = "http://localhost:5000/users";

function showMessage(message, isError = false) {
    const statusElement = document.getElementById("status-message");
    statusElement.textContent = message;
    statusElement.className = isError ? "error" : "success";
    statusElement.style.display = "block";
    setTimeout(() => {
        statusElement.style.display = "none";
    }, 3000);
}

document.addEventListener("DOMContentLoaded", () => {
    loadUsers();

    document.getElementById("user-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        try {
            const username = document.getElementById("username").value;
            const email = document.getElementById("email").value;

            console.log("Attempting to add user:", { username, email });

            const response = await fetch(API_URL, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ username, email }),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || `HTTP error! status: ${response.status}`);
            }

            showMessage(`User ${username} added successfully!`);
            await loadUsers();
            e.target.reset();
        } catch (error) {
            console.error("Error adding user:", error);
            showMessage(`Error adding user: ${error.message}`, true);
        }
    });
});

async function loadUsers() {
    try {
        console.log("Fetching users from:", API_URL); // Debug log
        const response = await fetch(API_URL);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const users = await response.json();
        console.log("Received users:", users); // Debug log
        
        const usersList = document.getElementById("users-list");
        usersList.innerHTML = users.length === 0 
            ? "<li>No users found</li>" 
            : users.map(user => `
                <li>
                    ${user.username} (${user.email})
                    <button onclick="deleteUser('${user._id}')" style="float: right;">Delete</button>
                </li>
            `).join("");
    } catch (error) {
        console.error("Error loading users:", error);
        document.getElementById("users-list").innerHTML = 
            `<li style="color: red;">Error loading users: ${error.message}</li>`;
    }
}

async function deleteUser(userId) {
    try {
        const response = await fetch(`${API_URL}/${userId}`, { method: "DELETE" });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        showMessage("User deleted successfully!");
        await loadUsers();
    } catch (error) {
        console.error("Error deleting user:", error);
        showMessage(`Error deleting user: ${error.message}`, true);
    }
}