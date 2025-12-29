document.addEventListener("DOMContentLoaded", function() {
    const infoBox = document.createElement('div');
    infoBox.innerHTML = `
        <h1 style="font-weight: bold; text-decoration: underline; text-decoration-color: red;">
            This is a mirror of the original TWO-TORIAL website. <br>
            Read more info about this mirror --->
            <a href="https://two-torial-info.maimaidxprism.plus/" target="_blank" rel="noopener noreferrer" style="color: #a47bea; text-decoration: underline; text-decoration-color: red;">here</a>
        </h1>
    `;
    const mdContent = document.querySelector('.md-content__inner');

    if (mdContent) {
        mdContent.parentNode.insertBefore(infoBox, mdContent);
    }
});
