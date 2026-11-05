const dark = document.documentElement.classList.contains("dark");

for (const img of document.querySelectorAll("img.lockup")) {
  if (img instanceof HTMLImageElement) {
    img.src = `../logo/lockup${dark ? "-dark" : ""}.svg`;
  }
}

for (const img of document.querySelectorAll("img[data-shot]")) {
  if (img instanceof HTMLImageElement) {
    img.src = `../../site/public/media/iphone-18-pro-max-${img.dataset.shot ?? ""}-${dark ? "dark" : "light"}.webp`;
  }
}
