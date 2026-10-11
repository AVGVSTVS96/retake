const dark = document.documentElement.classList.contains("dark")
for (const img of document.querySelectorAll("img.lockup")) img.src = `../logo/lockup${dark ? "-dark" : ""}.svg`
for (const img of document.querySelectorAll("img[data-shot]")) img.src = `../../site/public/media/iphone-18-pro-max-${img.dataset.shot}-${dark ? "dark" : "light"}.webp`
