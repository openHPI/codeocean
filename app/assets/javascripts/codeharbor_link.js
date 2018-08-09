$(function(){
    $('[data-toggle="tooltip"]').tooltip();
});

$(function(){
    if($.isController('code_harbor_links')) {
        if ($('.edit_code_harbor_link, .new_code_harbor_link').isPresent()) {

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
                var d = getDate();
                return replace('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx');
            });

            var generateRandomHex32 = (function () {
                var d = getDate();
                return replace(Array(32).join('x'));
            });



            $('.generate-client-id').on('click', function () {
                $('.client-id').val(generateUUID());
            });

            $('.generate-client-secret').on('click', function () {
                $('.client-secret').val(generateRandomHex32());
            });

            $('.generate-oauth2-token').on('click', function () {
                $('.oauth2-token').val(generateRandomHex32())
            });
        }
    }
});

