document.addEventListener("DOMContentLoaded", function() {
    const infoBox = document.createElement('div');
    infoBox.innerHTML = `
        <h1 style="font-weight: bold;">
            This is a continuation of the original TWO-TORIAL website. <br>
            Read more info about us
            <a href="https://info.re-two-torial.xyz" target="_blank" rel="noopener noreferrer" style="color: #5488e8;">here</a>
            <br> <br>
            <span style="color: lightcoral;">Recently Updated!</span>
        </h1>
    `;
    const mdContent = document.querySelector('.md-content__inner');

    if (mdContent) {
        mdContent.parentNode.insertBefore(infoBox, mdContent);
    }
});
