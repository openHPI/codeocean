/*
./config/webpack/environment.js
Info for this file can be found
github.com/rails/webpacker/blob/master/docs/webpack.md
*/

const { environment } = require('@rails/webpacker');
const merge = require('webpack-merge');
const webpack = require('webpack');

// Add an additional plugin of your choosing : ProvidePlugin
environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
        $: 'jquery',
        JQuery: 'jquery',
        jquery: 'jquery',
        'window.Tether': "tether",
        Popper: ['popper.js', 'default'], // for Bootstrap 4
        _: 'underscore',
    })
);

const envConfig = module.exports = environment;
const aliasConfig = module.exports = {
    resolve: {
        alias: {
            jquery: 'jquery/src/jquery',
            underscore: 'underscore/underscore',
        }
    }
};

module.exports = merge(envConfig.toWebpackConfig(), aliasConfig);
