// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

const { webpackConfig, merge } = require('shakapacker')
const webpack = require('webpack');

// Custom ERB loader to disable Spring and prevent crashes
const erb = require("./loaders/erb");

// This setting will change the absolute path used to refer
// external files (images, fonts, ...) in the generated assets
const relative_url_root = process.env.RAILS_RELATIVE_URL_ROOT || '';
const public_output_path = webpackConfig.output.publicPath;

const envConfig = module.exports = {
    output: {
        publicPath: relative_url_root + public_output_path
    },
    module: {
        rules: [
            erb
        ]
    },
    resolve: {
        extensions: ['.css', '.ts', '.tsx'],
        alias: {
            $: 'jquery/src/jquery',
            jquery: 'jquery/src/jquery',
            vis$: 'vis-timeline/standalone',
        }
    },
    plugins: [
        new webpack.ProvidePlugin({
            $: 'jquery',
            JQuery: 'jquery',
            jQuery: 'jquery',
            jquery: 'jquery',
            'window.Tether': "tether",
            Popper: ['popper.js', 'default'], // for Bootstrap 4
            _: 'underscore',
            vis: 'vis',
            d3: 'd3',
            Sentry: '@sentry/browser',
            Sortable: 'sortablejs',
        })
    ]
}

module.exports = merge(webpackConfig, envConfig)
