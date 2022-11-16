$(document).on('turbolinks:load', function() {
    if($.isController('codeharbor_links')) {
        if ($('.edit_codeharbor_link, .new_codeharbor_link').isPresent()) {

            var replace = (function(string) {
                var d = getDate();
                return string.replace(/[xy]/g, function (c) {
                    var r = (d + Math.random() * 16) % 16 | 0;
                    d = Math.floor(d / 16);
                    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
                });
            });

            var getDate = (function () {
                var d = new Date().getTime();
                if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
                    d += performance.now(); //use high-precision timer if available
                }
                return d
            });

            var generateUUID = (function () { // Public Domain/MIT
                return replace('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx');
            });

            var generateRandomHex32 = (function () {
                return replace(Array(32).join('x'));
            });

            $('.generate-api_key').on('click', function () {
                $('.api_key').val(generateRandomHex32())
            });
        }
    }
});

