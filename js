$(document).ready(function () {
    var temp_href = $('.page-class').attr('href'); // Get base URL

    // ✅ Mouse Click
    $('#search-button').on('click', function () {
        searchBranchM(temp_href);
    });

    // ✅ Enter Key Press
    $('#view-search-field').on('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault(); // Stop form submit if inside a form
            searchBranchM(temp_href);
        }
    });

    // 🔒 Optional: Live input filter (block special chars immediately)
    $('#view-search-field').on('input', function () {
        let val = $(this).val();
        // Allow only a-z, A-Z, 0-9
        val = val.replace(/[^a-zA-Z0-9]/g, '');
        $(this).val(val);
    });
});