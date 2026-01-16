let username;
let password;
const myCheckBox = document.getElementById("myCheckBox");

document.getElementById("submit").onclick = function() {
    username = document.getElementById("email").value;
    console.log(username);
    password = document.getElementById("password").value;
    console.log(password);
    
    console.log(myCheckBox.checked);


}