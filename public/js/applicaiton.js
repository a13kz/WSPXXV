document.addEventListener("DOMContentLoaded", () => {
  const card = document.getElementById("card");

  const yesBtn = document.querySelector(".yes");
  const noBtn = document.querySelector(".no");

  yesBtn.addEventListener("click", function(e) {
    e.preventDefault();
    card.classList.add("slide-right");

    setTimeout(() => {
      this.closest("form").submit();
    }, 450);
  });

  noBtn.addEventListener("click", function(e) {
    e.preventDefault();
    card.classList.add("slide-left");

    setTimeout(() => {
      this.closest("form").submit();
    }, 450);
  });
});