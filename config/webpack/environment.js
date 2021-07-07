/*
./config/webpack/environment.js
Info for this file can be found
github.com/rails/webpacker/blob/master/docs/webpack.md
*/

const {environment} = require('@rails/webpacker')
const {merge} = require('webpack-merge')
const webpack = require('webpack')
const erb = require('./loaders/erb')

// Add an additional plugin of your choosing : ProvidePlugin
environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
        $: 'jquery',
        JQuery: 'jquery',
        jquery: 'jquery',
        'window.Tether': "tether",
        Popper: ['popper.js', 'default'], // for Bootstrap 4
        _: 'underscore',
        vis: 'vis',
        hljs: 'highlight.js',
        d3: 'd3',
        Sentry: '@sentry/browser',
        Sortable: 'sortablejs',
    })
)

// This setting will change the absolute path used to refer
// external files (images, fonts, ...) in the generated assets
const relative_url_root = process.env.RAILS_RELATIVE_URL_ROOT || '';
const public_output_path = environment.config.output.publicPath;
environment.loaders.get('file')
    .use.find(item => item.loader === 'file-loader')
    .options.publicPath = relative_url_root + public_output_path;

environment.loaders.append('erb', erb)

const envConfig = module.exports = environment
const aliasConfig = module.exports = {
    resolve: {
        alias: {
            jquery: 'jquery/src/jquery',
        }
    }
}

module.exports = merge(envConfig.toWebpackConfig(), aliasConfig)
